import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

import '../../core/errors.dart';
import '../reddit/models/reddit_post.dart';
import 'llm_prompt_builder.dart';
import 'llm_service.dart';

class OsLlmService implements LlmService {
  static const _channel = MethodChannel('com.threadcast.app/llm');

  final LlmPromptBuilder _promptBuilder = LlmPromptBuilder();

  @override
  Future<bool> isAvailable() async {
    try {
      return await _channel.invokeMethod<bool>('isAvailable') ?? false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Stream<LlmProgress> generateTranscript({
    required List<RedditPost> posts,
    required String episodeId,
  }) async* {
    try {
      yield LlmProgress.analyzing;
      final analysisRaw = await generateRaw(_promptBuilder.buildAnalysisPrompt(posts));
      final analysis = jsonDecode(analysisRaw) as Map<String, dynamic>;

      yield LlmProgress.writing;
      await generateRaw(_promptBuilder.buildTranscriptPrompt(posts: posts, analysis: analysis));

      yield LlmProgress.complete;
    } catch (_) {
      yield LlmProgress.failed;
      rethrow;
    }
  }

  @override
  Future<String> generateRaw(String prompt) async {
    final response = await _channel.invokeMethod<String>('generateTranscript', {
      'prompt': prompt,
    });

    if (response == null || response.trim().isEmpty) {
      throw PlatformException(
        code: ThreadcastError.generationFailed,
        message: 'Native LLM returned an empty response.',
      );
    }

    return response;
  }
}
