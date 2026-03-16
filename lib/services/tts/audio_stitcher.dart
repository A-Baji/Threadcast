import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:path_provider/path_provider.dart';

import '../llm/models/transcript.dart';

class AudioStitcher {
  /// Takes ordered list of synthesized segments and produces a single WAV.
  /// Handles pause_before_ms and overlap_previous timing.
  Future<String> stitch({
    required List<TranscriptSegment> segments,
    required String episodeId,
  }) async {
    // Build ffmpeg filter_complex for precise timing
    // Each segment is placed at its calculated timestamp
    // Overlapping segments are mixed at their overlap point

    final timeline = _buildTimeline(segments);
    final outputPath = await _episodePath(episodeId);

    await FFmpegKit.execute(_buildFfmpegCommand(timeline, outputPath));
    return outputPath;
  }

  List<_SegmentTiming> _buildTimeline(List<TranscriptSegment> segments) {
    final timing = <_SegmentTiming>[];
    var currentMs = 0;

    for (int i = 0; i < segments.length; i++) {
      final seg = segments[i];
      currentMs += seg.delivery.pauseBeforeMs;

      if (seg.delivery.overlapPrevious && timing.isNotEmpty) {
        // Start this segment 500ms before the previous one ends
        final prevEnd = timing.last.startMs + timing.last.durationMs;
        currentMs = prevEnd - 500;
      }

      timing.add(_SegmentTiming(
        filePath: seg.audioFilePath!,
        startMs: currentMs,
        durationMs: seg.audioDuration!.inMilliseconds,
      ));

      currentMs += seg.audioDuration!.inMilliseconds;
    }

    return timing;
  }

  String _buildFfmpegCommand(List<_SegmentTiming> timing, String outputPath) {
    final inputs = timing.map((t) => '-i "${t.filePath}"').join(' ');
    final delays = timing.mapIndexed((i, t) => '[$i:a]adelay=${t.startMs}|${t.startMs}[s$i]').join(';');
    final mix = '${timing.mapIndexed((i, _) => '[s$i]').join('')}amix=inputs=${timing.length}:normalize=0[out]';

    return '$inputs -filter_complex "$delays;$mix" -map "[out]" '
        '-acodec pcm_s16le -ar 24000 "$outputPath"';
  }

  Future<String> _episodePath(String episodeId) async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/episodes/$episodeId/audio.wav';
  }
}

class _SegmentTiming {
  final String filePath;
  final int startMs;
  final int durationMs;

  _SegmentTiming({
    required this.filePath,
    required this.startMs,
    required this.durationMs,
  });
}

extension IterableExtensions<T> on Iterable<T> {
  Iterable<E> mapIndexed<E>(E Function(int index, T item) f) {
    var index = 0;
    return map((item) => f(index++, item));
  }
}
