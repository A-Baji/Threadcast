import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:drift/drift.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:threadcast/services/llm/llm_service.dart';
import 'package:threadcast/services/llm/llm_service_router.dart';
import 'package:threadcast/services/llm/model_download_manager.dart';
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

      final llm = _ref.read(llmServiceProvider);
      final router = llm is LlmServiceRouter ? llm : null;

      if (router != null && await router.needsModelDownload) {
        if (await ModelDownloadManager.hasPartialDownload()) {
          // The user already accepted the consent dialog in a previous session.
          // An interrupted download left a .part file on disk. Resume silently
          // without showing the dialog again.
          await WakelockPlus.disable();
          await confirmDownload();
          return;
        }

        state = state.copyWith(
          status: CreateStatus.awaitingDownloadConsent,
          error: null,
        );
        await WakelockPlus.disable();
        return;
      }

      final usingGemmaFallback = router != null && !(await router.usingOsModel);

      state = state.copyWith(status: CreateStatus.scraping, error: null);
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
      final analysis = await _generateAnalysis(
        llm: llm,
        analysisPrompt: usingGemmaFallback
            ? promptBuilder.buildGemmaAnalysisPrompt(posts)
            : promptBuilder.buildAnalysisPrompt(posts),
      );

      state = state.copyWith(status: CreateStatus.generatingTranscript);
      final transcriptPrompt = usingGemmaFallback
          ? promptBuilder.buildGemmaTranscriptPrompt(posts: posts, analysis: analysis)
          : promptBuilder.buildTranscriptPrompt(posts: posts, analysis: analysis);
      final segments = await _generateTranscriptSegments(
        llm: llm,
        transcriptPrompt: transcriptPrompt,
      );

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

  Future<List<TranscriptSegment>> _generateTranscriptSegments({
    required LlmService llm,
    required String transcriptPrompt,
  }) async {
    var transcriptRaw = await llm.generateRaw(transcriptPrompt);
    var parsed = _tryParseTranscriptSegments(transcriptRaw);
    if (parsed != null) {
      return parsed;
    }

    // Retry once with tighter output constraints for on-device models.
    transcriptRaw = await llm.generateRaw(
      '$transcriptPrompt\n\n'
      'IMPORTANT: Return compact output to fit on-device limits:\n'
      '- Maximum 16 segments\n'
      '- Maximum 2 sentences per segment\n'
      '- JSON array only, no markdown or commentary.',
    );
    parsed = _tryParseTranscriptSegments(transcriptRaw);
    if (parsed != null) {
      return parsed;
    }

    throw const FormatException(
      'Unable to parse transcript JSON from model output after retry.',
    );
  }

  Future<Map<String, dynamic>> _generateAnalysis({
    required LlmService llm,
    required String analysisPrompt,
  }) async {
    var analysisRaw = await llm.generateRaw(analysisPrompt);
    var parsed = _tryParseAnalysis(analysisRaw);
    if (parsed != null) {
      return parsed;
    }

    analysisRaw = await llm.generateRaw(
      '$analysisPrompt\n\n'
      'IMPORTANT:\n'
      '- Return a single JSON object only\n'
      '- No markdown/code fences\n'
      '- Keep fields concise to fit on-device limits.',
    );

    parsed = _tryParseAnalysis(analysisRaw);
    if (parsed != null) {
      return parsed;
    }

    throw const FormatException(
      'Unable to parse analysis JSON from model output after retry.',
    );
  }

  Map<String, dynamic>? _tryParseAnalysis(String raw) {
    try {
      return _parseJsonObject(raw);
    } catch (_) {
      return null;
    }
  }

  List<TranscriptSegment>? _tryParseTranscriptSegments(String raw) {
    try {
      final list = _parseJsonArray(raw);
      return list.map((s) => TranscriptSegment.fromJson(s as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _parseJsonObject(String raw) {
    final decoded = jsonDecode(_extractJsonPayload(raw));
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Expected JSON object from model output.');
    }
    return decoded;
  }

  List<dynamic> _parseJsonArray(String raw) {
    final decoded = jsonDecode(_extractJsonPayload(raw));
    if (decoded is! List<dynamic>) {
      throw const FormatException('Expected JSON array from model output.');
    }
    return decoded;
  }

  String _extractJsonPayload(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Empty model response.');
    }

    // Remove markdown fences when present.
    final fenceMatch = RegExp(
      r'^```(?:json)?\s*([\s\S]*?)\s*```$',
      caseSensitive: false,
      multiLine: true,
    ).firstMatch(trimmed);
    final withoutFence = fenceMatch != null ? fenceMatch.group(1)!.trim() : trimmed;

    final startObject = withoutFence.indexOf('{');
    final startArray = withoutFence.indexOf('[');
    final starts = [startObject, startArray].where((i) => i >= 0).toList()..sort();
    if (starts.isEmpty) {
      throw const FormatException('Model output did not contain JSON payload.');
    }

    final start = starts.first;
    final end = _findJsonEnd(withoutFence, start);
    if (end == -1) {
      throw const FormatException('Malformed/truncated JSON output from model.');
    }

    return withoutFence.substring(start, end + 1).trim();
  }

  int _findJsonEnd(String source, int start) {
    final open = source[start];
    final close = open == '{' ? '}' : ']';

    var depth = 0;
    var inString = false;
    var escaping = false;

    for (var i = start; i < source.length; i++) {
      final ch = source[i];

      if (escaping) {
        escaping = false;
        continue;
      }

      if (ch == '\\') {
        escaping = true;
        continue;
      }

      if (ch == '"') {
        inString = !inString;
        continue;
      }

      if (inString) {
        continue;
      }

      if (ch == open) {
        depth++;
      } else if (ch == close) {
        depth--;
        if (depth == 0) {
          return i;
        }
      }
    }

    return -1;
  }

  /// Called when the user taps "Download" in the consent dialog.
  /// Starts the download, reports progress, then resumes generation.
  Future<void> confirmDownload() async {
    try {
      await WakelockPlus.enable();

      state = state.copyWith(
        status: CreateStatus.modelDownloading,
        downloadProgress: 0.0,
      );

      final downloader = ModelDownloadManager();
      await for (final progress in downloader.download()) {
        state = state.copyWith(
          status: CreateStatus.modelDownloading,
          downloadProgress: progress,
        );
      }

      state = state.copyWith(status: CreateStatus.idle, downloadProgress: null);
      await generatePodcast();
    } catch (_) {
      state = state.copyWith(
        status: CreateStatus.failed,
        error: 'Download failed. Check your connection and try again.',
      );
      await WakelockPlus.disable();
    }
  }

  /// Called when the user taps "Not now" in the consent dialog.
  /// Returns to idle with URLs intact so the user can try again later.
  void cancelDownload() {
    state = state.copyWith(status: CreateStatus.idle, downloadProgress: null);
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
    this.downloadProgress,
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
  final double? downloadProgress;
  final String? currentSpeaker;
  final String? partialAudioPath;
  final Episode? episode;
  final String? error;
  final bool hasCheckedCompatibility;

  CreateState copyWith({
    CreateStatus? status,
    List<String>? urls,
    double? progress,
    double? downloadProgress,
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
      downloadProgress: downloadProgress,
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
  awaitingDownloadConsent,
  modelDownloading,
  scraping,
  analyzing,
  generatingTranscript,
  synthesizing,
  stitching,
  complete,
  failed,
}
