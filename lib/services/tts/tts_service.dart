import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;

import '../llm/models/transcript.dart';
import 'tts_model_extractor.dart';

class TtsService {
  sherpa_onnx.OfflineTts? _tts;
  String? _modelDirPath;

  /// Key: voice name (e.g. 'am_adam'), Value: integer SID.
  Map<String, int> _voiceMap = {};

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  Future<void> initialize() async {
    if (_tts != null) return;

    sherpa_onnx.initBindings();
    _modelDirPath ??= await TtsModelExtractor.ensureExtracted();

    // Lexicon is optional — present in v1_0 but may be absent in other releases.
    // Pass it only if the file actually exists so initialization doesn't fail.
    final lexiconFile = File('$_modelDirPath/lexicon-us-en.txt');
    final lexiconPath = await lexiconFile.exists() ? lexiconFile.path : '';

    final config = sherpa_onnx.OfflineTtsConfig(
      model: sherpa_onnx.OfflineTtsModelConfig(
        kokoro: sherpa_onnx.OfflineTtsKokoroModelConfig(
          model: '$_modelDirPath/model.onnx',
          voices: '$_modelDirPath/voices.bin',
          tokens: '$_modelDirPath/tokens.txt',
          lexicon: lexiconPath,
          dataDir: '$_modelDirPath/espeak-ng-data',
          lang: 'en-us', // required for v1_0 multilingual model
        ),
        numThreads: 2,
        debug: false,
        provider: 'cpu',
      ),
      maxNumSenetences: 1,
    );

    _tts = sherpa_onnx.OfflineTts(config);
    _voiceMap = {
      'af_alloy': 0,
      'af_aoede': 1,
      'af_bella': 2,
      'af_jessica': 4,
      'af_kore': 5,
      'af_nicole': 6,
      'af_nova': 7,
      'af_river': 8,
      'af_sarah': 9,
      'af_sky': 10,
      'am_adam': 11,
      'am_echo': 12,
      'am_eric': 13,
      'am_fenrir': 14,
      'am_liam': 15,
      'am_michael': 16,
      'am_onyx': 17,
      'am_puck': 18,
      'am_santa': 19,
      'bf_alice': 20,
      'bf_emma': 21,
      'bf_isabella': 22,
      'bf_lily': 23,
      'bm_daniel': 24,
      'bm_fable': 25,
      'bm_george': 26,
      'bm_lewis': 27,
      'ef_dora': 28,
      'em_alex': 29,
      'em_santa': 30,
      'ff_siwis': 31,
      'hf_alpha': 32,
      'hf_beta': 33,
      'hm_omega': 34,
      'hm_psi': 35,
      'if_sara': 36,
      'im_nicola': 37,
      'jf_alpha': 38,
      'jf_gongitsune': 39,
      'jf_nezumi': 40,
      'jf_tebukuro': 41,
      'jm_kumo': 42,
      'pf_dora': 43,
      'pm_alex': 44,
      'pm_santa': 45,
      'zf_xiaobei': 46,
      'zf_xiaoni': 47,
      'zf_xiaoxiao': 48,
      'zf_xiaoyi': 49,
      'zm_yunjian': 50,
      'zm_yunxi': 51,
      'zm_yunxia': 52,
      'zm_yunyang': 53,
    };
  }

  /// Synthesizes [segment] using [voice] (a Kokoro voice name such as
  /// 'am_adam') and writes the result to a WAV file.
  ///
  /// Returns the absolute path to the WAV file and the audio duration so the
  /// caller can store it on the [TranscriptSegment] without a second read.
  Future<String> synthesizeSegment({
    required TranscriptSegment segment,
    required String voice,
    required String episodeId,
    required int segmentIndex,
  }) async {
    await initialize();

    final outputPath = await _segmentPath(episodeId, segmentIndex);
    await Directory(File(outputPath).parent.path).create(recursive: true);

    final text = segment.text.trim();

    // Return a silent placeholder for empty segments so the pipeline doesn't
    // break — AudioStitcher handles zero-duration segments gracefully.
    if (text.isEmpty) {
      await File(outputPath).writeAsBytes(_silentWavHeader(sampleRate: 24000));
      return outputPath;
    }

    final speed = switch (segment.delivery.pace) {
      'slow' => 0.85,
      'fast' => 1.15,
      _ => 1.0,
    };

    final sid = _sidForVoice(voice);
    final audio = _tts!.generate(text: text, sid: sid, speed: speed);

    final ok = sherpa_onnx.writeWave(
      filename: outputPath,
      samples: audio.samples,
      sampleRate: audio.sampleRate,
    );

    if (!ok) {
      throw Exception('TtsService: writeWave failed for $outputPath');
    }

    return outputPath;
  }

  /// All voice names available in the loaded model, sorted by SID.
  /// Only valid after [initialize] has been called.
  List<String> get availableVoices {
    final entries = _voiceMap.entries.toList()..sort((a, b) => a.value.compareTo(b.value));
    return entries.map((e) => e.key).toList();
  }

  void dispose() {
    _tts?.free();
    _tts = null;
    _voiceMap = {};
  }

  // -------------------------------------------------------------------------
  // Path helpers (consumed by create_provider.dart and AudioStitcher)
  // -------------------------------------------------------------------------

  String get modelDirPath {
    _assertInitialized();
    return _modelDirPath!;
  }

  String get modelPath => '${_modelDirPath!}/model.onnx';
  String get voicesPath => '${_modelDirPath!}/voices.bin';
  String get tokensPath => '${_modelDirPath!}/tokens.txt';
  String get espeakDataPath => '${_modelDirPath!}/espeak-ng-data';
  String get lexiconDataPath => '${_modelDirPath!}/lexicon-us-en.txt';

  // -------------------------------------------------------------------------
  // Internal helpers
  // -------------------------------------------------------------------------

  void _assertInitialized() {
    if (_tts == null || _modelDirPath == null) {
      throw StateError('TtsService.initialize() must be called first.');
    }
  }

  int _sidForVoice(String voice) {
    final sid = _voiceMap[voice];
    if (sid != null) return sid;

    // Unknown voice name — log and default to am_adam (or SID 0 if not found).
    debugPrint('TtsService: unknown voice "$voice", defaulting to am_adam.');
    return _voiceMap['am_adam'] ?? 0;
  }

  Future<String> _segmentPath(String episodeId, int index) async {
    final dir = await getTemporaryDirectory();
    return '${dir.path}/$episodeId/segment_$index.wav';
  }

  /// Generates a minimal valid WAV header for a zero-sample silent file.
  /// Used as a placeholder for empty segments.
  static List<int> _silentWavHeader({required int sampleRate}) {
    const channels = 1;
    const bitsPerSample = 16;
    const dataSize = 0;
    final byteRate = sampleRate * channels * bitsPerSample ~/ 8;
    const blockAlign = channels * bitsPerSample ~/ 8;

    return [
      // RIFF header
      0x52, 0x49, 0x46, 0x46, // "RIFF"
      44 & 0xFF, (44 >> 8) & 0xFF, (44 >> 16) & 0xFF, (44 >> 24) & 0xFF, // ChunkSize
      0x57, 0x41, 0x56, 0x45, // "WAVE"
      // fmt sub-chunk
      0x66, 0x6D, 0x74, 0x20, // "fmt "
      16, 0, 0, 0, // Subchunk1Size (PCM)
      1, 0, // AudioFormat (PCM)
      channels & 0xFF, (channels >> 8) & 0xFF,
      sampleRate & 0xFF, (sampleRate >> 8) & 0xFF,
      (sampleRate >> 16) & 0xFF, (sampleRate >> 24) & 0xFF,
      byteRate & 0xFF, (byteRate >> 8) & 0xFF,
      (byteRate >> 16) & 0xFF, (byteRate >> 24) & 0xFF,
      blockAlign & 0xFF, (blockAlign >> 8) & 0xFF,
      bitsPerSample & 0xFF, (bitsPerSample >> 8) & 0xFF,
      // data sub-chunk
      0x64, 0x61, 0x74, 0x61, // "data"
      dataSize & 0xFF, (dataSize >> 8) & 0xFF,
      (dataSize >> 16) & 0xFF, (dataSize >> 24) & 0xFF,
    ];
  }
}
