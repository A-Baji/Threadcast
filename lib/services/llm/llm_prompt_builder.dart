import 'dart:convert';
import '../reddit/models/reddit_post.dart';
import '../reddit/models/reddit_comment.dart';

class LlmPromptBuilder {
  String buildAnalysisPrompt(List<RedditPost> posts) {
    // For multi-part: concatenate posts, label each part
    final postSection = posts.length == 1
        ? _formatPost(posts.first)
        : posts.mapIndexed((i, p) => '## Part ${i + 1}\n${_formatPost(p)}').join('\n\n');

    final allComments = posts.expand((p) => p.comments).toList();
    final commentsJson = jsonEncode(allComments.map((c) => c.toJson()).toList());

    return '''
You are analyzing a Reddit post to prepare it for conversion into a podcast.

## Input Data
<post>
SUBREDDIT: ${posts.first.subreddit}
TITLE: ${posts.map((p) => p.title).join(' / ')}
AUTHOR: ${posts.first.authorName}
BODY:
$postSection
</post>

<comments>
$commentsJson
</comments>

## Your Task
Analyze the post and comments and return a JSON object with the following structure:

{
  "tone": "true_crime" | "talk_show" | "documentary" | "comedic" | "heartfelt",
  "tone_reasoning": "Brief explanation of why this tone fits",
  "speakers": [
    {
      "id": "op",
      "reddit_username": "${posts.first.authorName}",
      "role": "main_speaker",
      "personality_notes": "How they speak — e.g. anxious and self-deprecating, uses run-on sentences, lots of qualifiers",
      "voice_gender": "male" | "female" | "neutral"
    }
  ],
  "selected_comment_ids": ["id1", "id2"],
  "episode_title": "A punchy, engaging episode title (not the Reddit post title verbatim)"
}

## Rules
- Tone must be inferred entirely from content. Do not default to any tone.
- Personality notes must be grounded in evidence from the actual writing.
- Only include comments that meaningfully advance the narrative.
- Aim for 2-5 total speakers including OP.
''';
  }

  String buildTranscriptPrompt({
    required List<RedditPost> posts,
    required Map<String, dynamic> analysis,
  }) {
    final selectedIds = (analysis['selected_comment_ids'] as List).cast<String>().toSet();
    final selectedComments =
        posts.expand((p) => _flattenComments(p.comments)).where((c) => selectedIds.contains(c.id)).toList();

    return '''
You are converting a Reddit post and selected comments into a podcast transcript.

## Analysis Results
<analysis>
${jsonEncode(analysis)}
</analysis>

## Original Content
<post>
${posts.map((p) => p.selftext).join('\n\n---\n\n')}
</post>

<selected_comments>
${jsonEncode(selectedComments.map((c) => c.toJson()).toList())}
</selected_comments>

## Output Format
Return a JSON array of transcript segments:

[
  {
    "speaker_id": "op",
    "text": "The spoken dialogue text",
    "delivery": {
      "pace": "normal" | "slow" | "fast",
      "emotion": "calm" | "anxious" | "frustrated" | "upset" | "excited" | "sarcastic" | "empathetic",
      "pause_before_ms": 0,
      "overlap_previous": false
    }
  }
]

## Rules — CRITICAL
- The OP's post must be adapted into spoken dialogue.
- Each commenter's core sentiment must be preserved.
- Do not editorialize. Do not add a narrator.
- Match the tone from analysis: ${analysis['tone']}
- Aim for 8-15 minutes of audio.
''';
  }

  List<RedditComment> _flattenComments(List<RedditComment> comments) {
    final result = <RedditComment>[];
    for (final c in comments) {
      result.add(c);
      result.addAll(_flattenComments(c.replies));
    }
    return result;
  }

  String _formatPost(RedditPost post) {
    return post.selftext;
  }
}

extension IterableExtensions<T> on Iterable<T> {
  Iterable<E> mapIndexed<E>(E Function(int index, T item) f) {
    var index = 0;
    return map((item) => f(index++, item));
  }
}
