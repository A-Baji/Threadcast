import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;

import '../llm/models/transcript.dart';
import 'tts_model_extractor.dart';

class TtsService {
  sherpa_onnx.OfflineTts? _tts;
  String? _modelDirPath;

  Future<void> initialize() async {
    if (_tts != null) return;

    sherpa_onnx.initBindings();

    _modelDirPath ??= await TtsModelExtractor.ensureExtracted();

    final config = sherpa_onnx.OfflineTtsConfig(
      model: sherpa_onnx.OfflineTtsModelConfig(
        kokoro: sherpa_onnx.OfflineTtsKokoroModelConfig(
          model: '$_modelDirPath/kokoro-v0_19.onnx',
          voices: '$_modelDirPath/voices.bin',
          tokens: '$_modelDirPath/tokens.txt',
          dataDir: '$_modelDirPath/espeak-ng-data',
        ),
      ),
    );

    _tts = sherpa_onnx.OfflineTts(config);
  }

  Future<String> synthesizeSegment({
    required TranscriptSegment segment,
    required String voice,
    required String episodeId,
    required int segmentIndex,
  }) async {
    await initialize();

    final outputPath = await _segmentPath(episodeId, segmentIndex);
    final outFile = File(outputPath);
    await outFile.parent.create(recursive: true);

    final text = segment.text.trim();

    if (text.isEmpty) {
      await outFile.writeAsBytes([]);
      return outFile.path;
    }

    final speed = switch (segment.delivery.pace) {
      'slow' => 0.85,
      'fast' => 1.15,
      _ => 1.0,
    };

    final sid = _voiceNameToIndex(voice);

    final audio = _tts!.generate(
      text: text,
      sid: sid,
      speed: speed,
    );

    final ok = sherpa_onnx.writeWave(
      filename: outputPath,
      samples: audio.samples,
      sampleRate: audio.sampleRate,
    );

    if (!ok) {
      throw Exception('Failed to write WAV file: $outputPath');
    }

    return outFile.path;
  }

  int _voiceNameToIndex(String voice) {
    const voiceMap = {
      'af_sarah': 0,
      'af_nicole': 1,
      'am_adam': 2,
      'am_michael': 3,
      'bf_emma': 4,
      'bm_george': 5,
    };

    final index = voiceMap[voice];
    if (index == null) {
      throw ArgumentError('Unknown voice: $voice');
    }

    return index;
  }

  Future<String> _segmentPath(String episodeId, int index) async {
    final dir = await getTemporaryDirectory();
    return '${dir.path}/$episodeId/segment_$index.wav';
  }

  void dispose() {
    _tts?.free();
    _tts = null;
  }
}
