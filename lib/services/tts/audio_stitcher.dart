import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:threadcast/core/extensions.dart';

import '../llm/models/transcript.dart';

class AudioStitcher {
  /// Takes ordered list of synthesized segments and produces a single WAV.
  /// Handles pause_before_ms and overlap_previous timing.
  Future<String> stitch({
    required List<TranscriptSegment> segments,
    required String episodeId,
  }) async {
    final outputPath = await _episodePath(episodeId);

    // Fix 1: Ensure the output directory exists before FFmpeg tries to write to it.
    await Directory(File(outputPath).parent.path).create(recursive: true);

    // Fix 2: FFmpeg amix requires 2+ inputs. For a single segment, just copy the file.
    if (segments.length == 1) {
      await File(segments.first.audioFilePath!).copy(outputPath);
      return outputPath;
    }

    final timeline = _buildTimeline(segments);

    // Fix 3: Capture the session and check the exit code — don't silently ignore failures.
    final session = await FFmpegKit.execute(_buildFfmpegCommand(timeline, outputPath));
    final returnCode = await session.getReturnCode();
    if (!ReturnCode.isSuccess(returnCode)) {
      final logs = await session.getOutput();
      throw Exception('FFmpeg stitching failed (exit code $returnCode). Logs: $logs');
    }

    // Fix 4: Clean up individual segment temp files now that they are merged.
    for (final seg in segments) {
      if (seg.audioFilePath != null) {
        await File(seg.audioFilePath!).deleteIfExists();
      }
    }

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
