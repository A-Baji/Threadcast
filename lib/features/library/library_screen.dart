import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'library_provider.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final episodesAsync = ref.watch(libraryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Library')),
      body: episodesAsync.when(
        data: (episodes) => ListView.builder(
          itemCount: episodes.length,
          itemBuilder: (context, index) {
            final episode = episodes[index];
            return ListTile(
              title: Text(episode.title),
              subtitle: Text(episode.subreddit),
              onTap: () => Navigator.pushNamed(context, '/player/${episode.episodeId}'),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
