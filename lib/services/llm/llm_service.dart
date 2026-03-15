import '../reddit/models/reddit_post.dart';

abstract class LlmService {
  /// Returns true if the OS model is available on this device/OS version.
  Future<bool> isAvailable();

  /// Generates a structured transcript from scraped Reddit data.
  /// Streams progress events for UI updates.
  Stream<LlmProgress> generateTranscript({
    required List<RedditPost> posts, // Ordered list (multi-part support)
    required String episodeId,
  });

  /// Generates raw model text for a given prompt.
  Future<String> generateRaw(String prompt);
}

enum LlmProgress {
  analyzing, // Personality + tone analysis phase
  writing, // Transcript generation phase
  complete,
  failed,
}
