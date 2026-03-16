// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'episode.dart';

// ignore_for_file: type=lint
class $EpisodesTable extends Episodes with TableInfo<$EpisodesTable, Episode> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EpisodesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>('id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _episodeIdMeta = const VerificationMeta('episodeId');
  @override
  late final GeneratedColumn<String> episodeId =
      GeneratedColumn<String>('episode_id', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title =
      GeneratedColumn<String>('title', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _subredditMeta = const VerificationMeta('subreddit');
  @override
  late final GeneratedColumn<String> subreddit =
      GeneratedColumn<String>('subreddit', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceUrlsJsonMeta = const VerificationMeta('sourceUrlsJson');
  @override
  late final GeneratedColumn<String> sourceUrlsJson = GeneratedColumn<String>('source_urls_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _toneMeta = const VerificationMeta('tone');
  @override
  late final GeneratedColumn<String> tone =
      GeneratedColumn<String>('tone', aliasedName, false, type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>('created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta('durationSeconds');
  @override
  late final GeneratedColumn<int> durationSeconds =
      GeneratedColumn<int>('duration_seconds', aliasedName, false, type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _audioWavPathMeta = const VerificationMeta('audioWavPath');
  @override
  late final GeneratedColumn<String> audioWavPath = GeneratedColumn<String>('audio_wav_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _audioMp3PathMeta = const VerificationMeta('audioMp3Path');
  @override
  late final GeneratedColumn<String> audioMp3Path = GeneratedColumn<String>('audio_mp3_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _transcriptJsonPathMeta = const VerificationMeta('transcriptJsonPath');
  @override
  late final GeneratedColumn<String> transcriptJsonPath = GeneratedColumn<String>(
      'transcript_json_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<int> status = GeneratedColumn<int>('status', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false, defaultValue: const Constant(0));
  static const VerificationMeta _errorMessageMeta = const VerificationMeta('errorMessage');
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>('error_message', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        episodeId,
        title,
        subreddit,
        sourceUrlsJson,
        tone,
        createdAt,
        durationSeconds,
        audioWavPath,
        audioMp3Path,
        transcriptJsonPath,
        status,
        errorMessage
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'episodes';
  @override
  VerificationContext validateIntegrity(Insertable<Episode> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('episode_id')) {
      context.handle(_episodeIdMeta, episodeId.isAcceptableOrUnknown(data['episode_id']!, _episodeIdMeta));
    } else if (isInserting) {
      context.missing(_episodeIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(_titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('subreddit')) {
      context.handle(_subredditMeta, subreddit.isAcceptableOrUnknown(data['subreddit']!, _subredditMeta));
    } else if (isInserting) {
      context.missing(_subredditMeta);
    }
    if (data.containsKey('source_urls_json')) {
      context.handle(
          _sourceUrlsJsonMeta, sourceUrlsJson.isAcceptableOrUnknown(data['source_urls_json']!, _sourceUrlsJsonMeta));
    } else if (isInserting) {
      context.missing(_sourceUrlsJsonMeta);
    }
    if (data.containsKey('tone')) {
      context.handle(_toneMeta, tone.isAcceptableOrUnknown(data['tone']!, _toneMeta));
    } else if (isInserting) {
      context.missing(_toneMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
          _durationSecondsMeta, durationSeconds.isAcceptableOrUnknown(data['duration_seconds']!, _durationSecondsMeta));
    } else if (isInserting) {
      context.missing(_durationSecondsMeta);
    }
    if (data.containsKey('audio_wav_path')) {
      context.handle(_audioWavPathMeta, audioWavPath.isAcceptableOrUnknown(data['audio_wav_path']!, _audioWavPathMeta));
    }
    if (data.containsKey('audio_mp3_path')) {
      context.handle(_audioMp3PathMeta, audioMp3Path.isAcceptableOrUnknown(data['audio_mp3_path']!, _audioMp3PathMeta));
    }
    if (data.containsKey('transcript_json_path')) {
      context.handle(_transcriptJsonPathMeta,
          transcriptJsonPath.isAcceptableOrUnknown(data['transcript_json_path']!, _transcriptJsonPathMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta, status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('error_message')) {
      context.handle(_errorMessageMeta, errorMessage.isAcceptableOrUnknown(data['error_message']!, _errorMessageMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Episode map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Episode(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      episodeId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}episode_id'])!,
      title: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      subreddit: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}subreddit'])!,
      sourceUrlsJson:
          attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}source_urls_json'])!,
      tone: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}tone'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      durationSeconds: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}duration_seconds'])!,
      audioWavPath: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}audio_wav_path']),
      audioMp3Path: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}audio_mp3_path']),
      transcriptJsonPath:
          attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}transcript_json_path']),
      status: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}status'])!,
      errorMessage: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}error_message']),
    );
  }

  @override
  $EpisodesTable createAlias(String alias) {
    return $EpisodesTable(attachedDatabase, alias);
  }
}

class Episode extends DataClass implements Insertable<Episode> {
  final int id;
  final String episodeId;
  final String title;
  final String subreddit;

  /// Stored as JSON string. Use encodeUrls/decodeUrls helpers.
  final String sourceUrlsJson;
  final String tone;
  final DateTime createdAt;
  final int durationSeconds;
  final String? audioWavPath;
  final String? audioMp3Path;
  final String? transcriptJsonPath;
  final int status;
  final String? errorMessage;
  const Episode(
      {required this.id,
      required this.episodeId,
      required this.title,
      required this.subreddit,
      required this.sourceUrlsJson,
      required this.tone,
      required this.createdAt,
      required this.durationSeconds,
      this.audioWavPath,
      this.audioMp3Path,
      this.transcriptJsonPath,
      required this.status,
      this.errorMessage});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['episode_id'] = Variable<String>(episodeId);
    map['title'] = Variable<String>(title);
    map['subreddit'] = Variable<String>(subreddit);
    map['source_urls_json'] = Variable<String>(sourceUrlsJson);
    map['tone'] = Variable<String>(tone);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['duration_seconds'] = Variable<int>(durationSeconds);
    if (!nullToAbsent || audioWavPath != null) {
      map['audio_wav_path'] = Variable<String>(audioWavPath);
    }
    if (!nullToAbsent || audioMp3Path != null) {
      map['audio_mp3_path'] = Variable<String>(audioMp3Path);
    }
    if (!nullToAbsent || transcriptJsonPath != null) {
      map['transcript_json_path'] = Variable<String>(transcriptJsonPath);
    }
    map['status'] = Variable<int>(status);
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    return map;
  }

  EpisodesCompanion toCompanion(bool nullToAbsent) {
    return EpisodesCompanion(
      id: Value(id),
      episodeId: Value(episodeId),
      title: Value(title),
      subreddit: Value(subreddit),
      sourceUrlsJson: Value(sourceUrlsJson),
      tone: Value(tone),
      createdAt: Value(createdAt),
      durationSeconds: Value(durationSeconds),
      audioWavPath: audioWavPath == null && nullToAbsent ? const Value.absent() : Value(audioWavPath),
      audioMp3Path: audioMp3Path == null && nullToAbsent ? const Value.absent() : Value(audioMp3Path),
      transcriptJsonPath: transcriptJsonPath == null && nullToAbsent ? const Value.absent() : Value(transcriptJsonPath),
      status: Value(status),
      errorMessage: errorMessage == null && nullToAbsent ? const Value.absent() : Value(errorMessage),
    );
  }

  factory Episode.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Episode(
      id: serializer.fromJson<int>(json['id']),
      episodeId: serializer.fromJson<String>(json['episodeId']),
      title: serializer.fromJson<String>(json['title']),
      subreddit: serializer.fromJson<String>(json['subreddit']),
      sourceUrlsJson: serializer.fromJson<String>(json['sourceUrlsJson']),
      tone: serializer.fromJson<String>(json['tone']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      durationSeconds: serializer.fromJson<int>(json['durationSeconds']),
      audioWavPath: serializer.fromJson<String?>(json['audioWavPath']),
      audioMp3Path: serializer.fromJson<String?>(json['audioMp3Path']),
      transcriptJsonPath: serializer.fromJson<String?>(json['transcriptJsonPath']),
      status: serializer.fromJson<int>(json['status']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'episodeId': serializer.toJson<String>(episodeId),
      'title': serializer.toJson<String>(title),
      'subreddit': serializer.toJson<String>(subreddit),
      'sourceUrlsJson': serializer.toJson<String>(sourceUrlsJson),
      'tone': serializer.toJson<String>(tone),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'durationSeconds': serializer.toJson<int>(durationSeconds),
      'audioWavPath': serializer.toJson<String?>(audioWavPath),
      'audioMp3Path': serializer.toJson<String?>(audioMp3Path),
      'transcriptJsonPath': serializer.toJson<String?>(transcriptJsonPath),
      'status': serializer.toJson<int>(status),
      'errorMessage': serializer.toJson<String?>(errorMessage),
    };
  }

  Episode copyWith(
          {int? id,
          String? episodeId,
          String? title,
          String? subreddit,
          String? sourceUrlsJson,
          String? tone,
          DateTime? createdAt,
          int? durationSeconds,
          Value<String?> audioWavPath = const Value.absent(),
          Value<String?> audioMp3Path = const Value.absent(),
          Value<String?> transcriptJsonPath = const Value.absent(),
          int? status,
          Value<String?> errorMessage = const Value.absent()}) =>
      Episode(
        id: id ?? this.id,
        episodeId: episodeId ?? this.episodeId,
        title: title ?? this.title,
        subreddit: subreddit ?? this.subreddit,
        sourceUrlsJson: sourceUrlsJson ?? this.sourceUrlsJson,
        tone: tone ?? this.tone,
        createdAt: createdAt ?? this.createdAt,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        audioWavPath: audioWavPath.present ? audioWavPath.value : this.audioWavPath,
        audioMp3Path: audioMp3Path.present ? audioMp3Path.value : this.audioMp3Path,
        transcriptJsonPath: transcriptJsonPath.present ? transcriptJsonPath.value : this.transcriptJsonPath,
        status: status ?? this.status,
        errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
      );
  Episode copyWithCompanion(EpisodesCompanion data) {
    return Episode(
      id: data.id.present ? data.id.value : this.id,
      episodeId: data.episodeId.present ? data.episodeId.value : this.episodeId,
      title: data.title.present ? data.title.value : this.title,
      subreddit: data.subreddit.present ? data.subreddit.value : this.subreddit,
      sourceUrlsJson: data.sourceUrlsJson.present ? data.sourceUrlsJson.value : this.sourceUrlsJson,
      tone: data.tone.present ? data.tone.value : this.tone,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      durationSeconds: data.durationSeconds.present ? data.durationSeconds.value : this.durationSeconds,
      audioWavPath: data.audioWavPath.present ? data.audioWavPath.value : this.audioWavPath,
      audioMp3Path: data.audioMp3Path.present ? data.audioMp3Path.value : this.audioMp3Path,
      transcriptJsonPath: data.transcriptJsonPath.present ? data.transcriptJsonPath.value : this.transcriptJsonPath,
      status: data.status.present ? data.status.value : this.status,
      errorMessage: data.errorMessage.present ? data.errorMessage.value : this.errorMessage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Episode(')
          ..write('id: $id, ')
          ..write('episodeId: $episodeId, ')
          ..write('title: $title, ')
          ..write('subreddit: $subreddit, ')
          ..write('sourceUrlsJson: $sourceUrlsJson, ')
          ..write('tone: $tone, ')
          ..write('createdAt: $createdAt, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('audioWavPath: $audioWavPath, ')
          ..write('audioMp3Path: $audioMp3Path, ')
          ..write('transcriptJsonPath: $transcriptJsonPath, ')
          ..write('status: $status, ')
          ..write('errorMessage: $errorMessage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, episodeId, title, subreddit, sourceUrlsJson, tone, createdAt, durationSeconds,
      audioWavPath, audioMp3Path, transcriptJsonPath, status, errorMessage);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Episode &&
          other.id == this.id &&
          other.episodeId == this.episodeId &&
          other.title == this.title &&
          other.subreddit == this.subreddit &&
          other.sourceUrlsJson == this.sourceUrlsJson &&
          other.tone == this.tone &&
          other.createdAt == this.createdAt &&
          other.durationSeconds == this.durationSeconds &&
          other.audioWavPath == this.audioWavPath &&
          other.audioMp3Path == this.audioMp3Path &&
          other.transcriptJsonPath == this.transcriptJsonPath &&
          other.status == this.status &&
          other.errorMessage == this.errorMessage);
}

class EpisodesCompanion extends UpdateCompanion<Episode> {
  final Value<int> id;
  final Value<String> episodeId;
  final Value<String> title;
  final Value<String> subreddit;
  final Value<String> sourceUrlsJson;
  final Value<String> tone;
  final Value<DateTime> createdAt;
  final Value<int> durationSeconds;
  final Value<String?> audioWavPath;
  final Value<String?> audioMp3Path;
  final Value<String?> transcriptJsonPath;
  final Value<int> status;
  final Value<String?> errorMessage;
  const EpisodesCompanion({
    this.id = const Value.absent(),
    this.episodeId = const Value.absent(),
    this.title = const Value.absent(),
    this.subreddit = const Value.absent(),
    this.sourceUrlsJson = const Value.absent(),
    this.tone = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.audioWavPath = const Value.absent(),
    this.audioMp3Path = const Value.absent(),
    this.transcriptJsonPath = const Value.absent(),
    this.status = const Value.absent(),
    this.errorMessage = const Value.absent(),
  });
  EpisodesCompanion.insert({
    this.id = const Value.absent(),
    required String episodeId,
    required String title,
    required String subreddit,
    required String sourceUrlsJson,
    required String tone,
    required DateTime createdAt,
    required int durationSeconds,
    this.audioWavPath = const Value.absent(),
    this.audioMp3Path = const Value.absent(),
    this.transcriptJsonPath = const Value.absent(),
    this.status = const Value.absent(),
    this.errorMessage = const Value.absent(),
  })  : episodeId = Value(episodeId),
        title = Value(title),
        subreddit = Value(subreddit),
        sourceUrlsJson = Value(sourceUrlsJson),
        tone = Value(tone),
        createdAt = Value(createdAt),
        durationSeconds = Value(durationSeconds);
  static Insertable<Episode> custom({
    Expression<int>? id,
    Expression<String>? episodeId,
    Expression<String>? title,
    Expression<String>? subreddit,
    Expression<String>? sourceUrlsJson,
    Expression<String>? tone,
    Expression<DateTime>? createdAt,
    Expression<int>? durationSeconds,
    Expression<String>? audioWavPath,
    Expression<String>? audioMp3Path,
    Expression<String>? transcriptJsonPath,
    Expression<int>? status,
    Expression<String>? errorMessage,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (episodeId != null) 'episode_id': episodeId,
      if (title != null) 'title': title,
      if (subreddit != null) 'subreddit': subreddit,
      if (sourceUrlsJson != null) 'source_urls_json': sourceUrlsJson,
      if (tone != null) 'tone': tone,
      if (createdAt != null) 'created_at': createdAt,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (audioWavPath != null) 'audio_wav_path': audioWavPath,
      if (audioMp3Path != null) 'audio_mp3_path': audioMp3Path,
      if (transcriptJsonPath != null) 'transcript_json_path': transcriptJsonPath,
      if (status != null) 'status': status,
      if (errorMessage != null) 'error_message': errorMessage,
    });
  }

  EpisodesCompanion copyWith(
      {Value<int>? id,
      Value<String>? episodeId,
      Value<String>? title,
      Value<String>? subreddit,
      Value<String>? sourceUrlsJson,
      Value<String>? tone,
      Value<DateTime>? createdAt,
      Value<int>? durationSeconds,
      Value<String?>? audioWavPath,
      Value<String?>? audioMp3Path,
      Value<String?>? transcriptJsonPath,
      Value<int>? status,
      Value<String?>? errorMessage}) {
    return EpisodesCompanion(
      id: id ?? this.id,
      episodeId: episodeId ?? this.episodeId,
      title: title ?? this.title,
      subreddit: subreddit ?? this.subreddit,
      sourceUrlsJson: sourceUrlsJson ?? this.sourceUrlsJson,
      tone: tone ?? this.tone,
      createdAt: createdAt ?? this.createdAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      audioWavPath: audioWavPath ?? this.audioWavPath,
      audioMp3Path: audioMp3Path ?? this.audioMp3Path,
      transcriptJsonPath: transcriptJsonPath ?? this.transcriptJsonPath,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (episodeId.present) {
      map['episode_id'] = Variable<String>(episodeId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (subreddit.present) {
      map['subreddit'] = Variable<String>(subreddit.value);
    }
    if (sourceUrlsJson.present) {
      map['source_urls_json'] = Variable<String>(sourceUrlsJson.value);
    }
    if (tone.present) {
      map['tone'] = Variable<String>(tone.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (audioWavPath.present) {
      map['audio_wav_path'] = Variable<String>(audioWavPath.value);
    }
    if (audioMp3Path.present) {
      map['audio_mp3_path'] = Variable<String>(audioMp3Path.value);
    }
    if (transcriptJsonPath.present) {
      map['transcript_json_path'] = Variable<String>(transcriptJsonPath.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(status.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EpisodesCompanion(')
          ..write('id: $id, ')
          ..write('episodeId: $episodeId, ')
          ..write('title: $title, ')
          ..write('subreddit: $subreddit, ')
          ..write('sourceUrlsJson: $sourceUrlsJson, ')
          ..write('tone: $tone, ')
          ..write('createdAt: $createdAt, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('audioWavPath: $audioWavPath, ')
          ..write('audioMp3Path: $audioMp3Path, ')
          ..write('transcriptJsonPath: $transcriptJsonPath, ')
          ..write('status: $status, ')
          ..write('errorMessage: $errorMessage')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $EpisodesTable episodes = $EpisodesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [episodes];
}

typedef $$EpisodesTableCreateCompanionBuilder = EpisodesCompanion Function({
  Value<int> id,
  required String episodeId,
  required String title,
  required String subreddit,
  required String sourceUrlsJson,
  required String tone,
  required DateTime createdAt,
  required int durationSeconds,
  Value<String?> audioWavPath,
  Value<String?> audioMp3Path,
  Value<String?> transcriptJsonPath,
  Value<int> status,
  Value<String?> errorMessage,
});
typedef $$EpisodesTableUpdateCompanionBuilder = EpisodesCompanion Function({
  Value<int> id,
  Value<String> episodeId,
  Value<String> title,
  Value<String> subreddit,
  Value<String> sourceUrlsJson,
  Value<String> tone,
  Value<DateTime> createdAt,
  Value<int> durationSeconds,
  Value<String?> audioWavPath,
  Value<String?> audioMp3Path,
  Value<String?> transcriptJsonPath,
  Value<int> status,
  Value<String?> errorMessage,
});

class $$EpisodesTableFilterComposer extends Composer<_$AppDatabase, $EpisodesTable> {
  $$EpisodesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get episodeId =>
      $composableBuilder(column: $table.episodeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get subreddit =>
      $composableBuilder(column: $table.subreddit, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceUrlsJson =>
      $composableBuilder(column: $table.sourceUrlsJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tone => $composableBuilder(column: $table.tone, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationSeconds =>
      $composableBuilder(column: $table.durationSeconds, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get audioWavPath =>
      $composableBuilder(column: $table.audioWavPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get audioMp3Path =>
      $composableBuilder(column: $table.audioMp3Path, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get transcriptJsonPath =>
      $composableBuilder(column: $table.transcriptJsonPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get errorMessage =>
      $composableBuilder(column: $table.errorMessage, builder: (column) => ColumnFilters(column));
}

class $$EpisodesTableOrderingComposer extends Composer<_$AppDatabase, $EpisodesTable> {
  $$EpisodesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get episodeId =>
      $composableBuilder(column: $table.episodeId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get subreddit =>
      $composableBuilder(column: $table.subreddit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceUrlsJson =>
      $composableBuilder(column: $table.sourceUrlsJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tone =>
      $composableBuilder(column: $table.tone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationSeconds =>
      $composableBuilder(column: $table.durationSeconds, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get audioWavPath =>
      $composableBuilder(column: $table.audioWavPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get audioMp3Path =>
      $composableBuilder(column: $table.audioMp3Path, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get transcriptJsonPath =>
      $composableBuilder(column: $table.transcriptJsonPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get errorMessage =>
      $composableBuilder(column: $table.errorMessage, builder: (column) => ColumnOrderings(column));
}

class $$EpisodesTableAnnotationComposer extends Composer<_$AppDatabase, $EpisodesTable> {
  $$EpisodesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get episodeId => $composableBuilder(column: $table.episodeId, builder: (column) => column);

  GeneratedColumn<String> get title => $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get subreddit => $composableBuilder(column: $table.subreddit, builder: (column) => column);

  GeneratedColumn<String> get sourceUrlsJson =>
      $composableBuilder(column: $table.sourceUrlsJson, builder: (column) => column);

  GeneratedColumn<String> get tone => $composableBuilder(column: $table.tone, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds =>
      $composableBuilder(column: $table.durationSeconds, builder: (column) => column);

  GeneratedColumn<String> get audioWavPath =>
      $composableBuilder(column: $table.audioWavPath, builder: (column) => column);

  GeneratedColumn<String> get audioMp3Path =>
      $composableBuilder(column: $table.audioMp3Path, builder: (column) => column);

  GeneratedColumn<String> get transcriptJsonPath =>
      $composableBuilder(column: $table.transcriptJsonPath, builder: (column) => column);

  GeneratedColumn<int> get status => $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get errorMessage =>
      $composableBuilder(column: $table.errorMessage, builder: (column) => column);
}

class $$EpisodesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $EpisodesTable,
    Episode,
    $$EpisodesTableFilterComposer,
    $$EpisodesTableOrderingComposer,
    $$EpisodesTableAnnotationComposer,
    $$EpisodesTableCreateCompanionBuilder,
    $$EpisodesTableUpdateCompanionBuilder,
    (Episode, BaseReferences<_$AppDatabase, $EpisodesTable, Episode>),
    Episode,
    PrefetchHooks Function()> {
  $$EpisodesTableTableManager(_$AppDatabase db, $EpisodesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$EpisodesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$EpisodesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$EpisodesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> episodeId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> subreddit = const Value.absent(),
            Value<String> sourceUrlsJson = const Value.absent(),
            Value<String> tone = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> durationSeconds = const Value.absent(),
            Value<String?> audioWavPath = const Value.absent(),
            Value<String?> audioMp3Path = const Value.absent(),
            Value<String?> transcriptJsonPath = const Value.absent(),
            Value<int> status = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
          }) =>
              EpisodesCompanion(
            id: id,
            episodeId: episodeId,
            title: title,
            subreddit: subreddit,
            sourceUrlsJson: sourceUrlsJson,
            tone: tone,
            createdAt: createdAt,
            durationSeconds: durationSeconds,
            audioWavPath: audioWavPath,
            audioMp3Path: audioMp3Path,
            transcriptJsonPath: transcriptJsonPath,
            status: status,
            errorMessage: errorMessage,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String episodeId,
            required String title,
            required String subreddit,
            required String sourceUrlsJson,
            required String tone,
            required DateTime createdAt,
            required int durationSeconds,
            Value<String?> audioWavPath = const Value.absent(),
            Value<String?> audioMp3Path = const Value.absent(),
            Value<String?> transcriptJsonPath = const Value.absent(),
            Value<int> status = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
          }) =>
              EpisodesCompanion.insert(
            id: id,
            episodeId: episodeId,
            title: title,
            subreddit: subreddit,
            sourceUrlsJson: sourceUrlsJson,
            tone: tone,
            createdAt: createdAt,
            durationSeconds: durationSeconds,
            audioWavPath: audioWavPath,
            audioMp3Path: audioMp3Path,
            transcriptJsonPath: transcriptJsonPath,
            status: status,
            errorMessage: errorMessage,
          ),
          withReferenceMapper: (p0) => p0.map((e) => (e.readTable(table), BaseReferences(db, table, e))).toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$EpisodesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $EpisodesTable,
    Episode,
    $$EpisodesTableFilterComposer,
    $$EpisodesTableOrderingComposer,
    $$EpisodesTableAnnotationComposer,
    $$EpisodesTableCreateCompanionBuilder,
    $$EpisodesTableUpdateCompanionBuilder,
    (Episode, BaseReferences<_$AppDatabase, $EpisodesTable, Episode>),
    Episode,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$EpisodesTableTableManager get episodes => $$EpisodesTableTableManager(_db, _db.episodes);
}
