import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../llm/models/transcript.dart';

/// Stub TTS service for compilation and local testing.
///
/// This implementation creates empty WAV files so the pipeline can run end-to-end.
class TtsService {
  Future<void> initialize() async {
    // No-op for stub implementation.
  }

  /// Synthesizes a single transcript segment.
  /// Returns path to the generated WAV file.
  Future<String> synthesizeSegment({
    required TranscriptSegment segment,
    required String voice,
    required String episodeId,
    required int segmentIndex,
  }) async {
    // Create an empty WAV file placeholder.
    final outputPath = await _segmentPath(episodeId, segmentIndex);
    final outFile = File(outputPath);
    await outFile.create(recursive: true);
    await outFile.writeAsBytes([]);
    return outputPath;
  }

  Future<String> _segmentPath(String episodeId, int index) async {
    final dir = await getTemporaryDirectory();
    return '${dir.path}/$episodeId/segment_$index.wav';
  }
}