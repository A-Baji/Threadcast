import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'episode.g.dart';

/// Episode status stored as int: 0=pending 1=generating 2=complete 3=failed
enum EpisodeStatus { pending, generating, complete, failed }

/// Drift table -- run `dart run build_runner build` after any schema change.
class Episodes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get episodeId => text()();
  TextColumn get title => text()();
  TextColumn get subreddit => text()();

  /// Stored as JSON string. Use encodeUrls/decodeUrls helpers.
  TextColumn get sourceUrlsJson => text()();
  TextColumn get tone => text()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get durationSeconds => integer()();
  TextColumn get audioWavPath => text().nullable()();
  TextColumn get audioMp3Path => text().nullable()();
  TextColumn get transcriptJsonPath => text().nullable()();
  IntColumn get status => integer().withDefault(const Constant(0))();
  TextColumn get errorMessage => text().nullable()();
}

@DriftDatabase(tables: [Episodes])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // Helpers -----------------------------------------------------------------
  static String encodeUrls(List<String> urls) => jsonEncode(urls);
  static List<String> decodeUrls(String json) => (jsonDecode(json) as List).cast<String>();
  static int encodeStatus(EpisodeStatus s) => s.index;
  static EpisodeStatus decodeStatus(int i) => EpisodeStatus.values[i];

  // Queries -----------------------------------------------------------------

  /// All completed episodes, newest first.
  Future<List<Episode>> completedEpisodes() => (select(episodes)
        ..where((e) => e.status.equals(encodeStatus(EpisodeStatus.complete)))
        ..orderBy([(e) => OrderingTerm.desc(e.createdAt)]))
      .get();

  /// Find one episode by its UUID string.
  Future<Episode?> episodeById(String id) => (select(episodes)..where((e) => e.episodeId.equals(id))).getSingleOrNull();

  /// Insert or update (upsert) an episode row.
  Future<void> upsertEpisode(EpisodesCompanion companion) => into(episodes).insertOnConflictUpdate(companion);

  /// Update individual nullable fields on an existing row.
  Future<void> updateEpisodeFields(
    int rowId, {
    String? audioMp3Path,
    String? transcriptJsonPath,
    int? durationSeconds,
    int? status,
    String? errorMessage,
  }) =>
      (update(episodes)..where((e) => e.id.equals(rowId))).write(EpisodesCompanion(
        audioMp3Path: audioMp3Path != null ? Value(audioMp3Path) : const Value.absent(),
        transcriptJsonPath: transcriptJsonPath != null ? Value(transcriptJsonPath) : const Value.absent(),
        durationSeconds: durationSeconds != null ? Value(durationSeconds) : const Value.absent(),
        status: status != null ? Value(status) : const Value.absent(),
        errorMessage: errorMessage != null ? Value(errorMessage) : const Value.absent(),
      ));

  /// Delete an episode row by its auto-increment integer id.
  Future<void> deleteEpisodeById(int rowId) => (delete(episodes)..where((e) => e.id.equals(rowId))).go();
}

QueryExecutor _openConnection() => driftDatabase(name: 'threadcast');
