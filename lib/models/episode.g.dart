// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'episode.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetEpisodeCollection on Isar {
  IsarCollection<Episode> get episodes => this.collection();
}

const EpisodeSchema = CollectionSchema(
  name: r'Episode',
  id: -3258565036328751473,
  properties: {
    r'audioMp3Path': PropertySchema(
      id: 0,
      name: r'audioMp3Path',
      type: IsarType.string,
    ),
    r'audioWavPath': PropertySchema(
      id: 1,
      name: r'audioWavPath',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 2,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'durationSeconds': PropertySchema(
      id: 3,
      name: r'durationSeconds',
      type: IsarType.long,
    ),
    r'episodeId': PropertySchema(
      id: 4,
      name: r'episodeId',
      type: IsarType.string,
    ),
    r'errorMessage': PropertySchema(
      id: 5,
      name: r'errorMessage',
      type: IsarType.string,
    ),
    r'sourceUrls': PropertySchema(
      id: 6,
      name: r'sourceUrls',
      type: IsarType.stringList,
    ),
    r'status': PropertySchema(
      id: 7,
      name: r'status',
      type: IsarType.byte,
      enumMap: _EpisodestatusEnumValueMap,
    ),
    r'subreddit': PropertySchema(
      id: 8,
      name: r'subreddit',
      type: IsarType.string,
    ),
    r'title': PropertySchema(
      id: 9,
      name: r'title',
      type: IsarType.string,
    ),
    r'tone': PropertySchema(
      id: 10,
      name: r'tone',
      type: IsarType.string,
    ),
    r'transcriptJsonPath': PropertySchema(
      id: 11,
      name: r'transcriptJsonPath',
      type: IsarType.string,
    )
  },
  estimateSize: _episodeEstimateSize,
  serialize: _episodeSerialize,
  deserialize: _episodeDeserialize,
  deserializeProp: _episodeDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _episodeGetId,
  getLinks: _episodeGetLinks,
  attach: _episodeAttach,
  version: '3.1.0+1',
);

int _episodeEstimateSize(
  Episode object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.audioMp3Path;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.audioWavPath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.episodeId.length * 3;
  {
    final value = object.errorMessage;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.sourceUrls.length * 3;
  {
    for (var i = 0; i < object.sourceUrls.length; i++) {
      final value = object.sourceUrls[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.subreddit.length * 3;
  bytesCount += 3 + object.title.length * 3;
  bytesCount += 3 + object.tone.length * 3;
  {
    final value = object.transcriptJsonPath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _episodeSerialize(
  Episode object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.audioMp3Path);
  writer.writeString(offsets[1], object.audioWavPath);
  writer.writeDateTime(offsets[2], object.createdAt);
  writer.writeLong(offsets[3], object.durationSeconds);
  writer.writeString(offsets[4], object.episodeId);
  writer.writeString(offsets[5], object.errorMessage);
  writer.writeStringList(offsets[6], object.sourceUrls);
  writer.writeByte(offsets[7], object.status.index);
  writer.writeString(offsets[8], object.subreddit);
  writer.writeString(offsets[9], object.title);
  writer.writeString(offsets[10], object.tone);
  writer.writeString(offsets[11], object.transcriptJsonPath);
}

Episode _episodeDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Episode();
  object.audioMp3Path = reader.readStringOrNull(offsets[0]);
  object.audioWavPath = reader.readStringOrNull(offsets[1]);
  object.createdAt = reader.readDateTime(offsets[2]);
  object.durationSeconds = reader.readLong(offsets[3]);
  object.episodeId = reader.readString(offsets[4]);
  object.errorMessage = reader.readStringOrNull(offsets[5]);
  object.id = id;
  object.sourceUrls = reader.readStringList(offsets[6]) ?? [];
  object.status =
      _EpisodestatusValueEnumMap[reader.readByteOrNull(offsets[7])] ??
          EpisodeStatus.pending;
  object.subreddit = reader.readString(offsets[8]);
  object.title = reader.readString(offsets[9]);
  object.tone = reader.readString(offsets[10]);
  object.transcriptJsonPath = reader.readStringOrNull(offsets[11]);
  return object;
}

P _episodeDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readStringList(offset) ?? []) as P;
    case 7:
      return (_EpisodestatusValueEnumMap[reader.readByteOrNull(offset)] ??
          EpisodeStatus.pending) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readString(offset)) as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _EpisodestatusEnumValueMap = {
  'pending': 0,
  'generating': 1,
  'complete': 2,
  'failed': 3,
};
const _EpisodestatusValueEnumMap = {
  0: EpisodeStatus.pending,
  1: EpisodeStatus.generating,
  2: EpisodeStatus.complete,
  3: EpisodeStatus.failed,
};

Id _episodeGetId(Episode object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _episodeGetLinks(Episode object) {
  return [];
}

void _episodeAttach(IsarCollection<dynamic> col, Id id, Episode object) {
  object.id = id;
}

extension EpisodeQueryWhereSort on QueryBuilder<Episode, Episode, QWhere> {
  QueryBuilder<Episode, Episode, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension EpisodeQueryWhere on QueryBuilder<Episode, Episode, QWhereClause> {
  QueryBuilder<Episode, Episode, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<Episode, Episode, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Episode, Episode, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Episode, Episode, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension EpisodeQueryFilter
    on QueryBuilder<Episode, Episode, QFilterCondition> {
  QueryBuilder<Episode, Episode, QAfterFilterCondition> audioMp3PathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'audioMp3Path',
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition>
      audioMp3PathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'audioMp3Path',
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> audioMp3PathEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'audioMp3Path',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> audioMp3PathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'audioMp3Path',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> audioMp3PathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'audioMp3Path',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> audioMp3PathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'audioMp3Path',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> audioMp3PathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'audioMp3Path',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> audioMp3PathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'audioMp3Path',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> audioMp3PathContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'audioMp3Path',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> audioMp3PathMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'audioMp3Path',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> audioMp3PathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'audioMp3Path',
        value: '',
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition>
      audioMp3PathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'audioMp3Path',
        value: '',
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> audioWavPathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'audioWavPath',
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition>
      audioWavPathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'audioWavPath',
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> audioWavPathEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'audioWavPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> audioWavPathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'audioWavPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> audioWavPathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'audioWavPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> audioWavPathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'audioWavPath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> audioWavPathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'audioWavPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> audioWavPathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'audioWavPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> audioWavPathContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'audioWavPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> audioWavPathMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'audioWavPath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> audioWavPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'audioWavPath',
        value: '',
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition>
      audioWavPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'audioWavPath',
        value: '',
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> createdAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> durationSecondsEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'durationSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition>
      durationSecondsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'durationSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> durationSecondsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'durationSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> durationSecondsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'durationSeconds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> episodeIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'episodeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> episodeIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'episodeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> episodeIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'episodeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> episodeIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'episodeId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> episodeIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'episodeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> episodeIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'episodeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> episodeIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'episodeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> episodeIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'episodeId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> episodeIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'episodeId',
        value: '',
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> episodeIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'episodeId',
        value: '',
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> errorMessageIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'errorMessage',
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition>
      errorMessageIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'errorMessage',
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> errorMessageEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'errorMessage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> errorMessageGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'errorMessage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> errorMessageLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'errorMessage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> errorMessageBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'errorMessage',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> errorMessageStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'errorMessage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> errorMessageEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'errorMessage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> errorMessageContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'errorMessage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> errorMessageMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'errorMessage',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> errorMessageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'errorMessage',
        value: '',
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition>
      errorMessageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'errorMessage',
        value: '',
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition>
      sourceUrlsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sourceUrls',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition>
      sourceUrlsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sourceUrls',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition>
      sourceUrlsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sourceUrls',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition>
      sourceUrlsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sourceUrls',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition>
      sourceUrlsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'sourceUrls',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition>
      sourceUrlsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'sourceUrls',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition>
      sourceUrlsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'sourceUrls',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition>
      sourceUrlsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'sourceUrls',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition>
      sourceUrlsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sourceUrls',
        value: '',
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition>
      sourceUrlsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'sourceUrls',
        value: '',
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> sourceUrlsLengthEqualTo(
      int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'sourceUrls',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> sourceUrlsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'sourceUrls',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> sourceUrlsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'sourceUrls',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition>
      sourceUrlsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'sourceUrls',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition>
      sourceUrlsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'sourceUrls',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> sourceUrlsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'sourceUrls',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> statusEqualTo(
      EpisodeStatus value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: value,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> statusGreaterThan(
    EpisodeStatus value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'status',
        value: value,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> statusLessThan(
    EpisodeStatus value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'status',
        value: value,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> statusBetween(
    EpisodeStatus lower,
    EpisodeStatus upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'status',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> subredditEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'subreddit',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> subredditGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'subreddit',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> subredditLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'subreddit',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> subredditBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'subreddit',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> subredditStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'subreddit',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> subredditEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'subreddit',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> subredditContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'subreddit',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> subredditMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'subreddit',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> subredditIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'subreddit',
        value: '',
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> subredditIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'subreddit',
        value: '',
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> titleEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> titleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> titleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> titleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'title',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> titleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> titleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> titleContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> titleMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'title',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> toneEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> toneGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> toneLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> toneBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tone',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> toneStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'tone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> toneEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'tone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> toneContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'tone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> toneMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'tone',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> toneIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tone',
        value: '',
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition> toneIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'tone',
        value: '',
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition>
      transcriptJsonPathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'transcriptJsonPath',
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition>
      transcriptJsonPathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'transcriptJsonPath',
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition>
      transcriptJsonPathEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'transcriptJsonPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition>
      transcriptJsonPathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'transcriptJsonPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition>
      transcriptJsonPathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'transcriptJsonPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition>
      transcriptJsonPathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'transcriptJsonPath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition>
      transcriptJsonPathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'transcriptJsonPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition>
      transcriptJsonPathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'transcriptJsonPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition>
      transcriptJsonPathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'transcriptJsonPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition>
      transcriptJsonPathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'transcriptJsonPath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition>
      transcriptJsonPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'transcriptJsonPath',
        value: '',
      ));
    });
  }

  QueryBuilder<Episode, Episode, QAfterFilterCondition>
      transcriptJsonPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'transcriptJsonPath',
        value: '',
      ));
    });
  }
}

extension EpisodeQueryObject
    on QueryBuilder<Episode, Episode, QFilterCondition> {}

extension EpisodeQueryLinks
    on QueryBuilder<Episode, Episode, QFilterCondition> {}

extension EpisodeQuerySortBy on QueryBuilder<Episode, Episode, QSortBy> {
  QueryBuilder<Episode, Episode, QAfterSortBy> sortByAudioMp3Path() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audioMp3Path', Sort.asc);
    });
  }

  QueryBuilder<Episode, Episode, QAfterSortBy> sortByAudioMp3PathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audioMp3Path', Sort.desc);
    });
  }

  QueryBuilder<Episode, Episode, QAfterSortBy> sortByAudioWavPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audioWavPath', Sort.asc);
    });
  }

  QueryBuilder<Episode, Episode, QAfterSortBy> sortByAudioWavPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audioWavPath', Sort.desc);
    });
  }

  QueryBuilder<Episode, Episode, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<Episode, Episode, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<Episode, Episode, QAfterSortBy> sortByDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationSeconds', Sort.asc);
    });
  }

  QueryBuilder<Episode, Episode, QAfterSortBy> sortByDurationSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationSeconds', Sort.desc);
    });
  }

  QueryBuilder<Episode, Episode, QAfterSortBy> sortByEpisodeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'episodeId', Sort.asc);
    });
  }

  QueryBuilder<Episode, Episode, QAfterSortBy> sortByEpisodeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'episodeId', Sort.desc);
    });
  }

  QueryBuilder<Episode, Episode, QAfterSortBy> sortByErrorMessage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorMessage', Sort.asc);
    });
  }

  QueryBuilder<Episode, Episode, QAfterSortBy> sortByErrorMessageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorMessage', Sort.desc);
    });
  }

  QueryBuilder<Episode, Episode, QAfterSortBy> sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<Episode, Episode, QAfterSortBy> sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<Episode, Episode, QAfterSortBy> sortBySubreddit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subreddit', Sort.asc);
    });
  }

  QueryBuilder<Episode, Episode, QAfterSortBy> sortBySubredditDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subreddit', Sort.desc);
    });
  }

  QueryBuilder<Episode, Episode, QAfterSortBy> sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<Episode, Episode, QAfterSortBy> sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<Episode, Episode, QAfterSortBy> sortByTone() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tone', Sort.asc);
    });
  }

  QueryBuilder<Episode, Episode, QAfterSortBy> sortByToneDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tone', Sort.desc);
    });
  }

  QueryBuilder<Episode, Episode, QAfterSortBy> sortByTranscriptJsonPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transcriptJsonPath', Sort.asc);
    });
  }

  QueryBuilder<Episode, Episode, QAfterSortBy> sortByTranscriptJsonPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transcriptJsonPath', Sort.desc);
    });
  }
}

extension EpisodeQuerySortThenBy
    on QueryBuilder<Episode, Episode, QSortThenBy> {
  QueryBuilder<Episode, Episode, QAfterSortBy> thenByAudioMp3Path() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audioMp3Path', Sort.asc);
    });
  }

  QueryBuilder<Episode, Episode, QAfterSortBy> thenByAudioMp3PathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audioMp3Path', Sort.desc);
    });
  }

  QueryBuilder<Episode, Episode, QAfterSortBy> thenByAudioWavPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audioWavPath', Sort.asc);
    });
  }

  QueryBuilder<Episode, Episode, QAfterSortBy> thenByAudioWavPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audioWavPath', Sort.desc);
    });
  }

  QueryBuilder<Episode, Episode, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<Episode, Episode, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<Episode, Episode, QAfterSortBy> thenByDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationSeconds', Sort.asc);
    });
  }

  QueryBuilder<Episode, Episode, QAfterSortBy> thenByDurationSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationSeconds', Sort.desc);
    });
  }

  QueryBuilder<Episode, Episode, QAfterSortBy> thenByEpisodeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'episodeId', Sort.asc);
    });
  }

  QueryBuilder<Episode, Episode, QAfterSortBy> thenByEpisodeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'episodeId', Sort.desc);
    });
  }

  QueryBuilder<Episode, Episode, QAfterSortBy> thenByErrorMessage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorMessage', Sort.asc);
    });
  }

  QueryBuilder<Episode, Episode, QAfterSortBy> thenByErrorMessageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorMessage', Sort.desc);
    });
  }

  QueryBuilder<Episode, Episode, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Episode, Episode, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Episode, Episode, QAfterSortBy> thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<Episode, Episode, QAfterSortBy> thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<Episode, Episode, QAfterSortBy> thenBySubreddit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subreddit', Sort.asc);
    });
  }

  QueryBuilder<Episode, Episode, QAfterSortBy> thenBySubredditDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subreddit', Sort.desc);
    });
  }

  QueryBuilder<Episode, Episode, QAfterSortBy> thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<Episode, Episode, QAfterSortBy> thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<Episode, Episode, QAfterSortBy> thenByTone() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tone', Sort.asc);
    });
  }

  QueryBuilder<Episode, Episode, QAfterSortBy> thenByToneDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tone', Sort.desc);
    });
  }

  QueryBuilder<Episode, Episode, QAfterSortBy> thenByTranscriptJsonPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transcriptJsonPath', Sort.asc);
    });
  }

  QueryBuilder<Episode, Episode, QAfterSortBy> thenByTranscriptJsonPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transcriptJsonPath', Sort.desc);
    });
  }
}

extension EpisodeQueryWhereDistinct
    on QueryBuilder<Episode, Episode, QDistinct> {
  QueryBuilder<Episode, Episode, QDistinct> distinctByAudioMp3Path(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'audioMp3Path', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Episode, Episode, QDistinct> distinctByAudioWavPath(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'audioWavPath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Episode, Episode, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<Episode, Episode, QDistinct> distinctByDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'durationSeconds');
    });
  }

  QueryBuilder<Episode, Episode, QDistinct> distinctByEpisodeId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'episodeId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Episode, Episode, QDistinct> distinctByErrorMessage(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'errorMessage', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Episode, Episode, QDistinct> distinctBySourceUrls() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sourceUrls');
    });
  }

  QueryBuilder<Episode, Episode, QDistinct> distinctByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status');
    });
  }

  QueryBuilder<Episode, Episode, QDistinct> distinctBySubreddit(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'subreddit', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Episode, Episode, QDistinct> distinctByTitle(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Episode, Episode, QDistinct> distinctByTone(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tone', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Episode, Episode, QDistinct> distinctByTranscriptJsonPath(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'transcriptJsonPath',
          caseSensitive: caseSensitive);
    });
  }
}

extension EpisodeQueryProperty
    on QueryBuilder<Episode, Episode, QQueryProperty> {
  QueryBuilder<Episode, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Episode, String?, QQueryOperations> audioMp3PathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'audioMp3Path');
    });
  }

  QueryBuilder<Episode, String?, QQueryOperations> audioWavPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'audioWavPath');
    });
  }

  QueryBuilder<Episode, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<Episode, int, QQueryOperations> durationSecondsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'durationSeconds');
    });
  }

  QueryBuilder<Episode, String, QQueryOperations> episodeIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'episodeId');
    });
  }

  QueryBuilder<Episode, String?, QQueryOperations> errorMessageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'errorMessage');
    });
  }

  QueryBuilder<Episode, List<String>, QQueryOperations> sourceUrlsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceUrls');
    });
  }

  QueryBuilder<Episode, EpisodeStatus, QQueryOperations> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<Episode, String, QQueryOperations> subredditProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'subreddit');
    });
  }

  QueryBuilder<Episode, String, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }

  QueryBuilder<Episode, String, QQueryOperations> toneProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tone');
    });
  }

  QueryBuilder<Episode, String?, QQueryOperations>
      transcriptJsonPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'transcriptJsonPath');
    });
  }
}
