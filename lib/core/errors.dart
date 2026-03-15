/// Typed error codes used throughout the pipeline.
/// See CLAUDE.md Error Handling Strategy for user-facing messages.
class ThreadcastError {
  static const modelUnavailable = 'MODEL_UNAVAILABLE';
  static const redditAuthExpired = 'REDDIT_AUTH_EXPIRED';
  static const redditRateLimited = 'REDDIT_RATE_LIMITED';
  static const contextTooLong = 'CONTEXT_TOO_LONG';
  static const generationFailed = 'GENERATION_FAILED';
  static const ttsFailed = 'TTS_FAILED';
  static const invalidUrl = 'INVALID_URL';
  static const backgroundBlocked = 'BACKGROUND_BLOCKED';
  static const cancelled = 'CANCELLED';
}
