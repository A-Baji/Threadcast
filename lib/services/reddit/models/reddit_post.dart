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

  factory RedditPost.fromJson(Map<String, dynamic> postData, Map<String, dynamic> commentsData) {
    // Implementation needed - parse Reddit API response
    // For now, stub
    return RedditPost(
      id: postData['data']['children'][0]['data']['id'],
      subreddit: postData['data']['children'][0]['data']['subreddit'],
      title: postData['data']['children'][0]['data']['title'],
      selftext: postData['data']['children'][0]['data']['selftext'],
      authorName: postData['data']['children'][0]['data']['author'],
      score: postData['data']['children'][0]['data']['score'],
      numComments: postData['data']['children'][0]['data']['num_comments'],
      createdUtc: DateTime.fromMillisecondsSinceEpoch(
        (postData['data']['children'][0]['data']['created_utc'] * 1000).toInt(),
      ),
      comments: [], // Parse comments
    );
  }
}
