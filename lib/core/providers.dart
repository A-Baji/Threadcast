import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:threadcast/services/llm/llm_service_router.dart';

import '../models/episode.dart';
import '../services/llm/llm_prompt_builder.dart';
import '../services/llm/llm_service.dart';
import '../services/reddit/reddit_auth_service.dart';
import '../services/reddit/reddit_scraper.dart';
import '../services/tts/audio_stitcher.dart';
import '../services/tts/tts_service.dart';

final dioProvider = Provider<Dio>((ref) => Dio());

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

/// Drift database provider -- synchronous, dispose-aware.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final redditAuthServiceProvider = Provider<RedditAuthService>(
  (ref) => RedditAuthService(),
);

final redditScraperProvider = Provider<RedditScraper>((ref) => RedditScraper(
      ref.watch(dioProvider),
      ref.watch(redditAuthServiceProvider),
    ));

final llmServiceProvider = Provider<LlmService>((ref) => LlmServiceRouter());
final llmPromptBuilderProvider = Provider<LlmPromptBuilder>((ref) => LlmPromptBuilder());
final ttsServiceProvider = Provider<TtsService>((ref) => TtsService());
final audioStitcherProvider = Provider<AudioStitcher>((ref) => AudioStitcher());
