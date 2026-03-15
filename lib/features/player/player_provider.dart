import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../models/episode.dart';

final playerProvider = StateNotifierProvider<PlayerNotifier, PlayerState>(
  (ref) => PlayerNotifier(),
);

class PlayerNotifier extends StateNotifier<PlayerState> {
  late AudioPlayer _player;

  PlayerNotifier() : super(const PlayerState.idle()) {
    _player = AudioPlayer();
  }

  Future<void> loadEpisode(Episode episode) async {
    await _player.setFilePath(episode.audioWavPath!);
    state = PlayerState.ready(episode: episode, duration: _player.duration!);
  }

  Future<void> play() async {
    await _player.play();
    state = state.copyWith(isPlaying: true);
  }

  Future<void> pause() async {
    await _player.pause();
    state = state.copyWith(isPlaying: false);
  }

  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
  }

  Future<void> skipForward() async {
    await _player.seek(_player.position + const Duration(seconds: 15));
  }

  Future<void> skipBackward() async {
    await _player.seek(_player.position - const Duration(seconds: 15));
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}

class PlayerState {
  const PlayerState({
    required this.status,
    this.episode,
    this.duration,
    this.isPlaying = false,
  });

  const PlayerState.idle() : this(status: PlayerStatus.idle);
  const PlayerState.ready({required Episode episode, required Duration duration, bool isPlaying = false})
      : this(status: PlayerStatus.ready, episode: episode, duration: duration, isPlaying: isPlaying);

  final PlayerStatus status;
  final Episode? episode;
  final Duration? duration;
  final bool isPlaying;

  PlayerState copyWith({
    PlayerStatus? status,
    Episode? episode,
    Duration? duration,
    bool? isPlaying,
  }) {
    return PlayerState(
      status: status ?? this.status,
      episode: episode ?? this.episode,
      duration: duration ?? this.duration,
      isPlaying: isPlaying ?? this.isPlaying,
    );
  }
}

enum PlayerStatus { idle, ready }
