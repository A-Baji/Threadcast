import 'package:flutter_riverpod/flutter_riverpod.dart';

final libraryProvider = StateNotifierProvider<LibraryNotifier, AsyncValue<List>>(
  (ref) => LibraryNotifier(),
);

class LibraryNotifier extends StateNotifier<AsyncValue<List>> {
  LibraryNotifier() : super(const AsyncValue.data([]));

  Future<void> reload() async {
    state = const AsyncValue.data([]);
  }

  Future<void> deleteEpisode(String episodeId) async {
    // TODO: Implement persistence and deletion once Isar codegen is available.
  }
}
