import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'onboarding_provider.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Welcome to Threadcast'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: state.status == OnboardingStatus.initial
                  ? () => ref.read(onboardingProvider.notifier).connectReddit()
                  : null,
              child: const Text('Connect Reddit'),
            ),
            if (state.status == OnboardingStatus.loading) const CircularProgressIndicator(),
            if (state.error != null) Text('Error: ${state.error}'),
          ],
        ),
      ),
    );
  }
}
