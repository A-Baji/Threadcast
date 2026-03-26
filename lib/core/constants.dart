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

  /// KV cache allocation passed to flutter_gemma's createModel().
  ///
  /// In MediaPipe's LLM Inference API, maxTokens controls how much memory is
  /// pre-allocated for the key-value cache at model load time — it is NOT a
  /// runtime limit on prompt length. The KV cache costs approximately 72 KB per
  /// token for Gemma 3 1B.
  ///
  /// 8,192 tokens × 72 KB = ~576 MB KV cache
  /// + ~800 MB model weights = ~1.4 GB total
  ///
  /// This is sustainable on devices with 8 GB+ total RAM (Pixel 8, S23+, S24+).
  /// Gemma 3 1B's theoretical context window is 32K; we use 8K because the full
  /// 32K KV cache (~2.3 GB) causes an OOM kill on virtually every mobile device.
  static const gemmaMaxTokens = 8192;

  /// Tokens reserved for model output within the gemmaMaxTokens budget.
  /// The remaining tokens are available for the prompt (input).
  static const gemmaOutputReserve = 512;

  /// Tokens available for prompt input after reserving output headroom.
  /// Prompt builder methods must keep their rendered output below this limit.
  static const gemmaInputBudget = gemmaMaxTokens - gemmaOutputReserve; // 7,680

  /// Approximate character limit for Gemma input prompts.
  /// Derived from gemmaInputBudget at ~4 characters per token.
  /// Used as a fast pre-check before the more precise token estimator runs.
  static const gemmaPromptCharLimit = gemmaInputBudget * 4; // ~30,720 chars
}
