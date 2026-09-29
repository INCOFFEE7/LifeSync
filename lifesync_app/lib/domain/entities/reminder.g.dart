// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminder.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetReminderCollection on Isar {
  IsarCollection<Reminder> get reminders => this.collection();
}

const ReminderSchema = CollectionSchema(
  name: r'Reminder',
  id: -8566764253612256045,
  properties: {
    r'category': PropertySchema(
      id: 0,
      name: r'category',
      type: IsarType.byte,
      enumMap: _RemindercategoryEnumValueMap,
    ),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'customCategory': PropertySchema(
      id: 2,
      name: r'customCategory',
      type: IsarType.string,
    ),
    r'customSound': PropertySchema(
      id: 3,
      name: r'customSound',
      type: IsarType.string,
    ),
    r'deleted': PropertySchema(
      id: 4,
      name: r'deleted',
      type: IsarType.bool,
    ),
    r'deletedAt': PropertySchema(
      id: 5,
      name: r'deletedAt',
      type: IsarType.dateTime,
    ),
    r'description': PropertySchema(
      id: 6,
      name: r'description',
      type: IsarType.string,
    ),
    r'deviceId': PropertySchema(
      id: 7,
      name: r'deviceId',
      type: IsarType.string,
    ),
    r'endTime': PropertySchema(
      id: 8,
      name: r'endTime',
      type: IsarType.dateTime,
    ),
    r'isAllDay': PropertySchema(
      id: 9,
      name: r'isAllDay',
      type: IsarType.bool,
    ),
    r'notificationPreferenceMinutes': PropertySchema(
      id: 10,
      name: r'notificationPreferenceMinutes',
      type: IsarType.long,
    ),
    r'priority': PropertySchema(
      id: 11,
      name: r'priority',
      type: IsarType.byte,
      enumMap: _ReminderpriorityEnumValueMap,
    ),
    r'status': PropertySchema(
      id: 12,
      name: r'status',
      type: IsarType.byte,
      enumMap: _ReminderstatusEnumValueMap,
    ),
    r'syncId': PropertySchema(
      id: 13,
      name: r'syncId',
      type: IsarType.string,
    ),
    r'syncStatus': PropertySchema(
      id: 14,
      name: r'syncStatus',
      type: IsarType.string,
    ),
    r'targetDateTime': PropertySchema(
      id: 15,
      name: r'targetDateTime',
      type: IsarType.dateTime,
    ),
    r'title': PropertySchema(
      id: 16,
      name: r'title',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 17,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'version': PropertySchema(
      id: 18,
      name: r'version',
      type: IsarType.long,
    )
  },
  estimateSize: _reminderEstimateSize,
  serialize: _reminderSerialize,
  deserialize: _reminderDeserialize,
  deserializeProp: _reminderDeserializeProp,
  idName: r'id',
  indexes: {
    r'syncId': IndexSchema(
      id: 7538593479801827566,
      name: r'syncId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'syncId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _reminderGetId,
  getLinks: _reminderGetLinks,
  attach: _reminderAttach,
  version: '3.1.0+1',
);

int _reminderEstimateSize(
  Reminder object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.customCategory;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.customSound;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.description;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.deviceId.length * 3;
  bytesCount += 3 + object.syncId.length * 3;
  bytesCount += 3 + object.syncStatus.length * 3;
  bytesCount += 3 + object.title.length * 3;
  return bytesCount;
}

void _reminderSerialize(
  Reminder object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeByte(offsets[0], object.category.index);
  writer.writeDateTime(offsets[1], object.createdAt);
  writer.writeString(offsets[2], object.customCategory);
  writer.writeString(offsets[3], object.customSound);
  writer.writeBool(offsets[4], object.deleted);
  writer.writeDateTime(offsets[5], object.deletedAt);
  writer.writeString(offsets[6], object.description);
  writer.writeString(offsets[7], object.deviceId);
  writer.writeDateTime(offsets[8], object.endTime);
  writer.writeBool(offsets[9], object.isAllDay);
  writer.writeLong(offsets[10], object.notificationPreferenceMinutes);
  writer.writeByte(offsets[11], object.priority.index);
  writer.writeByte(offsets[12], object.status.index);
  writer.writeString(offsets[13], object.syncId);
  writer.writeString(offsets[14], object.syncStatus);
  writer.writeDateTime(offsets[15], object.targetDateTime);
  writer.writeString(offsets[16], object.title);
  writer.writeDateTime(offsets[17], object.updatedAt);
  writer.writeLong(offsets[18], object.version);
}

Reminder _reminderDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Reminder();
  object.category =
      _RemindercategoryValueEnumMap[reader.readByteOrNull(offsets[0])] ??
          ReminderCategory.work;
  object.createdAt = reader.readDateTime(offsets[1]);
  object.customCategory = reader.readStringOrNull(offsets[2]);
  object.customSound = reader.readStringOrNull(offsets[3]);
  object.deleted = reader.readBool(offsets[4]);
  object.deletedAt = reader.readDateTimeOrNull(offsets[5]);
  object.description = reader.readStringOrNull(offsets[6]);
  object.deviceId = reader.readString(offsets[7]);
  object.endTime = reader.readDateTimeOrNull(offsets[8]);
  object.id = id;
  object.isAllDay = reader.readBool(offsets[9]);
  object.notificationPreferenceMinutes = reader.readLong(offsets[10]);
  object.priority =
      _ReminderpriorityValueEnumMap[reader.readByteOrNull(offsets[11])] ??
          PriorityLevel.low;
  object.status =
      _ReminderstatusValueEnumMap[reader.readByteOrNull(offsets[12])] ??
          ReminderStatus.pending;
  object.syncId = reader.readString(offsets[13]);
  object.syncStatus = reader.readString(offsets[14]);
  object.targetDateTime = reader.readDateTime(offsets[15]);
  object.title = reader.readString(offsets[16]);
  object.updatedAt = reader.readDateTime(offsets[17]);
  object.version = reader.readLong(offsets[18]);
  return object;
}

P _reminderDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (_RemindercategoryValueEnumMap[reader.readByteOrNull(offset)] ??
          ReminderCategory.work) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 9:
      return (reader.readBool(offset)) as P;
    case 10:
      return (reader.readLong(offset)) as P;
    case 11:
      return (_ReminderpriorityValueEnumMap[reader.readByteOrNull(offset)] ??
          PriorityLevel.low) as P;
    case 12:
      return (_ReminderstatusValueEnumMap[reader.readByteOrNull(offset)] ??
          ReminderStatus.pending) as P;
    case 13:
      return (reader.readString(offset)) as P;
    case 14:
      return (reader.readString(offset)) as P;
    case 15:
      return (reader.readDateTime(offset)) as P;
    case 16:
      return (reader.readString(offset)) as P;
    case 17:
      return (reader.readDateTime(offset)) as P;
    case 18:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _RemindercategoryEnumValueMap = {
  'work': 0,
  'personal': 1,
  'health': 2,
  'finance': 3,
  'other': 4,
};
const _RemindercategoryValueEnumMap = {
  0: ReminderCategory.work,
  1: ReminderCategory.personal,
  2: ReminderCategory.health,
  3: ReminderCategory.finance,
  4: ReminderCategory.other,
};
const _ReminderpriorityEnumValueMap = {
  'low': 0,
  'medium': 1,
  'high': 2,
};
const _ReminderpriorityValueEnumMap = {
  0: PriorityLevel.low,
  1: PriorityLevel.medium,
  2: PriorityLevel.high,
};
const _ReminderstatusEnumValueMap = {
  'pending': 0,
  'completed': 1,
  'cancelled': 2,
};
const _ReminderstatusValueEnumMap = {
  0: ReminderStatus.pending,
  1: ReminderStatus.completed,
  2: ReminderStatus.cancelled,
};

Id _reminderGetId(Reminder object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _reminderGetLinks(Reminder object) {
  return [];
}

void _reminderAttach(IsarCollection<dynamic> col, Id id, Reminder object) {
  object.id = id;
}

extension ReminderByIndex on IsarCollection<Reminder> {
  Future<Reminder?> getBySyncId(String syncId) {
    return getByIndex(r'syncId', [syncId]);
  }

  Reminder? getBySyncIdSync(String syncId) {
    return getByIndexSync(r'syncId', [syncId]);
  }

  Future<bool> deleteBySyncId(String syncId) {
    return deleteByIndex(r'syncId', [syncId]);
  }

  bool deleteBySyncIdSync(String syncId) {
    return deleteByIndexSync(r'syncId', [syncId]);
  }

  Future<List<Reminder?>> getAllBySyncId(List<String> syncIdValues) {
    final values = syncIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'syncId', values);
  }

  List<Reminder?> getAllBySyncIdSync(List<String> syncIdValues) {
    final values = syncIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'syncId', values);
  }

  Future<int> deleteAllBySyncId(List<String> syncIdValues) {
    final values = syncIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'syncId', values);
  }

  int deleteAllBySyncIdSync(List<String> syncIdValues) {
    final values = syncIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'syncId', values);
  }

  Future<Id> putBySyncId(Reminder object) {
    return putByIndex(r'syncId', object);
  }

  Id putBySyncIdSync(Reminder object, {bool saveLinks = true}) {
    return putByIndexSync(r'syncId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllBySyncId(List<Reminder> objects) {
    return putAllByIndex(r'syncId', objects);
  }

  List<Id> putAllBySyncIdSync(List<Reminder> objects, {bool saveLinks = true}) {
    return putAllByIndexSync(r'syncId', objects, saveLinks: saveLinks);
  }
}

extension ReminderQueryWhereSort on QueryBuilder<Reminder, Reminder, QWhere> {
  QueryBuilder<Reminder, Reminder, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ReminderQueryWhere on QueryBuilder<Reminder, Reminder, QWhereClause> {
  QueryBuilder<Reminder, Reminder, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<Reminder, Reminder, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterWhereClause> idBetween(
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

  QueryBuilder<Reminder, Reminder, QAfterWhereClause> syncIdEqualTo(
      String syncId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'syncId',
        value: [syncId],
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterWhereClause> syncIdNotEqualTo(
      String syncId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'syncId',
              lower: [],
              upper: [syncId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'syncId',
              lower: [syncId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'syncId',
              lower: [syncId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'syncId',
              lower: [],
              upper: [syncId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension ReminderQueryFilter
    on QueryBuilder<Reminder, Reminder, QFilterCondition> {
  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> categoryEqualTo(
      ReminderCategory value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'category',
        value: value,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> categoryGreaterThan(
    ReminderCategory value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'category',
        value: value,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> categoryLessThan(
    ReminderCategory value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'category',
        value: value,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> categoryBetween(
    ReminderCategory lower,
    ReminderCategory upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'category',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> createdAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> createdAtGreaterThan(
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

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> createdAtLessThan(
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

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> createdAtBetween(
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

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition>
      customCategoryIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'customCategory',
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition>
      customCategoryIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'customCategory',
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> customCategoryEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'customCategory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition>
      customCategoryGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'customCategory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition>
      customCategoryLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'customCategory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> customCategoryBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'customCategory',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition>
      customCategoryStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'customCategory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition>
      customCategoryEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'customCategory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition>
      customCategoryContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'customCategory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> customCategoryMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'customCategory',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition>
      customCategoryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'customCategory',
        value: '',
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition>
      customCategoryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'customCategory',
        value: '',
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> customSoundIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'customSound',
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition>
      customSoundIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'customSound',
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> customSoundEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'customSound',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition>
      customSoundGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'customSound',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> customSoundLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'customSound',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> customSoundBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'customSound',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> customSoundStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'customSound',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> customSoundEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'customSound',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> customSoundContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'customSound',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> customSoundMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'customSound',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> customSoundIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'customSound',
        value: '',
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition>
      customSoundIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'customSound',
        value: '',
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> deletedEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deleted',
        value: value,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> deletedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'deletedAt',
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> deletedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'deletedAt',
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> deletedAtEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deletedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> deletedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'deletedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> deletedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'deletedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> deletedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'deletedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> descriptionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'description',
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition>
      descriptionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'description',
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> descriptionEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition>
      descriptionGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> descriptionLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> descriptionBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'description',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> descriptionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> descriptionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> descriptionContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> descriptionMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'description',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition>
      descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> deviceIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deviceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> deviceIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'deviceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> deviceIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'deviceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> deviceIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'deviceId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> deviceIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'deviceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> deviceIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'deviceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> deviceIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'deviceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> deviceIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'deviceId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> deviceIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deviceId',
        value: '',
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> deviceIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'deviceId',
        value: '',
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> endTimeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'endTime',
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> endTimeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'endTime',
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> endTimeEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'endTime',
        value: value,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> endTimeGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'endTime',
        value: value,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> endTimeLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'endTime',
        value: value,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> endTimeBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'endTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> idBetween(
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

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> isAllDayEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isAllDay',
        value: value,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition>
      notificationPreferenceMinutesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notificationPreferenceMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition>
      notificationPreferenceMinutesGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'notificationPreferenceMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition>
      notificationPreferenceMinutesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'notificationPreferenceMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition>
      notificationPreferenceMinutesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'notificationPreferenceMinutes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> priorityEqualTo(
      PriorityLevel value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'priority',
        value: value,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> priorityGreaterThan(
    PriorityLevel value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'priority',
        value: value,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> priorityLessThan(
    PriorityLevel value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'priority',
        value: value,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> priorityBetween(
    PriorityLevel lower,
    PriorityLevel upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'priority',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> statusEqualTo(
      ReminderStatus value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: value,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> statusGreaterThan(
    ReminderStatus value, {
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

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> statusLessThan(
    ReminderStatus value, {
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

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> statusBetween(
    ReminderStatus lower,
    ReminderStatus upper, {
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

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> syncIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'syncId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> syncIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'syncId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> syncIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'syncId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> syncIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'syncId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> syncIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'syncId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> syncIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'syncId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> syncIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'syncId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> syncIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'syncId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> syncIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'syncId',
        value: '',
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> syncIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'syncId',
        value: '',
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> syncStatusEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'syncStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> syncStatusGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'syncStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> syncStatusLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'syncStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> syncStatusBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'syncStatus',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> syncStatusStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'syncStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> syncStatusEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'syncStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> syncStatusContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'syncStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> syncStatusMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'syncStatus',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> syncStatusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'syncStatus',
        value: '',
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition>
      syncStatusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'syncStatus',
        value: '',
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> targetDateTimeEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'targetDateTime',
        value: value,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition>
      targetDateTimeGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'targetDateTime',
        value: value,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition>
      targetDateTimeLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'targetDateTime',
        value: value,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> targetDateTimeBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'targetDateTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> titleEqualTo(
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

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> titleGreaterThan(
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

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> titleLessThan(
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

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> titleBetween(
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

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> titleStartsWith(
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

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> titleEndsWith(
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

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> titleContains(
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

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> titleMatches(
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

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> updatedAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> updatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> updatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> versionEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'version',
        value: value,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> versionGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'version',
        value: value,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> versionLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'version',
        value: value,
      ));
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterFilterCondition> versionBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'version',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension ReminderQueryObject
    on QueryBuilder<Reminder, Reminder, QFilterCondition> {}

extension ReminderQueryLinks
    on QueryBuilder<Reminder, Reminder, QFilterCondition> {}

extension ReminderQuerySortBy on QueryBuilder<Reminder, Reminder, QSortBy> {
  QueryBuilder<Reminder, Reminder, QAfterSortBy> sortByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> sortByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> sortByCustomCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customCategory', Sort.asc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> sortByCustomCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customCategory', Sort.desc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> sortByCustomSound() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customSound', Sort.asc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> sortByCustomSoundDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customSound', Sort.desc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> sortByDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deleted', Sort.asc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> sortByDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deleted', Sort.desc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> sortByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.asc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> sortByDeletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.desc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> sortByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> sortByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> sortByDeviceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceId', Sort.asc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> sortByDeviceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceId', Sort.desc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> sortByEndTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endTime', Sort.asc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> sortByEndTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endTime', Sort.desc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> sortByIsAllDay() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isAllDay', Sort.asc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> sortByIsAllDayDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isAllDay', Sort.desc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy>
      sortByNotificationPreferenceMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notificationPreferenceMinutes', Sort.asc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy>
      sortByNotificationPreferenceMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notificationPreferenceMinutes', Sort.desc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> sortByPriority() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priority', Sort.asc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> sortByPriorityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priority', Sort.desc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> sortBySyncId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncId', Sort.asc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> sortBySyncIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncId', Sort.desc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> sortBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.asc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> sortBySyncStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.desc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> sortByTargetDateTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetDateTime', Sort.asc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> sortByTargetDateTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetDateTime', Sort.desc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> sortByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.asc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> sortByVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.desc);
    });
  }
}

extension ReminderQuerySortThenBy
    on QueryBuilder<Reminder, Reminder, QSortThenBy> {
  QueryBuilder<Reminder, Reminder, QAfterSortBy> thenByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> thenByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> thenByCustomCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customCategory', Sort.asc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> thenByCustomCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customCategory', Sort.desc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> thenByCustomSound() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customSound', Sort.asc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> thenByCustomSoundDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customSound', Sort.desc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> thenByDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deleted', Sort.asc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> thenByDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deleted', Sort.desc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> thenByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.asc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> thenByDeletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.desc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> thenByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> thenByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> thenByDeviceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceId', Sort.asc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> thenByDeviceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceId', Sort.desc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> thenByEndTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endTime', Sort.asc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> thenByEndTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endTime', Sort.desc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> thenByIsAllDay() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isAllDay', Sort.asc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> thenByIsAllDayDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isAllDay', Sort.desc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy>
      thenByNotificationPreferenceMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notificationPreferenceMinutes', Sort.asc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy>
      thenByNotificationPreferenceMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notificationPreferenceMinutes', Sort.desc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> thenByPriority() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priority', Sort.asc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> thenByPriorityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priority', Sort.desc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> thenBySyncId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncId', Sort.asc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> thenBySyncIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncId', Sort.desc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> thenBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.asc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> thenBySyncStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.desc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> thenByTargetDateTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetDateTime', Sort.asc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> thenByTargetDateTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetDateTime', Sort.desc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> thenByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.asc);
    });
  }

  QueryBuilder<Reminder, Reminder, QAfterSortBy> thenByVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.desc);
    });
  }
}

extension ReminderQueryWhereDistinct
    on QueryBuilder<Reminder, Reminder, QDistinct> {
  QueryBuilder<Reminder, Reminder, QDistinct> distinctByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'category');
    });
  }

  QueryBuilder<Reminder, Reminder, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<Reminder, Reminder, QDistinct> distinctByCustomCategory(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'customCategory',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Reminder, Reminder, QDistinct> distinctByCustomSound(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'customSound', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Reminder, Reminder, QDistinct> distinctByDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deleted');
    });
  }

  QueryBuilder<Reminder, Reminder, QDistinct> distinctByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deletedAt');
    });
  }

  QueryBuilder<Reminder, Reminder, QDistinct> distinctByDescription(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'description', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Reminder, Reminder, QDistinct> distinctByDeviceId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deviceId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Reminder, Reminder, QDistinct> distinctByEndTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'endTime');
    });
  }

  QueryBuilder<Reminder, Reminder, QDistinct> distinctByIsAllDay() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isAllDay');
    });
  }

  QueryBuilder<Reminder, Reminder, QDistinct>
      distinctByNotificationPreferenceMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notificationPreferenceMinutes');
    });
  }

  QueryBuilder<Reminder, Reminder, QDistinct> distinctByPriority() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'priority');
    });
  }

  QueryBuilder<Reminder, Reminder, QDistinct> distinctByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status');
    });
  }

  QueryBuilder<Reminder, Reminder, QDistinct> distinctBySyncId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Reminder, Reminder, QDistinct> distinctBySyncStatus(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncStatus', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Reminder, Reminder, QDistinct> distinctByTargetDateTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'targetDateTime');
    });
  }

  QueryBuilder<Reminder, Reminder, QDistinct> distinctByTitle(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Reminder, Reminder, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<Reminder, Reminder, QDistinct> distinctByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'version');
    });
  }
}

extension ReminderQueryProperty
    on QueryBuilder<Reminder, Reminder, QQueryProperty> {
  QueryBuilder<Reminder, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Reminder, ReminderCategory, QQueryOperations>
      categoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'category');
    });
  }

  QueryBuilder<Reminder, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<Reminder, String?, QQueryOperations> customCategoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'customCategory');
    });
  }

  QueryBuilder<Reminder, String?, QQueryOperations> customSoundProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'customSound');
    });
  }

  QueryBuilder<Reminder, bool, QQueryOperations> deletedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deleted');
    });
  }

  QueryBuilder<Reminder, DateTime?, QQueryOperations> deletedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deletedAt');
    });
  }

  QueryBuilder<Reminder, String?, QQueryOperations> descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'description');
    });
  }

  QueryBuilder<Reminder, String, QQueryOperations> deviceIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deviceId');
    });
  }

  QueryBuilder<Reminder, DateTime?, QQueryOperations> endTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'endTime');
    });
  }

  QueryBuilder<Reminder, bool, QQueryOperations> isAllDayProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isAllDay');
    });
  }

  QueryBuilder<Reminder, int, QQueryOperations>
      notificationPreferenceMinutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notificationPreferenceMinutes');
    });
  }

  QueryBuilder<Reminder, PriorityLevel, QQueryOperations> priorityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'priority');
    });
  }

  QueryBuilder<Reminder, ReminderStatus, QQueryOperations> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<Reminder, String, QQueryOperations> syncIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncId');
    });
  }

  QueryBuilder<Reminder, String, QQueryOperations> syncStatusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncStatus');
    });
  }

  QueryBuilder<Reminder, DateTime, QQueryOperations> targetDateTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'targetDateTime');
    });
  }

  QueryBuilder<Reminder, String, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }

  QueryBuilder<Reminder, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<Reminder, int, QQueryOperations> versionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'version');
    });
  }
}
