import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../llm/models/transcript.dart';
import 'tts_model_extractor.dart';

/// Stub TTS service for compilation and local testing.
///
/// This implementation still creates empty WAV files so the pipeline can run
/// end-to-end, but it now resolves the extracted model directory first so the
/// eventual Sherpa-ONNX integration can use real filesystem paths.
class TtsService {
  String? _modelDirPath;

  Future<void> initialize() async {
    _modelDirPath ??= await TtsModelExtractor.ensureExtracted();
  }

  /// Synthesizes a single transcript segment.
  /// Returns path to the generated WAV file.
  Future<String> synthesizeSegment({
    required TranscriptSegment segment,
    required String voice,
    required String episodeId,
    required int segmentIndex,
  }) async {
    await initialize();

    final outputPath = await _segmentPath(episodeId, segmentIndex);
    final outFile = File(outputPath);
    await outFile.create(recursive: true);
    await outFile.writeAsBytes([]);
    return outFile.path;
  }

  String get modelDirPath {
    final path = _modelDirPath;
    if (path == null) {
      throw StateError('TtsService.initialize() must be called before accessing modelDirPath.');
    }
    return path;
  }

  String get modelPath => '$modelDirPath/kokoro-v0_19.onnx';

  String get voicesPath => '$modelDirPath/voices.bin';

  String get tokensPath => '$modelDirPath/tokens.txt';

  String get espeakDataPath => '$modelDirPath/espeak-ng-data';

  Future<String> _segmentPath(String episodeId, int index) async {
    final dir = await getTemporaryDirectory();
    return '${dir.path}/$episodeId/segment_$index.wav';
  }
}
