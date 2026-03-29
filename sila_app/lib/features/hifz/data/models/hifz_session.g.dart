// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hifz_session.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetHifzSessionCollection on Isar {
  IsarCollection<HifzSession> get hifzSessions => this.collection();
}

const HifzSessionSchema = CollectionSchema(
  name: r'HifzSession',
  id: 1469769376684306631,
  properties: {
    r'correctWords': PropertySchema(
      id: 0,
      name: r'correctWords',
      type: IsarType.long,
    ),
    r'date': PropertySchema(
      id: 1,
      name: r'date',
      type: IsarType.dateTime,
    ),
    r'durationSeconds': PropertySchema(
      id: 2,
      name: r'durationSeconds',
      type: IsarType.long,
    ),
    r'fromVerse': PropertySchema(
      id: 3,
      name: r'fromVerse',
      type: IsarType.long,
    ),
    r'hasanat': PropertySchema(
      id: 4,
      name: r'hasanat',
      type: IsarType.long,
    ),
    r'method': PropertySchema(
      id: 5,
      name: r'method',
      type: IsarType.string,
    ),
    r'surahIndex': PropertySchema(
      id: 6,
      name: r'surahIndex',
      type: IsarType.long,
    ),
    r'toVerse': PropertySchema(
      id: 7,
      name: r'toVerse',
      type: IsarType.long,
    ),
    r'wrongWords': PropertySchema(
      id: 8,
      name: r'wrongWords',
      type: IsarType.long,
    )
  },
  estimateSize: _hifzSessionEstimateSize,
  serialize: _hifzSessionSerialize,
  deserialize: _hifzSessionDeserialize,
  deserializeProp: _hifzSessionDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _hifzSessionGetId,
  getLinks: _hifzSessionGetLinks,
  attach: _hifzSessionAttach,
  version: '3.1.0+1',
);

int _hifzSessionEstimateSize(
  HifzSession object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.method.length * 3;
  return bytesCount;
}

void _hifzSessionSerialize(
  HifzSession object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.correctWords);
  writer.writeDateTime(offsets[1], object.date);
  writer.writeLong(offsets[2], object.durationSeconds);
  writer.writeLong(offsets[3], object.fromVerse);
  writer.writeLong(offsets[4], object.hasanat);
  writer.writeString(offsets[5], object.method);
  writer.writeLong(offsets[6], object.surahIndex);
  writer.writeLong(offsets[7], object.toVerse);
  writer.writeLong(offsets[8], object.wrongWords);
}

HifzSession _hifzSessionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = HifzSession();
  object.correctWords = reader.readLong(offsets[0]);
  object.date = reader.readDateTime(offsets[1]);
  object.durationSeconds = reader.readLong(offsets[2]);
  object.fromVerse = reader.readLong(offsets[3]);
  object.hasanat = reader.readLong(offsets[4]);
  object.id = id;
  object.method = reader.readString(offsets[5]);
  object.surahIndex = reader.readLong(offsets[6]);
  object.toVerse = reader.readLong(offsets[7]);
  object.wrongWords = reader.readLong(offsets[8]);
  return object;
}

P _hifzSessionDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _hifzSessionGetId(HifzSession object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _hifzSessionGetLinks(HifzSession object) {
  return [];
}

void _hifzSessionAttach(
    IsarCollection<dynamic> col, Id id, HifzSession object) {
  object.id = id;
}

extension HifzSessionQueryWhereSort
    on QueryBuilder<HifzSession, HifzSession, QWhere> {
  QueryBuilder<HifzSession, HifzSession, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension HifzSessionQueryWhere
    on QueryBuilder<HifzSession, HifzSession, QWhereClause> {
  QueryBuilder<HifzSession, HifzSession, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<HifzSession, HifzSession, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterWhereClause> idBetween(
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

extension HifzSessionQueryFilter
    on QueryBuilder<HifzSession, HifzSession, QFilterCondition> {
  QueryBuilder<HifzSession, HifzSession, QAfterFilterCondition>
      correctWordsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'correctWords',
        value: value,
      ));
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterFilterCondition>
      correctWordsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'correctWords',
        value: value,
      ));
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterFilterCondition>
      correctWordsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'correctWords',
        value: value,
      ));
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterFilterCondition>
      correctWordsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'correctWords',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterFilterCondition> dateEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterFilterCondition> dateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterFilterCondition> dateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterFilterCondition> dateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'date',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterFilterCondition>
      durationSecondsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'durationSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterFilterCondition>
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

  QueryBuilder<HifzSession, HifzSession, QAfterFilterCondition>
      durationSecondsLessThan(
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

  QueryBuilder<HifzSession, HifzSession, QAfterFilterCondition>
      durationSecondsBetween(
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

  QueryBuilder<HifzSession, HifzSession, QAfterFilterCondition>
      fromVerseEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fromVerse',
        value: value,
      ));
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterFilterCondition>
      fromVerseGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fromVerse',
        value: value,
      ));
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterFilterCondition>
      fromVerseLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fromVerse',
        value: value,
      ));
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterFilterCondition>
      fromVerseBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fromVerse',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterFilterCondition> hasanatEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hasanat',
        value: value,
      ));
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterFilterCondition>
      hasanatGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'hasanat',
        value: value,
      ));
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterFilterCondition> hasanatLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'hasanat',
        value: value,
      ));
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterFilterCondition> hasanatBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'hasanat',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<HifzSession, HifzSession, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<HifzSession, HifzSession, QAfterFilterCondition> idBetween(
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

  QueryBuilder<HifzSession, HifzSession, QAfterFilterCondition> methodEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'method',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterFilterCondition>
      methodGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'method',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterFilterCondition> methodLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'method',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterFilterCondition> methodBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'method',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterFilterCondition>
      methodStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'method',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterFilterCondition> methodEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'method',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterFilterCondition> methodContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'method',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterFilterCondition> methodMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'method',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterFilterCondition>
      methodIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'method',
        value: '',
      ));
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterFilterCondition>
      methodIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'method',
        value: '',
      ));
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterFilterCondition>
      surahIndexEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'surahIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterFilterCondition>
      surahIndexGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'surahIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterFilterCondition>
      surahIndexLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'surahIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterFilterCondition>
      surahIndexBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'surahIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterFilterCondition> toVerseEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'toVerse',
        value: value,
      ));
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterFilterCondition>
      toVerseGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'toVerse',
        value: value,
      ));
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterFilterCondition> toVerseLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'toVerse',
        value: value,
      ));
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterFilterCondition> toVerseBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'toVerse',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterFilterCondition>
      wrongWordsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'wrongWords',
        value: value,
      ));
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterFilterCondition>
      wrongWordsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'wrongWords',
        value: value,
      ));
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterFilterCondition>
      wrongWordsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'wrongWords',
        value: value,
      ));
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterFilterCondition>
      wrongWordsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'wrongWords',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension HifzSessionQueryObject
    on QueryBuilder<HifzSession, HifzSession, QFilterCondition> {}

extension HifzSessionQueryLinks
    on QueryBuilder<HifzSession, HifzSession, QFilterCondition> {}

extension HifzSessionQuerySortBy
    on QueryBuilder<HifzSession, HifzSession, QSortBy> {
  QueryBuilder<HifzSession, HifzSession, QAfterSortBy> sortByCorrectWords() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'correctWords', Sort.asc);
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterSortBy>
      sortByCorrectWordsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'correctWords', Sort.desc);
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterSortBy> sortByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterSortBy> sortByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterSortBy> sortByDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationSeconds', Sort.asc);
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterSortBy>
      sortByDurationSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationSeconds', Sort.desc);
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterSortBy> sortByFromVerse() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fromVerse', Sort.asc);
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterSortBy> sortByFromVerseDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fromVerse', Sort.desc);
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterSortBy> sortByHasanat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasanat', Sort.asc);
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterSortBy> sortByHasanatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasanat', Sort.desc);
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterSortBy> sortByMethod() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'method', Sort.asc);
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterSortBy> sortByMethodDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'method', Sort.desc);
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterSortBy> sortBySurahIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahIndex', Sort.asc);
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterSortBy> sortBySurahIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahIndex', Sort.desc);
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterSortBy> sortByToVerse() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toVerse', Sort.asc);
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterSortBy> sortByToVerseDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toVerse', Sort.desc);
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterSortBy> sortByWrongWords() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wrongWords', Sort.asc);
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterSortBy> sortByWrongWordsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wrongWords', Sort.desc);
    });
  }
}

extension HifzSessionQuerySortThenBy
    on QueryBuilder<HifzSession, HifzSession, QSortThenBy> {
  QueryBuilder<HifzSession, HifzSession, QAfterSortBy> thenByCorrectWords() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'correctWords', Sort.asc);
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterSortBy>
      thenByCorrectWordsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'correctWords', Sort.desc);
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterSortBy> thenByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterSortBy> thenByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterSortBy> thenByDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationSeconds', Sort.asc);
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterSortBy>
      thenByDurationSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationSeconds', Sort.desc);
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterSortBy> thenByFromVerse() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fromVerse', Sort.asc);
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterSortBy> thenByFromVerseDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fromVerse', Sort.desc);
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterSortBy> thenByHasanat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasanat', Sort.asc);
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterSortBy> thenByHasanatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasanat', Sort.desc);
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterSortBy> thenByMethod() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'method', Sort.asc);
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterSortBy> thenByMethodDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'method', Sort.desc);
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterSortBy> thenBySurahIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahIndex', Sort.asc);
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterSortBy> thenBySurahIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahIndex', Sort.desc);
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterSortBy> thenByToVerse() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toVerse', Sort.asc);
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterSortBy> thenByToVerseDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toVerse', Sort.desc);
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterSortBy> thenByWrongWords() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wrongWords', Sort.asc);
    });
  }

  QueryBuilder<HifzSession, HifzSession, QAfterSortBy> thenByWrongWordsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wrongWords', Sort.desc);
    });
  }
}

extension HifzSessionQueryWhereDistinct
    on QueryBuilder<HifzSession, HifzSession, QDistinct> {
  QueryBuilder<HifzSession, HifzSession, QDistinct> distinctByCorrectWords() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'correctWords');
    });
  }

  QueryBuilder<HifzSession, HifzSession, QDistinct> distinctByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'date');
    });
  }

  QueryBuilder<HifzSession, HifzSession, QDistinct>
      distinctByDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'durationSeconds');
    });
  }

  QueryBuilder<HifzSession, HifzSession, QDistinct> distinctByFromVerse() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fromVerse');
    });
  }

  QueryBuilder<HifzSession, HifzSession, QDistinct> distinctByHasanat() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hasanat');
    });
  }

  QueryBuilder<HifzSession, HifzSession, QDistinct> distinctByMethod(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'method', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<HifzSession, HifzSession, QDistinct> distinctBySurahIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'surahIndex');
    });
  }

  QueryBuilder<HifzSession, HifzSession, QDistinct> distinctByToVerse() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'toVerse');
    });
  }

  QueryBuilder<HifzSession, HifzSession, QDistinct> distinctByWrongWords() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'wrongWords');
    });
  }
}

extension HifzSessionQueryProperty
    on QueryBuilder<HifzSession, HifzSession, QQueryProperty> {
  QueryBuilder<HifzSession, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<HifzSession, int, QQueryOperations> correctWordsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'correctWords');
    });
  }

  QueryBuilder<HifzSession, DateTime, QQueryOperations> dateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'date');
    });
  }

  QueryBuilder<HifzSession, int, QQueryOperations> durationSecondsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'durationSeconds');
    });
  }

  QueryBuilder<HifzSession, int, QQueryOperations> fromVerseProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fromVerse');
    });
  }

  QueryBuilder<HifzSession, int, QQueryOperations> hasanatProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hasanat');
    });
  }

  QueryBuilder<HifzSession, String, QQueryOperations> methodProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'method');
    });
  }

  QueryBuilder<HifzSession, int, QQueryOperations> surahIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'surahIndex');
    });
  }

  QueryBuilder<HifzSession, int, QQueryOperations> toVerseProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'toVerse');
    });
  }

  QueryBuilder<HifzSession, int, QQueryOperations> wrongWordsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'wrongWords');
    });
  }
}
