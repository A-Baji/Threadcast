import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:drift/drift.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

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

    final supported = await _isOsVersionSupported();
    if (!supported) {
      state = state.copyWith(status: CreateStatus.unsupported);
      return;
    }

    state = state.copyWith(status: CreateStatus.idle);
  }

  Future<bool> _isOsVersionSupported() async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.version.sdkInt >= 36;
      }

      if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        final majorVersion = int.tryParse(iosInfo.systemVersion.split('.').first);
        return (majorVersion ?? 0) >= 18;
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
      await WakelockPlus.enable();
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
      await tts.initialize();
      final synthesized = <TranscriptSegment>[];

      for (int i = 0; i < segments.length; i++) {
        state = state.copyWith(
          status: CreateStatus.synthesizing,
          progress: i / segments.length,
          currentSpeaker: segments[i].speakerId,
        );
        final seg = segments[i];
        final result = await tts.synthesizeSegment(
          segment: seg,
          voice: voiceMap[seg.speakerId] ?? 'am_adam',
          episodeId: episodeId,
          segmentIndex: i,
        );
        synthesized.add(seg.copyWith(audioFilePath: result.path, audioDuration: result.duration));
      }

      final timedSegments = _withAudioOffsets(synthesized);

      final durationSeconds = _episodeDurationSeconds(timedSegments);

      final docsDir = await getApplicationDocumentsDirectory();
      final episodeDir = Directory('${docsDir.path}/episodes/$episodeId');
      await episodeDir.create(recursive: true);
      final transcriptFile = File('${episodeDir.path}/transcript.json');
      final transcriptData = {
        'episode_title': analysis['episode_title'],
        'tone': analysis['tone'],
        'speakers': analysis['speakers'],
        'segments': timedSegments
            .map(
              (seg) => {
                'speaker_id': seg.speakerId,
                'text': seg.text,
                'delivery': {
                  'pace': seg.delivery.pace,
                  'emotion': seg.delivery.emotion,
                  'pause_before_ms': seg.delivery.pauseBeforeMs,
                  'overlap_previous': seg.delivery.overlapPrevious,
                },
                'audio_offset_ms': seg.audioOffset?.inMilliseconds,
                'audio_duration_ms': seg.audioDuration?.inMilliseconds,
              },
            )
            .toList(),
      };
      await transcriptFile.writeAsString(jsonEncode(transcriptData));
      final transcriptPath = transcriptFile.path;

      state = state.copyWith(status: CreateStatus.stitching, progress: null, currentSpeaker: null);
      final stitcher = _ref.read(audioStitcherProvider);
      final finalAudioPath = await stitcher.stitch(segments: timedSegments, episodeId: episodeId);

      // Auto-encode MP3 immediately after stitching, while the user is still
      // on the "generating" screen. This means share is instant later — no
      // spinner at share time. Failure is non-fatal: episode saves with WAV only.
      String? mp3Path;
      try {
        final candidateMp3Path = finalAudioPath.replaceAll('.wav', '.mp3');
        final session = await FFmpegKit.execute(
          '-i "$finalAudioPath" -codec:a libmp3lame -qscale:a 2 "$candidateMp3Path"',
        );
        final returnCode = await session.getReturnCode();
        if (ReturnCode.isSuccess(returnCode)) {
          mp3Path = candidateMp3Path;
        }
      } catch (_) {
        // Non-fatal — episode is still usable via WAV
      }

      final db = _ref.read(databaseProvider);
      await db.upsertEpisode(EpisodesCompanion(
        episodeId: Value(episodeId),
        title: Value(analysis['episode_title'] as String? ?? 'Untitled'),
        subreddit: Value(posts.first.subreddit),
        sourceUrlsJson: Value(AppDatabase.encodeUrls(urls)),
        tone: Value(analysis['tone'] as String? ?? 'talk_show'),
        createdAt: Value(DateTime.now()),
        durationSeconds: Value(durationSeconds),
        audioWavPath: Value(finalAudioPath),
        audioMp3Path: mp3Path != null ? Value(mp3Path) : const Value.absent(),
        transcriptJsonPath: Value(transcriptPath),
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
    } finally {
      await WakelockPlus.disable();
    }
  }

  List<TranscriptSegment> _withAudioOffsets(List<TranscriptSegment> segments) {
    final timedSegments = <TranscriptSegment>[];
    var currentMs = 0;

    for (final segment in segments) {
      currentMs += segment.delivery.pauseBeforeMs;

      if (segment.delivery.overlapPrevious && timedSegments.isNotEmpty) {
        final previous = timedSegments.last;
        final previousEnd = previous.audioOffset!.inMilliseconds + previous.audioDuration!.inMilliseconds;
        currentMs = previousEnd - 500;
      }

      timedSegments.add(segment.copyWith(audioOffset: Duration(milliseconds: currentMs)));
      currentMs += segment.audioDuration!.inMilliseconds;
    }

    return timedSegments;
  }

  int _episodeDurationSeconds(List<TranscriptSegment> segments) {
    var totalMilliseconds = 0;

    for (final segment in segments) {
      final offsetMs = segment.audioOffset?.inMilliseconds ?? 0;
      final durationMs = segment.audioDuration?.inMilliseconds ?? 0;
      final segmentEndMs = offsetMs + durationMs;
      if (segmentEndMs > totalMilliseconds) {
        totalMilliseconds = segmentEndMs;
      }
    }

    return (totalMilliseconds / 1000).ceil();
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
