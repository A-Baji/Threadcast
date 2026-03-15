import 'package:isar/isar.dart';

part 'episode.g.dart';

@collection
class Episode {
  Id id = Isar.autoIncrement;

  late String episodeId; // UUID
  late String title;
  late String subreddit;
  late List<String> sourceUrls; // Original Reddit URLs (ordered)
  late String tone;

  late DateTime createdAt;
  late int durationSeconds;

  // File paths (relative to app documents dir)
  String? audioWavPath;
  String? audioMp3Path;
  String? transcriptJsonPath; // Full transcript JSON for transcript view

  // Generation state
  @enumerated
  late EpisodeStatus status; // pending | generating | complete | failed

  String? errorMessage;
}

enum EpisodeStatus { pending, generating, complete, failed }
