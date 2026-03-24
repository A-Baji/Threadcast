import 'dart:io';

import 'package:share_plus/share_plus.dart';
import 'package:threadcast/models/episode.dart';

class ExportService {
  /// Opens the system share sheet with the episode's MP3 attached.
  ///
  /// The MP3 is encoded automatically at the end of generation and stored in
  /// [Episode.audioMp3Path], so this should never need to encode on-the-fly.
  /// The WAV fallback exists purely as a safety net for episodes generated
  /// before auto-encoding was introduced.
  Future<void> shareEpisode(Episode episode) async {
    final sharePath = _resolveSharePath(episode);
    if (sharePath == null) {
      throw Exception('No audio file found for this episode.');
    }

    final file = File(sharePath);
    if (!await file.exists()) {
      throw Exception('Audio file is missing from device storage.');
    }

    final isMp3 = sharePath.endsWith('.mp3');
    await SharePlus.instance.share(ShareParams(
      files: [XFile(sharePath, mimeType: isMp3 ? 'audio/mpeg' : 'audio/wav')],
      subject: episode.title,
    ));
  }

  /// Returns the best available audio path for sharing.
  /// Prefers MP3; falls back to WAV if MP3 hasn't been written yet.
  String? _resolveSharePath(Episode episode) {
    if (episode.audioMp3Path != null) return episode.audioMp3Path;
    if (episode.audioWavPath != null) return episode.audioWavPath;
    return null;
  }
}
