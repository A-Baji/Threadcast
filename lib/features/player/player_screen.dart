import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'player_provider.dart';

class PlayerScreen extends ConsumerWidget {
  final String episodeId;

  const PlayerScreen({super.key, required this.episodeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Player')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Playing episode: $episodeId'),
            if (state.status == PlayerStatus.ready) ...[
              Text('Duration: ${state.duration}'),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => ref.read(playerProvider.notifier).skipBackward(),
                    icon: const Icon(Icons.replay_10),
                  ),
                  IconButton(
                    onPressed: state.isPlaying
                        ? () => ref.read(playerProvider.notifier).pause()
                        : () => ref.read(playerProvider.notifier).play(),
                    icon: Icon(state.isPlaying ? Icons.pause : Icons.play_arrow),
                  ),
                  IconButton(
                    onPressed: () => ref.read(playerProvider.notifier).skipForward(),
                    icon: const Icon(Icons.forward_10),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
