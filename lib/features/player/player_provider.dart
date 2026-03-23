import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../models/episode.dart'; // AppDatabase passed in as parameter -- no provider import needed

final playerProvider = StateNotifierProvider<PlayerNotifier, PlayerState>(
  (ref) => PlayerNotifier(),
);

class PlayerNotifier extends StateNotifier<PlayerState> {
  final AudioPlayer _player = AudioPlayer();

  PlayerNotifier() : super(const PlayerState.idle());

  Future<void> loadEpisodeById(String episodeId, AppDatabase db) async {
    try {
      final ep = await db.episodeById(episodeId);
      if (ep?.audioWavPath == null) return;
      await _player.setFilePath(ep!.audioWavPath!);
      state = PlayerState.ready(episode: ep, duration: _player.duration ?? Duration.zero);
    } catch (_) {}
  }

  Future<void> play() async {
    await WakelockPlus.enable(); // keep screen on during playback
    return _player.play();
  }

  Future<void> pause() async {
    await WakelockPlus.disable();
    return _player.pause();
  }

  Future<void> seekTo(Duration p) => _player.seek(p);
  Future<void> skipForward() => _player.seek(_player.position + const Duration(seconds: 10));
  Future<void> skipBackward() => _player.seek(_player.position - const Duration(seconds: 10));

  Stream<Duration> get positionStream => _player.positionStream;
  Duration get position => _player.position;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  // Expose whether audio is currently playing as a stream
  Stream<bool> get playingStream => _player.playingStream;

// Change playback speed (0.75, 1.0, 1.25, 1.5)
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);
}

class PlayerState {
  const PlayerState._({required this.status, this.episode, this.duration, this.isPlaying = false});

  const PlayerState.idle() : this._(status: PlayerStatus.idle);
  const PlayerState.ready({required Episode episode, required Duration duration, bool isPlaying = false})
      : this._(status: PlayerStatus.ready, episode: episode, duration: duration, isPlaying: isPlaying);

  final PlayerStatus status;
  final Episode? episode;
  final Duration? duration;
  final bool isPlaying;

  PlayerState copyWith({bool? isPlaying}) => PlayerState._(
        status: status,
        episode: episode,
        duration: duration,
        isPlaying: isPlaying ?? this.isPlaying,
      );
}

enum PlayerStatus { idle, ready }
