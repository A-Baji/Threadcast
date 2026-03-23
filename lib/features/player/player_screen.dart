import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:threadcast/features/player/widgets/transcript_view.dart';

import '../../core/providers.dart';
import 'player_provider.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  final String episodeId;

  const PlayerScreen({super.key, required this.episodeId});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  @override
  void initState() {
    super.initState();
    // Load the episode as soon as the screen opens.
    // addPostFrameCallback ensures the first build is complete before we
    // trigger state changes.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final db = ref.read(databaseProvider);
      ref.read(playerProvider.notifier).loadEpisodeById(widget.episodeId, db);
    });
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
            // Stop playback when navigating away
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
          // Episode title and subreddit badge
          Text(episode.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Chip(label: Text('r/${episode.subreddit}')),
          const SizedBox(height: 24),

          // Seek bar — updates in real time using positionStream
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
                  // Current time / total time display
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

          // Transport controls row
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
              // Play/pause button — use StreamBuilder so it reflects actual player state
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

          // Playback speed selector
          _SpeedSelector(
            onSpeedChanged: (speed) {
              notifier.setSpeed(speed);
            },
          ),
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
