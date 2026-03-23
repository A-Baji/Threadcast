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
    GoRoute(
      path: '/onboarding',
      builder: (_, __) => const OnboardingScreen(),
    ),

    // ShellRoute wraps the two main screens (Create and Library) with a
    // persistent bottom navigation bar. The shell widget is rebuilt on every
    // navigation but the bottom bar stays visible across both screens.
    ShellRoute(
      builder: (context, state, child) => _AppShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const CreateScreen(),
        ),
        GoRoute(
          path: '/library',
          builder: (_, __) => const LibraryScreen(),
        ),
      ],
    ),

    // The player sits outside the shell so it gets the full screen
    // without the bottom nav bar showing underneath it.
    GoRoute(
      path: '/player/:episodeId',
      builder: (_, state) => PlayerScreen(
        episodeId: state.pathParameters['episodeId']!,
      ),
    ),
  ],
  redirect: (context, state) async {
    if (AppConstants.redditClientId.isEmpty) return null;
    // TODO: check for stored Reddit token here (Issue #15)
    return null;
  },
);

/// Shell widget that provides the persistent bottom navigation bar.
/// [child] is the currently active screen (Create or Library).
class _AppShell extends StatelessWidget {
  final Widget child;

  const _AppShell({required this.child});

  @override
  Widget build(BuildContext context) {
    // Determine which tab is active based on the current route location.
    final location = GoRouterState.of(context).uri.path;
    final selectedIndex = location.startsWith('/library') ? 1 : 0;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/');
            case 1:
              context.go('/library');
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Create',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_music_outlined),
            selectedIcon: Icon(Icons.library_music),
            label: 'Library',
          ),
        ],
      ),
    );
  }
}
