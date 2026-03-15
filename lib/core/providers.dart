import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../models/episode.dart';
import '../services/llm/llm_prompt_builder.dart';
import '../services/llm/llm_service.dart';
import '../services/llm/os_llm_service.dart';
import '../services/reddit/reddit_auth_service.dart';
import '../services/reddit/reddit_scraper.dart';
import '../services/tts/audio_stitcher.dart';
import '../services/tts/tts_service.dart';

// Global providers

final dioProvider = Provider<Dio>((ref) => Dio());

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

final isarProvider = Provider<Future<Isar>>((ref) async {
  final dir = await getApplicationDocumentsDirectory();
  return Isar.open(
    [EpisodeSchema],
    directory: dir.path,
  );
});

// Service providers

final redditAuthServiceProvider = Provider<RedditAuthService>((ref) {
  return RedditAuthService();
});

final redditScraperProvider = Provider<RedditScraper>((ref) {
  return RedditScraper(
    ref.watch(dioProvider),
    ref.watch(redditAuthServiceProvider),
  );
});

final llmServiceProvider = Provider<LlmService>((ref) {
  return OsLlmService();
});

final llmPromptBuilderProvider = Provider<LlmPromptBuilder>((ref) {
  return LlmPromptBuilder();
});

final ttsServiceProvider = Provider<TtsService>((ref) {
  return TtsService();
});

final audioStitcherProvider = Provider<AudioStitcher>((ref) {
  return AudioStitcher();
});
