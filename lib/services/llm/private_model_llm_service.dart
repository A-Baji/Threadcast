import 'package:flutter_gemma/flutter_gemma.dart';

import '../../core/constants.dart';
import '../../core/errors.dart';
import '../reddit/models/reddit_post.dart';
import 'llm_service.dart';
import 'model_download_manager.dart';

/// LLM service powered by flutter_gemma (MediaPipe GenAI Tasks API).
///
/// Works identically on Android and iOS — flutter_gemma abstracts the native
/// MediaPipe Kotlin and Swift SDKs behind a single Dart interface.
///
/// Requires [ModelDownloadManager.isModelReady()] to return true before
/// [generateRaw] is called.
class PrivateModelLlmService implements LlmService {
  // Derived from AppConstants.gemmaPromptCharLimit which is itself derived from
  // gemmaInputBudget. Change the constants in constants.dart, not here.
  static const int _promptCharBudget = AppConstants.gemmaPromptCharLimit;

  InferenceModel? _model;

  @override
  Future<bool> isAvailable() async => true;

  /// Initializes the flutter_gemma engine with the on-disk model.
  /// Safe to call multiple times — subsequent calls are no-ops.
  Future<void> initialize() async {
    if (_model != null) {
      return;
    }

    final path = await ModelDownloadManager.modelPath();

    await FlutterGemma.installModel(
      modelType: ModelType.gemmaIt, // Adjust to your model type (e.g., gemma2b, deepSeek)
    ).fromFile(path).install();

    _model = await FlutterGemmaPlugin.instance.createModel(
      modelType: ModelType.gemmaIt,
      // GPU/OpenCL initialization can hard-crash on devices/environments
      // without a compatible OpenCL stack (e.g. Android emulators).
      // CPU backend is slower but avoids native SIGSEGV failures.
      preferredBackend: PreferredBackend.cpu,
      maxTokens: AppConstants.gemmaMaxTokens,
    );
  }

  @override
  Future<String> generateRaw(String prompt) async {
    await initialize();

    final session = await _model!.createSession(
      // Greedy decoding (topK=1) can get stuck in repetitive loops and run
      // until sequence exhaustion. A small sampling window tends to reach EOS
      // earlier while preserving structured JSON quality.
      topK: 40,
      temperature: 0.4,
    );
    try {
      final safePrompt = _truncatePrompt(_tightenGemmaPrompt(prompt));
      await session.addQueryChunk(Message.text(text: safePrompt, isUser: true));
      final response = await session.getResponse();

      if (response.trim().isEmpty) {
        throw Exception(ThreadcastError.generationFailed);
      }

      return response;
    } finally {
      await session.close();
    }
  }

  @override
  Stream<LlmProgress> generateTranscript({
    required List<RedditPost> posts,
    required String episodeId,
  }) {
    throw UnimplementedError('Use generateRaw directly via CreateNotifier.');
  }

  Future<void> dispose() async {
    await _model?.close();
    _model = null;
  }

  String _truncatePrompt(String prompt) {
    if (prompt.length <= _promptCharBudget) {
      return prompt;
    }

    return '${prompt.substring(0, _promptCharBudget)}\n\n'
        '[Truncated to fit on-device model token budget.]';
  }

  String _tightenGemmaPrompt(String prompt) {
    const hardLimit = '\n\nIMPORTANT HARD LIMITS:\n'
        '- Return valid JSON only.\n'
        '- Keep the response concise.\n'
        '- Stop immediately after the JSON closes.';

    if (prompt.contains('IMPORTANT HARD LIMITS:')) {
      return prompt;
    }
    return '$prompt$hardLimit';
  }
}
