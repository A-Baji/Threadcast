import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:threadcast/core/constants.dart';
import 'package:threadcast/services/reddit/models/reddit_post.dart';
import 'package:threadcast/services/reddit/reddit_auth_service.dart';
import 'package:threadcast/services/reddit/reddit_scraper.dart';

class _FakeRedditAuthService extends RedditAuthService {
  _FakeRedditAuthService({required this.tokenValid, required this.token});

  final bool tokenValid;
  final String token;

  @override
  bool get hasValidToken => tokenValid;

  @override
  Future<String> getAccessToken() async => token;
}

List<dynamic> _loadFixturePayload() {
  final fixturePath =
      Uri.file(Platform.script.toFilePath()).resolve('test/services/reddit/reddit_post_example.json').toFilePath();
  return jsonDecode(File(fixturePath).readAsStringSync()) as List<dynamic>;
}

void main() {
  group('RedditModels', () {
    test('parses real-style reddit listing JSON fixture', () {
      final responsePayload = _loadFixturePayload();

      final post = RedditPost.fromJson(
        Map<String, dynamic>.from(responsePayload[0] as Map),
        Map<String, dynamic>.from(responsePayload[1] as Map),
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
  });

  group('RedditScraper', () {
    test('uses public endpoint and expected query params/headers for reddit.com URLs', () async {
      final responsePayload = _loadFixturePayload();

      final dio = Dio();
      RequestOptions? capturedRequest;

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            capturedRequest = options;
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                data: responsePayload,
                statusCode: 200,
              ),
            );
          },
        ),
      );

      final auth = _FakeRedditAuthService(tokenValid: true, token: 'token_should_not_be_used');
      final scraper = RedditScraper(dio, auth);

      final post = await scraper.fetchPost('https://www.reddit.com/r/dartlang/comments/abc123/my_test_post/');

      expect(post.id, 'abc123');
      expect(post.comments.length, 2);

      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.uri.path, '/comments/abc123.json');
      expect(capturedRequest!.queryParameters, {
        'sort': 'top',
        'limit': 100,
        'depth': 3,
        'raw_json': 1,
      });
      expect(capturedRequest!.headers['User-Agent'], AppConstants.redditUserAgent);
      expect(capturedRequest!.headers.containsKey('Authorization'), isFalse);
    });

    test('supports reddit URL variants (www, old, bare, m, np, and redd.it)', () async {
      final responsePayload = _loadFixturePayload();
      final variants = <String>[
        'https://www.reddit.com/r/dartlang/comments/abc123/my_test_post/',
        'https://reddit.com/r/dartlang/comments/abc123/my_test_post/',
        'https://old.reddit.com/r/dartlang/comments/abc123/my_test_post/',
        'https://m.reddit.com/r/dartlang/comments/abc123/my_test_post/',
        'https://np.reddit.com/r/dartlang/comments/abc123/my_test_post/',
        'https://redd.it/abc123',
      ];

      for (final url in variants) {
        final dio = Dio();
        RequestOptions? capturedRequest;

        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              capturedRequest = options;
              handler.resolve(
                Response<dynamic>(
                  requestOptions: options,
                  data: responsePayload,
                  statusCode: 200,
                ),
              );
            },
          ),
        );

        final scraper = RedditScraper(
          dio,
          _FakeRedditAuthService(tokenValid: false, token: 'unused'),
        );

        final post = await scraper.fetchPost(url);

        expect(post.id, 'abc123', reason: 'Failed URL: $url');
        expect(capturedRequest, isNotNull, reason: 'No request captured for: $url');
        expect(capturedRequest!.uri.path, '/comments/abc123.json', reason: 'Wrong endpoint for: $url');
      }
    });

    test('throws FormatException for reddit variant roots without post id', () {
      final dio = Dio();
      final scraper = RedditScraper(
        dio,
        _FakeRedditAuthService(tokenValid: false, token: 'unused'),
      );

      final invalidUrls = <String>[
        'https://www.reddit.com',
        'https://reddit.com',
        'https://old.reddit.com',
        'https://m.reddit.com',
        'https://np.reddit.com',
        'https://redd.it',
      ];

      for (final url in invalidUrls) {
        expectLater(scraper.fetchPost(url), throwsA(isA<FormatException>()));
      }
    });
  });
}
