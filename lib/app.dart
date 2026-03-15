import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/constants.dart';
import 'features/create/create_screen.dart';
import 'features/library/library_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/player/player_screen.dart';

class ThreadcastApp extends StatelessWidget {
  const ThreadcastApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp.router(
        title: 'Threadcast',
        routerConfig: _router,
      ),
    );
  }
}

final _router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, __) => const CreateScreen()),
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
    GoRoute(path: '/library', builder: (_, __) => const LibraryScreen()),
    GoRoute(
      path: '/player/:episodeId',
      builder: (_, state) => PlayerScreen(
        episodeId: state.pathParameters['episodeId']!,
      ),
    ),
  ],
  redirect: (context, state) async {
    // In development mode (no client ID configured), skip onboarding entirely
    if (AppConstants.redditClientId.isEmpty) {
      return null;
    }

    // Production mode: check if user has valid Reddit token
    // TODO: Implement token check when RedditAuthService is fully implemented
    // For now, assume no token in production mode
    if (state.matchedLocation != '/onboarding') {
      return '/onboarding';
    }
    return null;
  },
);
