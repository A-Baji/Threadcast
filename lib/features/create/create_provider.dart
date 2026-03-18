import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
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

  Future<void> checkCompatibilityOnLoad() async {
    if (state.hasCheckedCompatibility || state.status == CreateStatus.checkingCompatibility) {
      return;
    }

    state = state.copyWith(status: CreateStatus.checkingCompatibility, hasCheckedCompatibility: true, error: null);

    final supported = _isOsVersionSupported();
    if (!supported) {
      state = state.copyWith(status: CreateStatus.unsupported);
      return;
    }

    state = state.copyWith(status: CreateStatus.idle);
  }

  bool _isOsVersionSupported() {
    try {
      final versionString = Platform.operatingSystemVersion;

      if (Platform.isAndroid) {
        // Logic: Build IDs starting with 'A' are Android 15.
        // Android 16 (Baklava) builds typically start with 'B'.
        if (versionString.startsWith('B')) return true; // Android 16+
        if (versionString.startsWith('A')) return false; // Android 15

        // Fallback: If it actually contains "Android X"
        final match = RegExp(r'Android\s+(\d+)').firstMatch(versionString);
        final major = int.tryParse(match?.group(1) ?? '');
        return (major ?? 0) >= 16;
      }

      if (Platform.isIOS) {
        // iOS version strings usually start with the version: "17.4..."
        final match = RegExp(r'^(\d+)').firstMatch(versionString);
        final major = int.tryParse(match?.group(1) ?? '');
        return (major ?? 0) >= 18;
      }

      return true;
    } catch (_) {
      return true; // Default to supported on error
    }
  }

  void addUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty || !trimmed.contains('reddit')) {
      return;
    }

    if (state.urls.contains(trimmed)) {
      return;
    }

    state = state.copyWith(urls: [...state.urls, trimmed]);
  }

  void removeUrl(int index) {
    if (index < 0 || index >= state.urls.length) {
      return;
    }

    final updated = [...state.urls]..removeAt(index);
    state = state.copyWith(urls: updated);
  }

  void reorderUrls(int oldIndex, int newIndex) {
    final updated = [...state.urls];

    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    if (oldIndex < 0 || oldIndex >= updated.length || newIndex < 0 || newIndex >= updated.length) {
      return;
    }

    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);
    state = state.copyWith(urls: updated);
  }

  Future<void> generatePodcast() async {
    final urls = List<String>.from(state.urls);
    if (urls.isEmpty || state.status == CreateStatus.unsupported) {
      return;
    }

    final episodeId = const Uuid().v4();

    try {
      state = state.copyWith(status: CreateStatus.scraping, error: null);
      final llm = _ref.read(llmServiceProvider);
      if (!await llm.isAvailable()) {
        state = state.copyWith(
          status: CreateStatus.failed,
          error: 'On-device model is unavailable. Please verify your model setup and try again.',
        );
        return;
      }

      final scraper = _ref.read(redditScraperProvider);
      final posts = await Future.wait(urls.map(scraper.fetchPost));

      state = state.copyWith(status: CreateStatus.analyzing);
      final promptBuilder = _ref.read(llmPromptBuilderProvider);
      final analysisRaw = await llm.generateRaw(promptBuilder.buildAnalysisPrompt(posts));
      final analysis = jsonDecode(analysisRaw) as Map<String, dynamic>;

      state = state.copyWith(status: CreateStatus.generatingTranscript);
      final transcriptRaw =
          await llm.generateRaw(promptBuilder.buildTranscriptPrompt(posts: posts, analysis: analysis));
      final segments = (jsonDecode(transcriptRaw) as List)
          .map((s) => TranscriptSegment.fromJson(s as Map<String, dynamic>))
          .toList();

      final speakers = (analysis['speakers'] as List).map((s) => Speaker.fromJson(s as Map<String, dynamic>)).toList();
      final voiceMap = VoiceAssignment.assignVoices(speakers);

      final tts = _ref.read(ttsServiceProvider);
      final synthesized = <TranscriptSegment>[];

      for (int i = 0; i < segments.length; i++) {
        state = state.copyWith(
          status: CreateStatus.synthesizing,
          progress: i / segments.length,
          currentSpeaker: segments[i].speakerId,
        );
        final seg = segments[i];
        final audioPath = await tts.synthesizeSegment(
          segment: seg,
          voice: voiceMap[seg.speakerId] ?? 'am_adam',
          episodeId: episodeId,
          segmentIndex: i,
        );
        synthesized.add(seg.copyWith(
          audioFilePath: audioPath,
          audioDuration: const Duration(seconds: 5),
        ));
      }

      state = state.copyWith(status: CreateStatus.stitching, progress: null, currentSpeaker: null);
      final stitcher = _ref.read(audioStitcherProvider);
      final finalAudioPath = await stitcher.stitch(segments: synthesized, episodeId: episodeId);

      final db = _ref.read(databaseProvider);
      await db.upsertEpisode(EpisodesCompanion(
        episodeId: Value(episodeId),
        title: Value(analysis['episode_title'] as String? ?? 'Untitled'),
        subreddit: Value(posts.first.subreddit),
        sourceUrlsJson: Value(AppDatabase.encodeUrls(urls)),
        tone: Value(analysis['tone'] as String? ?? 'talk_show'),
        createdAt: Value(DateTime.now()),
        durationSeconds: const Value(60),
        audioWavPath: Value(finalAudioPath),
        status: Value(AppDatabase.encodeStatus(EpisodeStatus.complete)),
      ));

      final episode = await db.episodeById(episodeId);
      state = state.copyWith(status: CreateStatus.complete, episode: episode);
    } on PlatformException catch (e) {
      final message = e.message?.trim();
      final details = message == null || message.isEmpty ? e.code : '${e.code}: $message';
      state = state.copyWith(status: CreateStatus.failed, error: details);
    } catch (e) {
      state = state.copyWith(status: CreateStatus.failed, error: e.toString());
    }
  }
}

class CreateState {
  const CreateState._(
    this.status, {
    this.urls = const [],
    this.progress,
    this.currentSpeaker,
    this.partialAudioPath,
    this.episode,
    this.error,
    this.hasCheckedCompatibility = false,
  });

  const CreateState.idle() : this._(CreateStatus.idle);

  final CreateStatus status;
  final List<String> urls;
  final double? progress;
  final String? currentSpeaker;
  final String? partialAudioPath;
  final Episode? episode;
  final String? error;
  final bool hasCheckedCompatibility;

  CreateState copyWith({
    CreateStatus? status,
    List<String>? urls,
    double? progress,
    String? currentSpeaker,
    String? partialAudioPath,
    Episode? episode,
    String? error,
    bool? hasCheckedCompatibility,
  }) {
    return CreateState._(
      status ?? this.status,
      urls: urls ?? this.urls,
      progress: progress,
      currentSpeaker: currentSpeaker,
      partialAudioPath: partialAudioPath ?? this.partialAudioPath,
      episode: episode ?? this.episode,
      error: error,
      hasCheckedCompatibility: hasCheckedCompatibility ?? this.hasCheckedCompatibility,
    );
  }
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
