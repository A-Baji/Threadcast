import 'dart:convert';

import 'package:threadcast/core/constants.dart';

import '../reddit/models/reddit_comment.dart';
import '../reddit/models/reddit_post.dart';

const String _analysisPromptTemplate = '''You are analyzing a Reddit post to prepare it for conversion into a podcast.

## Input Data
<post>
SUBREDDIT: {subreddit}
TITLE: {title}
AUTHOR: {author}
BODY:
{post_body}
</post>

<comments>
{comments_json}
</comments>

## Your Task
Analyze the post and comments and return a JSON object with the following structure:

{
  "tone": "true_crime" | "talk_show" | "documentary" | "comedic" | "heartfelt",
  "tone_reasoning": "Brief explanation of why this tone fits",
  "speakers": [
    {
      "id": "op",
      "reddit_username": "{post_author}",
      "role": "main_speaker",
      "personality_notes": "How they speak — e.g. anxious and self-deprecating, uses run-on sentences, lots of qualifiers",
      "voice_gender": "male" | "female"
    },
    {
      "id": "speaker_2",
      "reddit_username": "commenter_username OR 'composite' if multiple merged",
      "role": "commenter",
      "personality_notes": "...",
      "voice_gender": "male" | "female",
      "merged_usernames": []   // List of usernames merged into this composite speaker, empty if single
    }
    // Include only commenters worth including in the podcast
    // Merge multiple commenters with the same energy/role into one speaker
    // Aim for 2-5 total speakers including OP
  ],
  "selected_comment_ids": ["id1", "id2"],   // Comment IDs selected for inclusion
  "episode_title": "A punchy, engaging episode title (not the Reddit post title verbatim)"
}

## Rules
- Tone must be inferred entirely from content. Do not default to any tone.
- Personality notes must be grounded in evidence from the actual writing — word choice, sentence structure, punctuation habits, emoji usage, etc.
- Only include comments that meaningfully advance the narrative or represent a significant reaction. Exclude low-effort comments, pure jokes with no substance, and comments that repeat a point already made.
- If OP has replied to commenters, prioritize those comment chains — the conversation dynamic between OP and commenters is more interesting than isolated takes.
- You may consolidate multiple commenters into a single composite speaker if they share a clear role (e.g. several people all saying "leave him", several people defending OP). Composite speakers should feel like one coherent voice.''';

const String _transcriptPromptTemplate =
    '''You are converting a Reddit post and selected comments into a podcast transcript.

## Analysis Results
<analysis>
{analysis_json_from_phase_1}
</analysis>

## Original Content
<post>
{post_body}
</post>

<selected_comments>
{selected_comments_json}
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
      "pause_before_ms": 0,      // Milliseconds of silence before this segment
      "overlap_previous": false  // True if this speaker is interrupting/overlapping the previous
    }
  }
]

## Rules — CRITICAL

### Faithfulness
- The OP's post must be adapted into spoken dialogue. You may reorder sentences for clarity and remove Reddit-specific formatting (e.g. "Edit:", "UPDATE:", bullet points, "throwaway account"). You may NOT add facts, invent details, or change what happened.
- Each commenter's core sentiment and factual claims must be preserved. You may adapt their phrasing for natural speech. You may NOT change their position or invent reactions they did not express.
- Do not editorialize. Do not add a narrator. The OP is the main speaker telling their own story in their own voice.

### Structure
- Begin with the OP telling their story. This should feel natural and conversational, not like someone reading an essay.
- Interject commenters at dramatically appropriate moments — not just at the end. A commenter can react mid-story when the OP describes the key moment that their comment addresses.
- OP may respond to commenters (use OP's actual replies if they exist; otherwise do not invent OP responses).
- Use overlap_previous: true sparingly for moments of genuine interruption or strong reaction. When used, keep the overlapping segment short (one sentence max).
- For multi-part posts, the OP's narrative flows continuously across parts. Do not announce "Part 2" — just continue the story.

### Delivery
- Match the tone from analysis: {tone}
- Delivery cues must be grounded in the content of the line, not randomly assigned.
- Pauses (pause_before_ms) should be used at emotional beats, revelations, or natural paragraph breaks. Typical values: 300ms (light pause), 800ms (dramatic pause), 1500ms (scene break).

### Personality
- Each speaker's dialogue style must reflect their personality_notes from the analysis.
- OP's verbal tics, hedging language, and sentence rhythm should feel consistent throughout.
- Commenter voices must feel distinct from each other and from OP.

### Length
- Aim for a transcript that would produce 8-15 minutes of audio at natural speaking pace (~130 words per minute).
- For multi-part posts, scale up proportionally.''';

class LlmPromptBuilder {
  int estimateTokens(String text) => _estimateTokens(text);

  String buildAnalysisPrompt(List<RedditPost> posts) {
    final postSection = posts.length == 1
        ? _formatPost(posts.first)
        : posts.mapIndexed((i, p) => '## Part ${i + 1}\n${_formatPost(p)}').join('\n\n');

    final sortedComments = posts.expand((p) => _flattenComments(p.comments)).toList()
      ..sort((a, b) {
        if (a.isOp != b.isOp) {
          return a.isOp ? -1 : 1;
        }
        return b.score.compareTo(a.score);
      });

    final commentsForPrompt = _truncateCommentsToFitBudget(
      comments: sortedComments,
      subreddit: posts.first.subreddit,
      title: posts.map((p) => p.title).join(' / '),
      author: posts.first.authorName,
      postBody: postSection,
      tokenBudget: 2000,
    );

    final commentsJson = jsonEncode(commentsForPrompt.map(_toPromptCommentJson).toList());

    return _analysisPromptTemplate
        .replaceAll('{subreddit}', _sanitizeText(posts.first.subreddit))
        .replaceAll('{title}', _sanitizeText(posts.map((p) => p.title).join(' / ')))
        .replaceAll('{author}', _sanitizeText(posts.first.authorName))
        .replaceAll('{post_author}', _sanitizeText(posts.first.authorName))
        .replaceAll('{post_body}', postSection)
        .replaceAll('{comments_json}', commentsJson);
  }

  String buildTranscriptPrompt({
    required List<RedditPost> posts,
    required Map<String, dynamic> analysis,
  }) {
    final selectedIds = (analysis['selected_comment_ids'] as List).cast<String>().toSet();
    final selectedComments =
        posts.expand((p) => _flattenComments(p.comments)).where((c) => selectedIds.contains(c.id)).toList();

    return _transcriptPromptTemplate
        .replaceAll('{analysis_json_from_phase_1}', jsonEncode(analysis))
        .replaceAll('{post_body}', posts.map((p) => _sanitizeText(p.selftext)).join('\n\n---\n\n'))
        .replaceAll('{selected_comments_json}', jsonEncode(selectedComments.map(_toPromptCommentJson).toList()))
        .replaceAll('{tone}', analysis['tone'] as String);
  }

  // -------------------------------------------------------------------------
  // Gemma 3 1B fallback prompts
  //
  // The OS-model prompts (buildAnalysisPrompt / buildTranscriptPrompt) are
  // optimised for the larger context windows of Gemini Nano and Foundation
  // Models. The Gemma prompts below are structurally identical in intent but:
  //   - Use a tighter schema definition to reduce template overhead
  //   - Derive all truncation limits from AppConstants.gemmaInputBudget so
  //     they automatically adjust if the budget constant is ever changed
  //   - Apply more aggressive comment truncation since comment bodies are the
  //     largest variable-cost component
  //
  // Budget allocation within the 7,680-token input budget:
  //   ~300  tokens — prompt template + schema definition
  //   ~600  tokens — post title + subreddit + author metadata
  //   ~800  tokens — post body (truncated if necessary)
  //   ~5,980 tokens — comments (truncated from bottom if over budget)
  //   ─────────────────────────────────────────────────────────
  //   7,680 tokens — total input budget (gemmaInputBudget)
  // -------------------------------------------------------------------------

  /// Analysis prompt for the Gemma 3 1B fallback path.
  ///
  /// Structurally equivalent to [buildAnalysisPrompt] but uses a more compact
  /// schema definition to reduce template token overhead, and enforces the
  /// gemmaInputBudget ceiling across all content fields.
  String buildGemmaAnalysisPrompt(List<RedditPost> posts) {
    final postSection = posts.length == 1
        ? _formatPost(posts.first)
        : posts.mapIndexed((i, p) => '## Part ${i + 1}\n${_formatPost(p)}').join('\n\n');

    final truncatedPostSection = _truncateTo(postSection, 3200);

    final sortedComments = posts.expand((p) => _flattenComments(p.comments)).toList()
      ..sort((a, b) {
        if (a.isOp != b.isOp) return a.isOp ? -1 : 1;
        return b.score.compareTo(a.score);
      });

    const templateOverheadChars = 1200;
    const metadataChars = 200;
    final postBodyChars = truncatedPostSection.length;
    final commentBudgetChars =
        (AppConstants.gemmaInputBudget * 4) - templateOverheadChars - metadataChars - postBodyChars;

    final commentsForPrompt = _truncateCommentsToFitBudget(
      comments: sortedComments,
      subreddit: posts.first.subreddit,
      title: posts.map((p) => p.title).join(' / '),
      author: posts.first.authorName,
      postBody: truncatedPostSection,
      tokenBudget: (commentBudgetChars / 4).floor().clamp(200, AppConstants.gemmaInputBudget),
    ).take(24).toList();

    final commentsJson = jsonEncode(
      commentsForPrompt.map((c) => _toGemmaPromptCommentJson(c, maxBodyChars: 420)).toList(),
    );

    const schema = '''Return only a JSON object. No markdown. No explanation.
Schema:
{
  "tone": "true_crime"|"talk_show"|"documentary"|"comedic"|"heartfelt",
  "tone_reasoning": "one sentence",
  "speakers": [
    {"id":"op","reddit_username":"<author>","role":"main_speaker","personality_notes":"brief","voice_gender":"male"|"female"},
    {"id":"speaker_2","reddit_username":"<name>","role":"commenter","personality_notes":"brief","voice_gender":"male"|"female","merged_usernames":[]}
  ],
  "selected_comment_ids": ["id1","id2"],
  "episode_title": "punchy title"
}
Rules: infer tone from content; 2-5 speakers total; exclude bot comments.''';

    return '$schema\n\n'
        'SUBREDDIT: ${_sanitizeText(posts.first.subreddit)}\n'
        'TITLE: ${_sanitizeText(posts.map((p) => p.title).join(" / "))}\n'
        'AUTHOR: ${_sanitizeText(posts.first.authorName)}\n\n'
        'POST:\n$truncatedPostSection\n\n'
        'COMMENTS:\n$commentsJson';
  }

  /// Transcript prompt for the Gemma 3 1B fallback path.
  ///
  /// Structurally equivalent to [buildTranscriptPrompt] but uses a more compact
  /// schema definition and enforces the gemmaInputBudget ceiling.
  String buildGemmaTranscriptPrompt({
    required List<RedditPost> posts,
    required Map<String, dynamic> analysis,
  }) {
    final selectedIds = (analysis['selected_comment_ids'] as List? ?? []).cast<String>().toSet();
    final selectedComments =
        posts.expand((p) => _flattenComments(p.comments)).where((c) => selectedIds.contains(c.id)).take(16).toList();

    final postBody = _truncateTo(
      posts.map((p) => _sanitizeText(p.selftext)).join('\n\n---\n\n'),
      2400,
    );

    final analysisJson = _truncateTo(jsonEncode(analysis), 1200);

    const templateOverheadChars = 1000;
    final commentBudgetChars =
        (AppConstants.gemmaInputBudget * 4) - templateOverheadChars - postBody.length - analysisJson.length;

    var usedChars = 0;
    final fittedComments = <Map<String, dynamic>>[];
    for (final c in selectedComments) {
      final commentJson = _toGemmaPromptCommentJson(c, maxBodyChars: 280);
      final commentStr = jsonEncode(commentJson);
      if (usedChars + commentStr.length > commentBudgetChars.clamp(400, 20000)) {
        break;
      }
      fittedComments.add(commentJson);
      usedChars += commentStr.length;
    }

    final tone = analysis['tone'] as String? ?? 'talk_show';

    const schema = '''Return only a JSON array. No markdown. No explanation.
Each element:
{
  "speaker_id": "op"|"speaker_2"|...,
  "text": "spoken dialogue",
  "delivery": {
    "pace": "normal"|"slow"|"fast",
    "emotion": "calm"|"anxious"|"frustrated"|"upset"|"excited"|"sarcastic"|"empathetic",
    "pause_before_ms": 0,
    "overlap_previous": false
  }
}
Rules:
- OP tells story in their own voice. No narrator.
- Interject commenters at dramatically appropriate moments, not just at the end.
- Delivery must match tone: TONE_PLACEHOLDER
- Preserve each speaker's personality from the analysis.
- Target 8-12 minutes of audio at ~130 words per minute.''';

    return '${schema.replaceAll('TONE_PLACEHOLDER', tone)}\n\n'
        'ANALYSIS:\n$analysisJson\n\n'
        'POST:\n$postBody\n\n'
        'SELECTED COMMENTS:\n${jsonEncode(fittedComments)}';
  }

  int _estimateTokens(String text) => (text.length / 4).ceil();

  List<RedditComment> _truncateCommentsToFitBudget({
    required List<RedditComment> comments,
    required String subreddit,
    required String title,
    required String author,
    required String postBody,
    required int tokenBudget,
  }) {
    final promptWithoutComments = _analysisPromptTemplate
        .replaceAll('{subreddit}', subreddit)
        .replaceAll('{title}', title)
        .replaceAll('{author}', author)
        .replaceAll('{post_author}', author)
        .replaceAll('{post_body}', postBody)
        .replaceAll('{comments_json}', '[]');

    var remaining = tokenBudget - _estimateTokens(promptWithoutComments);
    final result = <RedditComment>[];

    for (final comment in comments) {
      final tokens = _estimateTokens(comment.body);
      if (comment.isOp) {
        result.add(comment);
        remaining -= tokens;
        continue;
      }
      if (remaining - tokens < 0) {
        break;
      }
      remaining -= tokens;
      result.add(comment);
    }

    return result;
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
    return _sanitizeText(post.selftext);
  }

  String _truncateTo(String text, int maxChars) {
    if (text.length <= maxChars) return text;
    return '${text.substring(0, maxChars)}…';
  }

  Map<String, dynamic> _toPromptCommentJson(RedditComment comment) {
    return {
      'id': comment.id,
      'author': _sanitizeText(comment.authorName),
      'body': _sanitizeText(comment.body),
      'score': comment.score,
      'depth': comment.depth,
      'parent_id': comment.parentId,
      // Keep the key for schema familiarity, but avoid recursively embedding
      // entire reply trees in each flattened comment object.
      'replies': const <Map<String, dynamic>>[],
      'is_op': comment.isOp,
    };
  }

  Map<String, dynamic> _toGemmaPromptCommentJson(
    RedditComment comment, {
    required int maxBodyChars,
  }) {
    final json = _toPromptCommentJson(comment);
    json['body'] = _truncateTo(json['body'] as String, maxBodyChars);
    return json;
  }

  String _sanitizeText(String value) {
    return value.replaceAll(RegExp(r'[\u0000-\u0008\u000B\u000C\u000E-\u001F]'), ' ').trim();
  }
}

extension IterableExtensions<T> on Iterable<T> {
  Iterable<E> mapIndexed<E>(E Function(int index, T item) f) {
    var index = 0;
    return map((item) => f(index++, item));
  }
}
