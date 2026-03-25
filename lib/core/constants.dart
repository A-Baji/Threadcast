class AppConstants {
  // Set to empty string during development (uses public .json endpoint)
  // Set to your approved Reddit client ID for production OAuth flow
  static const redditClientId = '';

  static const redditRedirectUri = 'threadcast://oauth/callback';

  // TODO: replace YOUR_REDDIT_USERNAME before going to production
  static const redditUserAgent = 'ios:com.threadcast.app:v1.0.0 (by /u/YOUR_REDDIT_USERNAME)';

  static const redditScopes = 'read identity';

  /// Filename for the Gemma 3 1B IT INT4 model as stored in the app's
  /// support directory. The name is stable across app updates.
  static const gemmaModelFilename = 'gemma3-1b-it-int4.task';

  /// Primary + fallback public URLs for Gemma 3 1B IT INT4 model download.
  ///
  /// The first URL is the official LiteRT Community artifact. Some environments
  /// can return 401/403 due model license gating. The second URL is a public
  /// mirror fallback for download resiliency.
  static const gemmaModelUrls = <String>[
    'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/gemma3-1b-it-int4.task?download=true',
    'https://huggingface.co/AfiOne/gemma3-1b-it-int4.task/resolve/main/gemma3-1b-it-int4.task?download=true',
  ];

  /// Human-readable size shown in the download consent dialog.
  static const gemmaModelDisplaySize = '~800 MB';

  /// Gemma 3 1B context window used for local inference.
  /// Keep this in sync with `PrivateModelLlmService` createModel options.
  static const gemmaMaxTokens = 32768;
}
