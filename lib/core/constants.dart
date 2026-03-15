class AppConstants {
  // Set to empty string during development (uses public .json endpoint)
  // Set to your approved Reddit client ID for production OAuth flow
  static const redditClientId = '';

  static const redditRedirectUri = 'threadcast://oauth/callback';

  // TODO: replace YOUR_REDDIT_USERNAME before going to production
  static const redditUserAgent =
      'ios:com.threadcast.app:v1.0.0 (by /u/YOUR_REDDIT_USERNAME)';

  static const redditScopes = 'read identity';
}