import 'reddit_comment.dart';

class RedditPost {
  final String id;
  final String subreddit;
  final String title;
  final String selftext; // Full post body
  final String authorName;
  final int score;
  final int numComments;
  final DateTime createdUtc;
  final List<RedditComment> comments;

  RedditPost({
    required this.id,
    required this.subreddit,
    required this.title,
    required this.selftext,
    required this.authorName,
    required this.score,
    required this.numComments,
    required this.createdUtc,
    required this.comments,
  });

  factory RedditPost.fromJson(
    Map<String, dynamic> postListing,
    Map<String, dynamic> commentsListing,
  ) {
    final postData = Map<String, dynamic>.from(
      ((postListing['data'] as Map<String, dynamic>)['children'] as List).first['data'] as Map,
    );

    final commentChildren = ((commentsListing['data'] as Map<String, dynamic>)['children'] as List?) ?? const [];
    final comments = commentChildren
        .where((child) => child is Map && child['kind'] == 't1')
        .map(
          (child) => RedditComment.fromJson(
            Map<String, dynamic>.from((child as Map)['data'] as Map),
            postData['author']?.toString() ?? '',
          ),
        )
        .toList();

    final createdUtcSeconds = (postData['created_utc'] as num?) ?? 0;

    return RedditPost(
      id: postData['id']?.toString() ?? '',
      subreddit: postData['subreddit']?.toString() ?? '',
      title: postData['title']?.toString() ?? '',
      selftext: postData['selftext']?.toString() ?? '',
      authorName: postData['author']?.toString() ?? '',
      score: (postData['score'] as num?)?.toInt() ?? 0,
      numComments: (postData['num_comments'] as num?)?.toInt() ?? comments.length,
      createdUtc: DateTime.fromMillisecondsSinceEpoch((createdUtcSeconds * 1000).toInt()),
      comments: comments,
    );
  }
}
