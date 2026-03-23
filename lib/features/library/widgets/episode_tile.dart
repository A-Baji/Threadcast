import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../models/episode.dart';

/// A list tile displaying episode metadata.
/// Used as the visible child inside a Dismissible in LibraryScreen.
class EpisodeTile extends StatelessWidget {
  final Episode episode;

  const EpisodeTile({super.key, required this.episode});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        episode.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        'r/${episode.subreddit}  •  '
        '${episode.durationSeconds ~/ 60}m '
        '${(episode.durationSeconds % 60).toString().padLeft(2, '0')}s  •  '
        '${_formatDate(episode.createdAt)}',
        style: TextStyle(
          color: Theme.of(context).colorScheme.outline,
          fontSize: 13,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push('/player/${episode.episodeId}'),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }
}
