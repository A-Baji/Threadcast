import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'create_provider.dart';

class CreateScreen extends ConsumerWidget {
  const CreateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Create Podcast')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Reddit URL'),
              onSubmitted: (url) {
                if (url.isNotEmpty) {
                  ref.read(createProvider.notifier).generatePodcast([url]);
                }
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: state.status == CreateStatus.idle
                  ? () => ref.read(createProvider.notifier).generatePodcast(['https://www.reddit.com/r/AITAH/comments/example/'])
                  : null,
              child: const Text('Generate (Mock)'),
            ),
            if (state.status == CreateStatus.synthesizing)
              LinearProgressIndicator(value: state.progress),
            Text('Status: ${state.status}'),
          ],
        ),
      ),
    );
  }
}