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
    // 1. Safely extract the data with null-aware operators
    final data = postListing['data'] as Map<String, dynamic>?;
    final children = data?['children'] as List<dynamic>?;

    // 2. Check if the list is empty or null before accessing .first
    if (children == null || children.isEmpty) {
      throw const FormatException('Malformed Reddit API response: No posts found.');
    }

    // 3. Extract the first item safely
    final firstChild = children.first as Map<dynamic, dynamic>?;
    final rawPostData = firstChild?['data'] as Map<dynamic, dynamic>?;

    if (rawPostData == null) {
      throw const FormatException('Malformed Reddit API response: Post data is missing.');
    }

    // 4. Finally, create your strongly-typed map
    final postData = Map<String, dynamic>.from(rawPostData);

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
