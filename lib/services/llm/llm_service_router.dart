import '../reddit/models/reddit_post.dart';
import 'llm_service.dart';
import 'model_download_manager.dart';
import 'os_llm_service.dart';
import 'private_model_llm_service.dart';

/// Routes LLM calls to the best available backend.
///
/// Priority:
///   1. OsLlmService            — Gemini Nano (Android) or Foundation Models (iOS)
///   2. PrivateModelLlmService  — Gemma 3 1B via flutter_gemma (both platforms)
///
/// The OS availability check is performed once and cached for the app session.
class LlmServiceRouter implements LlmService {
  final OsLlmService _osService;
  final PrivateModelLlmService _privateService;

  LlmServiceRouter({
    OsLlmService? osService,
    PrivateModelLlmService? privateService,
  })  : _osService = osService ?? OsLlmService(),
        _privateService = privateService ?? PrivateModelLlmService();

  bool? _osAvailable;

  /// True when the OS model is unavailable AND Gemma has not been downloaded.
  /// CreateNotifier uses this to gate the download/consent flow.
  Future<bool> get needsModelDownload async {
    if (await _resolveOsAvailable()) {
      return false;
    }
    return !(await ModelDownloadManager.isModelReady());
  }

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<String> generateRaw(String prompt) async {
    if (await _resolveOsAvailable()) {
      return _osService.generateRaw(prompt);
    }
    return _privateService.generateRaw(prompt);
  }

  @override
  Stream<LlmProgress> generateTranscript({
    required List<RedditPost> posts,
    required String episodeId,
  }) {
    throw UnimplementedError('Use generateRaw directly.');
  }

  Future<bool> _resolveOsAvailable() async {
    _osAvailable ??= await _osService.isAvailable();
    return _osAvailable!;
  }
}
