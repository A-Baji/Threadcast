import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/reddit/reddit_auth_service.dart';
import '../../core/providers.dart';

final onboardingProvider = StateNotifierProvider<OnboardingNotifier, OnboardingState>(
  (ref) => OnboardingNotifier(ref.watch(redditAuthServiceProvider)),
);

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final RedditAuthService _auth;

  OnboardingNotifier(this._auth) : super(const OnboardingState.initial());

  Future<void> connectReddit() async {
    state = const OnboardingState.loading();
    try {
      await _auth.authenticate();
      state = const OnboardingState.success();
    } catch (e) {
      state = OnboardingState.error(e.toString());
    }
  }
}

class OnboardingState {
  const OnboardingState._(this.status, this.error);

  const OnboardingState.initial() : this._(OnboardingStatus.initial, null);
  const OnboardingState.loading() : this._(OnboardingStatus.loading, null);
  const OnboardingState.success() : this._(OnboardingStatus.success, null);
  const OnboardingState.error(String error) : this._(OnboardingStatus.error, error);

  final OnboardingStatus status;
  final String? error;
}

enum OnboardingStatus { initial, loading, success, error }
