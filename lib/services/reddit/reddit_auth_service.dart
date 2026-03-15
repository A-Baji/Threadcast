/// Stubbed Reddit auth service used for development.
/// Replace with real OAuth+PKCE logic when building for production.
class RedditAuthService {
  RedditAuthService();

  bool get hasValidToken => false; // Stub

  Future<String> getAccessToken() async {
    // Stub
    return 'mock_token';
  }

  Future<void> authenticate() async {
    // Stub OAuth flow
  }

}
