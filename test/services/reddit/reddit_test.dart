import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:threadcast/services/reddit/models/reddit_post.dart';

void main() {
  test('parses real-style reddit listing JSON fixture', () {
    final fixturePath =
        Uri.file(Platform.script.toFilePath()).resolve('test/services/reddit/reddit_post_example.json').toFilePath();
    final jsonText = File(fixturePath).readAsStringSync();
    final payload = jsonDecode(jsonText) as List<dynamic>;

    final post = RedditPost.fromJson(
      Map<String, dynamic>.from(payload[0] as Map),
      Map<String, dynamic>.from(payload[1] as Map),
    );

    expect(post.id, 'abc123');
    expect(post.title, 'My test post');
    expect(post.authorName, 'post_op');
    expect(post.comments.length, 2); // skips `more`

    final first = post.comments[0];
    final second = post.comments[1];

    expect(first.id, 'c1');
    expect(first.isOp, false);
    expect(first.replies, isEmpty);

    expect(second.id, 'c2');
    expect(second.isOp, true);
    expect(second.replies.length, 1);
    expect(second.replies.first.id, 'c2r1');
    expect(second.replies.first.isOp, false);
    expect(second.replies.first.replies.length, 1);
    expect(second.replies.first.replies.first.id, 'c2r1r1');
    expect(second.replies.first.replies.first.isOp, true);

    expect(post.createdUtc.year, greaterThan(1970));
  });
}
