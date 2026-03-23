import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/extensions.dart';
import '../../core/providers.dart';
import '../../models/episode.dart';

final libraryProvider = StateNotifierProvider<LibraryNotifier, AsyncValue<List<Episode>>>(
  (ref) => LibraryNotifier(ref),
);

class LibraryNotifier extends StateNotifier<AsyncValue<List<Episode>>> {
  final Ref _ref;

  LibraryNotifier(this._ref) : super(const AsyncValue.loading()) {
    reload();
  }

  Future<void> reload() async {
    state = const AsyncValue.loading();
    try {
      final episodes = await _ref.read(databaseProvider).completedEpisodes();
      state = AsyncValue.data(episodes);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteEpisode(int rowId, {String? wavPath, String? mp3Path, String? transcriptPath}) async {
    try {
      if (wavPath != null) await File(wavPath).deleteIfExists();
      if (mp3Path != null) await File(mp3Path).deleteIfExists();
      if (transcriptPath != null) await File(transcriptPath).deleteIfExists();
      await _ref.read(databaseProvider).deleteEpisodeById(rowId);
      await reload();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
