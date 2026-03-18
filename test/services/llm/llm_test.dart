import 'package:flutter_test/flutter_test.dart';
import 'package:threadcast/services/llm/llm_prompt_builder.dart';
import 'package:threadcast/services/reddit/models/reddit_comment.dart';
import 'package:threadcast/services/reddit/models/reddit_post.dart';

RedditComment mockComment(
  String id,
  String body, {
  int score = 1,
  bool isOp = false,
  int depth = 0,
  String? parentId,
}) {
  return RedditComment(
    id: id,
    authorName: isOp ? 'op' : 'commenter_$id',
    body: body,
    score: score,
    depth: depth,
    parentId: parentId,
    replies: const [],
    isOp: isOp,
  );
}

RedditPost mockPost(String body, List<RedditComment> comments) {
  return RedditPost(
    id: 'p1',
    subreddit: 'AITAH',
    title: 'Test post',
    selftext: body,
    authorName: 'op',
    score: 1,
    numComments: comments.length,
    createdUtc: DateTime.utc(2024, 1, 1),
    comments: comments,
  );
}

void main() {
  group('LlmPromptBuilder', () {
    test('truncates comments to fit token budget and keeps prompt under threshold', () {
      final builder = LlmPromptBuilder();
      final longPostBody = 'word ' * 800;
      final manyComments = List.generate(
        20,
        (i) => mockComment('c$i', 'word ' * 100, score: 20 - i),
      );

      final prompt = builder.buildAnalysisPrompt([mockPost(longPostBody, manyComments)]);

      expect(builder.estimateTokens(prompt), lessThan(2100));
    });

    test('retains OP replies when truncation occurs', () {
      final builder = LlmPromptBuilder();
      final postBody = 'word ' * 1600;
      final comments = <RedditComment>[
        mockComment('op_1', 'op reply ' * 40, score: 1, isOp: true, depth: 1, parentId: 't1_x'),
        mockComment('c1', 'comment ' * 200, score: 500),
        mockComment('c2', 'comment ' * 200, score: 499),
      ];

      final prompt = builder.buildAnalysisPrompt([mockPost(postBody, comments)]);

      expect(prompt, contains('"id":"op_1"'));
    });
  });
}
