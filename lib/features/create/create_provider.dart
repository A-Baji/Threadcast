import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/providers.dart';
import '../../models/episode.dart';
import '../../services/llm/models/transcript.dart';
import '../../services/tts/voice_assignment.dart';

final createProvider = StateNotifierProvider<CreateNotifier, CreateState>(
  (ref) => CreateNotifier(ref),
);

class CreateNotifier extends StateNotifier<CreateState> {
  final Ref _ref;

  CreateNotifier(this._ref) : super(const CreateState.idle());

  Future<void> generatePodcast(List<String> urls) async {
    final episodeId = const Uuid().v4();

    try {
      // 1. Check device compatibility
      state = const CreateState.checkingCompatibility();
      final llm = _ref.read(llmServiceProvider);
      if (!await llm.isAvailable()) {
        state = const CreateState.unsupported();
        return;
      }

      // 2. Scrape Reddit posts
      state = const CreateState.scraping();
      final scraper = _ref.read(redditScraperProvider);
      final posts = await Future.wait(urls.map(scraper.fetchPost));

      // 3. Phase 1: Analysis
      state = const CreateState.analyzing();
      final promptBuilder = _ref.read(llmPromptBuilderProvider);
      final analysisPrompt = promptBuilder.buildAnalysisPrompt(posts);
      final analysisRaw = await llm.generateRaw(analysisPrompt);
      final analysis = jsonDecode(analysisRaw) as Map<String, dynamic>;

      // 4. Phase 2: Transcript generation
      state = const CreateState.generatingTranscript();
      final transcriptPrompt = promptBuilder.buildTranscriptPrompt(
        posts: posts,
        analysis: analysis,
      );
      final transcriptRaw = await llm.generateRaw(transcriptPrompt);
      final segments = (jsonDecode(transcriptRaw) as List)
          .map((s) => TranscriptSegment.fromJson(s as Map<String, dynamic>))
          .toList();

      // 5. Assign voices
      final speakers = (analysis['speakers'] as List).map((s) => Speaker.fromJson(s as Map<String, dynamic>)).toList();
      final voiceMap = VoiceAssignment.assignVoices(speakers);

      // 6. TTS synthesis — STREAMING PIPELINE
      final tts = _ref.read(ttsServiceProvider);
      final synthesized = <TranscriptSegment>[];
      final stitcher = _ref.read(audioStitcherProvider);

      for (int i = 0; i < segments.length; i++) {
        state = CreateState.synthesizing(
          i / segments.length,
          segments[i].speakerId,
        );

        final seg = segments[i];
        final voice = voiceMap[seg.speakerId] ?? 'am_adam';
        final audioPath = await tts.synthesizeSegment(
          segment: seg,
          voice: voice,
          episodeId: episodeId,
          segmentIndex: i,
        );
        const duration = Duration(seconds: 5); // Mock duration
        synthesized.add(seg.copyWith(
          audioFilePath: audioPath,
          audioDuration: duration,
        ));
      }

      // 7. Final stitch of all segments
      state = const CreateState.stitching();
      final finalAudioPath = await stitcher.stitch(
        segments: synthesized,
        episodeId: episodeId,
      );

      // 8. Persist episode
      final episode = Episode()
        ..episodeId = episodeId
        ..title = analysis['episode_title'] as String? ?? 'Mock Episode'
        ..subreddit = posts.first.subreddit
        ..sourceUrls = urls
        ..tone = analysis['tone'] as String? ?? 'talk_show'
        ..createdAt = DateTime.now()
        ..durationSeconds = 60 // Mock
        ..audioWavPath = finalAudioPath
        ..status = EpisodeStatus.complete;

      final isar = await _ref.read(isarProvider);
      await isar.writeTxn(() => isar.episodes.put(episode));

      state = CreateState.complete(episode: episode);
    } catch (e) {
      state = CreateState.failed(error: e.toString());
    }
  }
}

class CreateState {
  const CreateState._(this.status, this.progress, this.currentSpeaker, this.partialAudioPath, this.episode, this.error);

  const CreateState.idle() : this._(CreateStatus.idle, null, null, null, null, null);
  const CreateState.checkingCompatibility() : this._(CreateStatus.checkingCompatibility, null, null, null, null, null);
  const CreateState.unsupported() : this._(CreateStatus.unsupported, null, null, null, null, null);
  const CreateState.scraping() : this._(CreateStatus.scraping, null, null, null, null, null);
  const CreateState.analyzing() : this._(CreateStatus.analyzing, null, null, null, null, null);
  const CreateState.generatingTranscript() : this._(CreateStatus.generatingTranscript, null, null, null, null, null);
  const CreateState.synthesizing(double progress, String currentSpeaker, {String? partialAudioPath})
      : this._(CreateStatus.synthesizing, progress, currentSpeaker, partialAudioPath, null, null);
  const CreateState.stitching() : this._(CreateStatus.stitching, null, null, null, null, null);
  const CreateState.complete({required Episode episode})
      : this._(CreateStatus.complete, null, null, null, episode, null);
  const CreateState.failed({required String error}) : this._(CreateStatus.failed, null, null, null, null, error);

  final CreateStatus status;
  final double? progress;
  final String? currentSpeaker;
  final String? partialAudioPath;
  final Episode? episode;
  final String? error;
}

enum CreateStatus {
  idle,
  checkingCompatibility,
  unsupported,
  scraping,
  analyzing,
  generatingTranscript,
  synthesizing,
  stitching,
  complete,
  failed,
}
