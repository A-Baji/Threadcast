import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

import '../reddit/models/reddit_post.dart';
import 'llm_service.dart';

class OsLlmService implements LlmService {
  static const _channel = MethodChannel('com.threadcast.app/llm');

  @override
  Future<bool> isAvailable() async {
    try {
      return await _channel.invokeMethod('isAvailable');
    } catch (e) {
      return false;
    }
  }

  @override
  Stream<LlmProgress> generateTranscript({
    required List<RedditPost> posts,
    required String episodeId,
  }) async* {
    yield LlmProgress.analyzing;
    await Future.delayed(const Duration(seconds: 1)); // Mock delay

    yield LlmProgress.writing;
    await Future.delayed(const Duration(seconds: 2)); // Mock delay

    // Return mock transcript JSON
    yield LlmProgress.complete;
  }

  // For testing, return mock JSON for either analysis or transcript.
  @override
  Future<String> generateRaw(String prompt) async {
    // Simple heuristic to choose analysis vs transcript output
    if (prompt.contains('You are analyzing a Reddit post')) {
      return jsonEncode({
        'tone': 'talk_show',
        'tone_reasoning': 'The post is conversational and seeks opinions.',
        'speakers': [
          {
            'id': 'op',
            'reddit_username': 'op_user',
            'role': 'main_speaker',
            'personality_notes': 'Casual and self-reflective.',
            'voice_gender': 'neutral',
          },
          {
            'id': 'speaker_2',
            'reddit_username': 'commenter1',
            'role': 'commenter',
            'personality_notes': 'Direct and a bit sarcastic.',
            'voice_gender': 'female',
            'merged_usernames': [],
          }
        ],
        'selected_comment_ids': [],
        'episode_title': 'Mock Episode Title',
      });
    }

    // Otherwise, return a mock transcript JSON
    return jsonEncode([
      {
        "speaker_id": "op",
        "text": "This is a mock transcript segment from the OP.",
        "delivery": {"pace": "normal", "emotion": "calm", "pause_before_ms": 0, "overlap_previous": false}
      },
      {
        "speaker_id": "speaker_2",
        "text": "And this is a mock response from a commenter.",
        "delivery": {"pace": "normal", "emotion": "excited", "pause_before_ms": 500, "overlap_previous": false}
      }
    ]);
  }
}
