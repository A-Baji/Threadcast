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
  // Keep an emergency guard to avoid native aborts when malformed inputs exceed
  // the model context budget. Approximation uses ~4 chars/token and reserves
  // 1k tokens for generation output.
  static const int _promptCharBudget = (AppConstants.gemmaMaxTokens - 1024) * 4;

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

    final modelManager = FlutterGemmaPlugin.instance.modelManager;
    await modelManager.setModelPath(path);

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

    final session = await _model!.createSession();
    try {
      final safePrompt = _truncatePrompt(prompt);
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
}
