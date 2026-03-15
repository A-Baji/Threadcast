import 'package:dio/dio.dart';
import '../../core/constants.dart';
import 'reddit_auth_service.dart';
import 'models/reddit_post.dart';

class RedditScraper {
  final Dio _dio;
  final RedditAuthService _auth;

  RedditScraper(this._dio, this._auth);

  // True when a client ID is configured and an OAuth token is available
  bool get _isAuthenticated => AppConstants.redditClientId.isNotEmpty && _auth.hasValidToken;

  /// Fetch and parse a single Reddit post.
  /// Automatically uses the OAuth API when credentials are available,
  /// falling back to the public .json endpoint for development.
  Future<RedditPost> fetchPost(String url) async {
    final postId = _extractPostId(url);
    final endpoint =
        _isAuthenticated ? 'https://oauth.reddit.com/comments/$postId' : 'https://www.reddit.com/comments/$postId.json';

    final headers = _isAuthenticated
        ? {'Authorization': 'Bearer ${await _auth.getAccessToken()}', 'User-Agent': AppConstants.redditUserAgent}
        : {'User-Agent': AppConstants.redditUserAgent};

    final response = await _dio.get(
      endpoint,
      options: Options(headers: headers),
      queryParameters: {
        'sort': 'top',
        'limit': 100,
        'depth': 3,
        'raw_json': 1,
      },
    );

    // Both endpoints return a 2-element array: [postData, commentsData]
    return RedditPost.fromJson(response.data[0], response.data[1]);
  }

  /// Extract the post ID from any Reddit URL format.
  /// Handles: reddit.com/r/sub/comments/ID/slug/
  ///          redd.it/ID
  ///          old.reddit.com/r/sub/comments/ID/
  String _extractPostId(String url) {
    final uri = Uri.parse(url);
    final segments = uri.pathSegments;
    final commentsIdx = segments.indexOf('comments');
    if (commentsIdx != -1 && commentsIdx + 1 < segments.length) {
      return segments[commentsIdx + 1];
    }
    // redd.it/ID short links
    if (uri.host == 'redd.it' && segments.isNotEmpty) {
      return segments.first;
    }
    throw FormatException('Could not extract post ID from URL: $url');
  }
}
