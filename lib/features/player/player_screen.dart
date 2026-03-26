import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:threadcast/features/player/widgets/transcript_view.dart';
import 'package:threadcast/services/tts/export_service.dart';

import '../../core/providers.dart';
import 'player_provider.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  final String episodeId;

  const PlayerScreen({super.key, required this.episodeId});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  bool _isSharing = false;
  final _exportService = ExportService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final db = ref.read(databaseProvider);
      ref.read(playerProvider.notifier).loadEpisodeById(widget.episodeId, db);
    });
  }

  Future<void> _share(episode) async {
    setState(() => _isSharing = true);
    try {
      await _exportService.shareEpisode(episode);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playerProvider);
    final notifier = ref.read(playerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(state.episode?.title ?? 'Player'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            notifier.pause();
            context.pop();
          },
        ),
      ),
      body: state.status == PlayerStatus.idle
          ? const Center(child: CircularProgressIndicator())
          : _buildPlayerBody(context, state, notifier),
    );
  }

  Widget _buildPlayerBody(BuildContext context, PlayerState state, PlayerNotifier notifier) {
    final episode = state.episode!;
    final total = state.duration ?? Duration.zero;
    final transcriptPath = episode.transcriptJsonPath;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(episode.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),

          // Subreddit chip + Share button on the same row
          Row(
            children: [
              Chip(label: Text('r/${episode.subreddit}')),
              const Spacer(),
              _isSharing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : TextButton.icon(
                      onPressed: () => _share(episode),
                      icon: const Icon(Icons.ios_share, size: 18),
                      label: const Text(''),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
            ],
          ),

          const SizedBox(height: 16),

          // Seek bar
          StreamBuilder<Duration>(
            stream: notifier.positionStream,
            builder: (context, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              final totalMs = total.inMilliseconds.toDouble();
              final posMs = position.inMilliseconds.toDouble().clamp(0.0, totalMs);

              return Column(
                children: [
                  Slider(
                    value: totalMs > 0 ? posMs / totalMs : 0.0,
                    onChanged: totalMs > 0
                        ? (value) {
                            notifier.seekTo(Duration(milliseconds: (value * totalMs).round()));
                          }
                        : null,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(position)),
                      Text(_formatDuration(total)),
                    ],
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 16),

          // Transport controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                iconSize: 36,
                icon: const Icon(Icons.replay_10),
                onPressed: notifier.skipBackward,
                tooltip: 'Back 10 seconds',
              ),
              const SizedBox(width: 16),
              StreamBuilder<bool>(
                stream: notifier.playingStream,
                builder: (context, snap) {
                  final isPlaying = snap.data ?? false;
                  return IconButton(
                    iconSize: 56,
                    icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled),
                    onPressed: isPlaying ? notifier.pause : notifier.play,
                  );
                },
              ),
              const SizedBox(width: 16),
              IconButton(
                iconSize: 36,
                icon: const Icon(Icons.forward_10),
                onPressed: notifier.skipForward,
                tooltip: 'Forward 10 seconds',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Speed selector
          _SpeedSelector(onSpeedChanged: notifier.setSpeed),

          const SizedBox(height: 16),
          const Divider(),

          Expanded(
            child: transcriptPath == null
                ? const Center(child: Text('No transcript available'))
                : TranscriptView(
                    transcriptJsonPath: transcriptPath,
                    positionStream: notifier.positionStream,
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _SpeedSelector extends StatefulWidget {
  final ValueChanged<double> onSpeedChanged;

  const _SpeedSelector({required this.onSpeedChanged});

  @override
  State<_SpeedSelector> createState() => _SpeedSelectorState();
}

class _SpeedSelectorState extends State<_SpeedSelector> {
  double _speed = 1.0;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Speed:'),
        const SizedBox(width: 8),
        for (final speed in [0.75, 1.0, 1.25, 1.5])
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text('$speed×'),
              selected: _speed == speed,
              onSelected: (_) {
                setState(() => _speed = speed);
                widget.onSpeedChanged(speed);
              },
            ),
          ),
      ],
    );
  }
}
