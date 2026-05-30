// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $LifeEntitiesTable extends LifeEntities
    with TableInfo<$LifeEntitiesTable, LifeEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LifeEntitiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<int> syncedAt = GeneratedColumn<int>(
      'synced_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _isDeletedMeta =
      const VerificationMeta('isDeleted');
  @override
  late final GeneratedColumn<int> isDeleted = GeneratedColumn<int>(
      'is_deleted', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns =>
      [id, title, description, createdAt, updatedAt, syncedAt, isDeleted];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'life_entities';
  @override
  VerificationContext validateIntegrity(Insertable<LifeEntity> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    }
    if (data.containsKey('is_deleted')) {
      context.handle(_isDeletedMeta,
          isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LifeEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LifeEntity(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}synced_at']),
      isDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}is_deleted'])!,
    );
  }

  @override
  $LifeEntitiesTable createAlias(String alias) {
    return $LifeEntitiesTable(attachedDatabase, alias);
  }
}

class LifeEntity extends DataClass implements Insertable<LifeEntity> {
  final String id;
  final String title;
  final String? description;
  final int createdAt;
  final int updatedAt;
  final int? syncedAt;
  final int isDeleted;
  const LifeEntity(
      {required this.id,
      required this.title,
      this.description,
      required this.createdAt,
      required this.updatedAt,
      this.syncedAt,
      required this.isDeleted});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<int>(syncedAt);
    }
    map['is_deleted'] = Variable<int>(isDeleted);
    return map;
  }

  LifeEntitiesCompanion toCompanion(bool nullToAbsent) {
    return LifeEntitiesCompanion(
      id: Value(id),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      isDeleted: Value(isDeleted),
    );
  }

  factory LifeEntity.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LifeEntity(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      syncedAt: serializer.fromJson<int?>(json['syncedAt']),
      isDeleted: serializer.fromJson<int>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'syncedAt': serializer.toJson<int?>(syncedAt),
      'isDeleted': serializer.toJson<int>(isDeleted),
    };
  }

  LifeEntity copyWith(
          {String? id,
          String? title,
          Value<String?> description = const Value.absent(),
          int? createdAt,
          int? updatedAt,
          Value<int?> syncedAt = const Value.absent(),
          int? isDeleted}) =>
      LifeEntity(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description.present ? description.value : this.description,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
        isDeleted: isDeleted ?? this.isDeleted,
      );
  LifeEntity copyWithCompanion(LifeEntitiesCompanion data) {
    return LifeEntity(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description:
          data.description.present ? data.description.value : this.description,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LifeEntity(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, title, description, createdAt, updatedAt, syncedAt, isDeleted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LifeEntity &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncedAt == this.syncedAt &&
          other.isDeleted == this.isDeleted);
}

class LifeEntitiesCompanion extends UpdateCompanion<LifeEntity> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> description;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> syncedAt;
  final Value<int> isDeleted;
  final Value<int> rowid;
  const LifeEntitiesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LifeEntitiesCompanion.insert({
    required String id,
    required String title,
    this.description = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.syncedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        title = Value(title),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<LifeEntity> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? syncedAt,
    Expression<int>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LifeEntitiesCompanion copyWith(
      {Value<String>? id,
      Value<String>? title,
      Value<String?>? description,
      Value<int>? createdAt,
      Value<int>? updatedAt,
      Value<int?>? syncedAt,
      Value<int>? isDeleted,
      Value<int>? rowid}) {
    return LifeEntitiesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<int>(syncedAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<int>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LifeEntitiesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, SyncQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _targetTableMeta =
      const VerificationMeta('targetTable');
  @override
  late final GeneratedColumn<String> targetTable = GeneratedColumn<String>(
      'target_table', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _recordIdMeta =
      const VerificationMeta('recordId');
  @override
  late final GeneratedColumn<String> recordId = GeneratedColumn<String>(
      'record_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fieldNameMeta =
      const VerificationMeta('fieldName');
  @override
  late final GeneratedColumn<String> fieldName = GeneratedColumn<String>(
      'field_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _oldValueMeta =
      const VerificationMeta('oldValue');
  @override
  late final GeneratedColumn<String> oldValue = GeneratedColumn<String>(
      'old_value', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _newValueMeta =
      const VerificationMeta('newValue');
  @override
  late final GeneratedColumn<String> newValue = GeneratedColumn<String>(
      'new_value', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _clientUpdatedAtMeta =
      const VerificationMeta('clientUpdatedAt');
  @override
  late final GeneratedColumn<int> clientUpdatedAt = GeneratedColumn<int>(
      'client_updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _syncedStateMeta =
      const VerificationMeta('syncedState');
  @override
  late final GeneratedColumn<int> syncedState = GeneratedColumn<int>(
      'synced_state', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        targetTable,
        recordId,
        fieldName,
        oldValue,
        newValue,
        clientUpdatedAt,
        syncedState
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(Insertable<SyncQueueData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('target_table')) {
      context.handle(
          _targetTableMeta,
          targetTable.isAcceptableOrUnknown(
              data['target_table']!, _targetTableMeta));
    } else if (isInserting) {
      context.missing(_targetTableMeta);
    }
    if (data.containsKey('record_id')) {
      context.handle(_recordIdMeta,
          recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta));
    } else if (isInserting) {
      context.missing(_recordIdMeta);
    }
    if (data.containsKey('field_name')) {
      context.handle(_fieldNameMeta,
          fieldName.isAcceptableOrUnknown(data['field_name']!, _fieldNameMeta));
    } else if (isInserting) {
      context.missing(_fieldNameMeta);
    }
    if (data.containsKey('old_value')) {
      context.handle(_oldValueMeta,
          oldValue.isAcceptableOrUnknown(data['old_value']!, _oldValueMeta));
    }
    if (data.containsKey('new_value')) {
      context.handle(_newValueMeta,
          newValue.isAcceptableOrUnknown(data['new_value']!, _newValueMeta));
    }
    if (data.containsKey('client_updated_at')) {
      context.handle(
          _clientUpdatedAtMeta,
          clientUpdatedAt.isAcceptableOrUnknown(
              data['client_updated_at']!, _clientUpdatedAtMeta));
    } else if (isInserting) {
      context.missing(_clientUpdatedAtMeta);
    }
    if (data.containsKey('synced_state')) {
      context.handle(
          _syncedStateMeta,
          syncedState.isAcceptableOrUnknown(
              data['synced_state']!, _syncedStateMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      targetTable: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}target_table'])!,
      recordId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}record_id'])!,
      fieldName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}field_name'])!,
      oldValue: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}old_value']),
      newValue: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}new_value']),
      clientUpdatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}client_updated_at'])!,
      syncedState: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}synced_state'])!,
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }
}

class SyncQueueData extends DataClass implements Insertable<SyncQueueData> {
  final String id;
  final String targetTable;
  final String recordId;
  final String fieldName;
  final String? oldValue;
  final String? newValue;
  final int clientUpdatedAt;
  final int syncedState;
  const SyncQueueData(
      {required this.id,
      required this.targetTable,
      required this.recordId,
      required this.fieldName,
      this.oldValue,
      this.newValue,
      required this.clientUpdatedAt,
      required this.syncedState});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['target_table'] = Variable<String>(targetTable);
    map['record_id'] = Variable<String>(recordId);
    map['field_name'] = Variable<String>(fieldName);
    if (!nullToAbsent || oldValue != null) {
      map['old_value'] = Variable<String>(oldValue);
    }
    if (!nullToAbsent || newValue != null) {
      map['new_value'] = Variable<String>(newValue);
    }
    map['client_updated_at'] = Variable<int>(clientUpdatedAt);
    map['synced_state'] = Variable<int>(syncedState);
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      id: Value(id),
      targetTable: Value(targetTable),
      recordId: Value(recordId),
      fieldName: Value(fieldName),
      oldValue: oldValue == null && nullToAbsent
          ? const Value.absent()
          : Value(oldValue),
      newValue: newValue == null && nullToAbsent
          ? const Value.absent()
          : Value(newValue),
      clientUpdatedAt: Value(clientUpdatedAt),
      syncedState: Value(syncedState),
    );
  }

  factory SyncQueueData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueData(
      id: serializer.fromJson<String>(json['id']),
      targetTable: serializer.fromJson<String>(json['targetTable']),
      recordId: serializer.fromJson<String>(json['recordId']),
      fieldName: serializer.fromJson<String>(json['fieldName']),
      oldValue: serializer.fromJson<String?>(json['oldValue']),
      newValue: serializer.fromJson<String?>(json['newValue']),
      clientUpdatedAt: serializer.fromJson<int>(json['clientUpdatedAt']),
      syncedState: serializer.fromJson<int>(json['syncedState']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'targetTable': serializer.toJson<String>(targetTable),
      'recordId': serializer.toJson<String>(recordId),
      'fieldName': serializer.toJson<String>(fieldName),
      'oldValue': serializer.toJson<String?>(oldValue),
      'newValue': serializer.toJson<String?>(newValue),
      'clientUpdatedAt': serializer.toJson<int>(clientUpdatedAt),
      'syncedState': serializer.toJson<int>(syncedState),
    };
  }

  SyncQueueData copyWith(
          {String? id,
          String? targetTable,
          String? recordId,
          String? fieldName,
          Value<String?> oldValue = const Value.absent(),
          Value<String?> newValue = const Value.absent(),
          int? clientUpdatedAt,
          int? syncedState}) =>
      SyncQueueData(
        id: id ?? this.id,
        targetTable: targetTable ?? this.targetTable,
        recordId: recordId ?? this.recordId,
        fieldName: fieldName ?? this.fieldName,
        oldValue: oldValue.present ? oldValue.value : this.oldValue,
        newValue: newValue.present ? newValue.value : this.newValue,
        clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
        syncedState: syncedState ?? this.syncedState,
      );
  SyncQueueData copyWithCompanion(SyncQueueCompanion data) {
    return SyncQueueData(
      id: data.id.present ? data.id.value : this.id,
      targetTable:
          data.targetTable.present ? data.targetTable.value : this.targetTable,
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      fieldName: data.fieldName.present ? data.fieldName.value : this.fieldName,
      oldValue: data.oldValue.present ? data.oldValue.value : this.oldValue,
      newValue: data.newValue.present ? data.newValue.value : this.newValue,
      clientUpdatedAt: data.clientUpdatedAt.present
          ? data.clientUpdatedAt.value
          : this.clientUpdatedAt,
      syncedState:
          data.syncedState.present ? data.syncedState.value : this.syncedState,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueData(')
          ..write('id: $id, ')
          ..write('targetTable: $targetTable, ')
          ..write('recordId: $recordId, ')
          ..write('fieldName: $fieldName, ')
          ..write('oldValue: $oldValue, ')
          ..write('newValue: $newValue, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('syncedState: $syncedState')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, targetTable, recordId, fieldName,
      oldValue, newValue, clientUpdatedAt, syncedState);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueData &&
          other.id == this.id &&
          other.targetTable == this.targetTable &&
          other.recordId == this.recordId &&
          other.fieldName == this.fieldName &&
          other.oldValue == this.oldValue &&
          other.newValue == this.newValue &&
          other.clientUpdatedAt == this.clientUpdatedAt &&
          other.syncedState == this.syncedState);
}

class SyncQueueCompanion extends UpdateCompanion<SyncQueueData> {
  final Value<String> id;
  final Value<String> targetTable;
  final Value<String> recordId;
  final Value<String> fieldName;
  final Value<String?> oldValue;
  final Value<String?> newValue;
  final Value<int> clientUpdatedAt;
  final Value<int> syncedState;
  final Value<int> rowid;
  const SyncQueueCompanion({
    this.id = const Value.absent(),
    this.targetTable = const Value.absent(),
    this.recordId = const Value.absent(),
    this.fieldName = const Value.absent(),
    this.oldValue = const Value.absent(),
    this.newValue = const Value.absent(),
    this.clientUpdatedAt = const Value.absent(),
    this.syncedState = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    required String id,
    required String targetTable,
    required String recordId,
    required String fieldName,
    this.oldValue = const Value.absent(),
    this.newValue = const Value.absent(),
    required int clientUpdatedAt,
    this.syncedState = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        targetTable = Value(targetTable),
        recordId = Value(recordId),
        fieldName = Value(fieldName),
        clientUpdatedAt = Value(clientUpdatedAt);
  static Insertable<SyncQueueData> custom({
    Expression<String>? id,
    Expression<String>? targetTable,
    Expression<String>? recordId,
    Expression<String>? fieldName,
    Expression<String>? oldValue,
    Expression<String>? newValue,
    Expression<int>? clientUpdatedAt,
    Expression<int>? syncedState,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (targetTable != null) 'target_table': targetTable,
      if (recordId != null) 'record_id': recordId,
      if (fieldName != null) 'field_name': fieldName,
      if (oldValue != null) 'old_value': oldValue,
      if (newValue != null) 'new_value': newValue,
      if (clientUpdatedAt != null) 'client_updated_at': clientUpdatedAt,
      if (syncedState != null) 'synced_state': syncedState,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncQueueCompanion copyWith(
      {Value<String>? id,
      Value<String>? targetTable,
      Value<String>? recordId,
      Value<String>? fieldName,
      Value<String?>? oldValue,
      Value<String?>? newValue,
      Value<int>? clientUpdatedAt,
      Value<int>? syncedState,
      Value<int>? rowid}) {
    return SyncQueueCompanion(
      id: id ?? this.id,
      targetTable: targetTable ?? this.targetTable,
      recordId: recordId ?? this.recordId,
      fieldName: fieldName ?? this.fieldName,
      oldValue: oldValue ?? this.oldValue,
      newValue: newValue ?? this.newValue,
      clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
      syncedState: syncedState ?? this.syncedState,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (targetTable.present) {
      map['target_table'] = Variable<String>(targetTable.value);
    }
    if (recordId.present) {
      map['record_id'] = Variable<String>(recordId.value);
    }
    if (fieldName.present) {
      map['field_name'] = Variable<String>(fieldName.value);
    }
    if (oldValue.present) {
      map['old_value'] = Variable<String>(oldValue.value);
    }
    if (newValue.present) {
      map['new_value'] = Variable<String>(newValue.value);
    }
    if (clientUpdatedAt.present) {
      map['client_updated_at'] = Variable<int>(clientUpdatedAt.value);
    }
    if (syncedState.present) {
      map['synced_state'] = Variable<int>(syncedState.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('targetTable: $targetTable, ')
          ..write('recordId: $recordId, ')
          ..write('fieldName: $fieldName, ')
          ..write('oldValue: $oldValue, ')
          ..write('newValue: $newValue, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('syncedState: $syncedState, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LifeEntitiesTable lifeEntities = $LifeEntitiesTable(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  late final LifeEntitiesDao lifeEntitiesDao =
      LifeEntitiesDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [lifeEntities, syncQueue];
}

typedef $$LifeEntitiesTableCreateCompanionBuilder = LifeEntitiesCompanion
    Function({
  required String id,
  required String title,
  Value<String?> description,
  required int createdAt,
  required int updatedAt,
  Value<int?> syncedAt,
  Value<int> isDeleted,
  Value<int> rowid,
});
typedef $$LifeEntitiesTableUpdateCompanionBuilder = LifeEntitiesCompanion
    Function({
  Value<String> id,
  Value<String> title,
  Value<String?> description,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int?> syncedAt,
  Value<int> isDeleted,
  Value<int> rowid,
});

class $$LifeEntitiesTableFilterComposer
    extends Composer<_$AppDatabase, $LifeEntitiesTable> {
  $$LifeEntitiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnFilters(column));
}

class $$LifeEntitiesTableOrderingComposer
    extends Composer<_$AppDatabase, $LifeEntitiesTable> {
  $$LifeEntitiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnOrderings(column));
}

class $$LifeEntitiesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LifeEntitiesTable> {
  $$LifeEntitiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<int> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);
}

class $$LifeEntitiesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LifeEntitiesTable,
    LifeEntity,
    $$LifeEntitiesTableFilterComposer,
    $$LifeEntitiesTableOrderingComposer,
    $$LifeEntitiesTableAnnotationComposer,
    $$LifeEntitiesTableCreateCompanionBuilder,
    $$LifeEntitiesTableUpdateCompanionBuilder,
    (LifeEntity, BaseReferences<_$AppDatabase, $LifeEntitiesTable, LifeEntity>),
    LifeEntity,
    PrefetchHooks Function()> {
  $$LifeEntitiesTableTableManager(_$AppDatabase db, $LifeEntitiesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LifeEntitiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LifeEntitiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LifeEntitiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<int?> syncedAt = const Value.absent(),
            Value<int> isDeleted = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LifeEntitiesCompanion(
            id: id,
            title: title,
            description: description,
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncedAt: syncedAt,
            isDeleted: isDeleted,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String title,
            Value<String?> description = const Value.absent(),
            required int createdAt,
            required int updatedAt,
            Value<int?> syncedAt = const Value.absent(),
            Value<int> isDeleted = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LifeEntitiesCompanion.insert(
            id: id,
            title: title,
            description: description,
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncedAt: syncedAt,
            isDeleted: isDeleted,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LifeEntitiesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LifeEntitiesTable,
    LifeEntity,
    $$LifeEntitiesTableFilterComposer,
    $$LifeEntitiesTableOrderingComposer,
    $$LifeEntitiesTableAnnotationComposer,
    $$LifeEntitiesTableCreateCompanionBuilder,
    $$LifeEntitiesTableUpdateCompanionBuilder,
    (LifeEntity, BaseReferences<_$AppDatabase, $LifeEntitiesTable, LifeEntity>),
    LifeEntity,
    PrefetchHooks Function()>;
typedef $$SyncQueueTableCreateCompanionBuilder = SyncQueueCompanion Function({
  required String id,
  required String targetTable,
  required String recordId,
  required String fieldName,
  Value<String?> oldValue,
  Value<String?> newValue,
  required int clientUpdatedAt,
  Value<int> syncedState,
  Value<int> rowid,
});
typedef $$SyncQueueTableUpdateCompanionBuilder = SyncQueueCompanion Function({
  Value<String> id,
  Value<String> targetTable,
  Value<String> recordId,
  Value<String> fieldName,
  Value<String?> oldValue,
  Value<String?> newValue,
  Value<int> clientUpdatedAt,
  Value<int> syncedState,
  Value<int> rowid,
});

class $$SyncQueueTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get targetTable => $composableBuilder(
      column: $table.targetTable, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get recordId => $composableBuilder(
      column: $table.recordId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fieldName => $composableBuilder(
      column: $table.fieldName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get oldValue => $composableBuilder(
      column: $table.oldValue, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get newValue => $composableBuilder(
      column: $table.newValue, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get clientUpdatedAt => $composableBuilder(
      column: $table.clientUpdatedAt,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get syncedState => $composableBuilder(
      column: $table.syncedState, builder: (column) => ColumnFilters(column));
}

class $$SyncQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get targetTable => $composableBuilder(
      column: $table.targetTable, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get recordId => $composableBuilder(
      column: $table.recordId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fieldName => $composableBuilder(
      column: $table.fieldName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get oldValue => $composableBuilder(
      column: $table.oldValue, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get newValue => $composableBuilder(
      column: $table.newValue, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get clientUpdatedAt => $composableBuilder(
      column: $table.clientUpdatedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get syncedState => $composableBuilder(
      column: $table.syncedState, builder: (column) => ColumnOrderings(column));
}

class $$SyncQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get targetTable => $composableBuilder(
      column: $table.targetTable, builder: (column) => column);

  GeneratedColumn<String> get recordId =>
      $composableBuilder(column: $table.recordId, builder: (column) => column);

  GeneratedColumn<String> get fieldName =>
      $composableBuilder(column: $table.fieldName, builder: (column) => column);

  GeneratedColumn<String> get oldValue =>
      $composableBuilder(column: $table.oldValue, builder: (column) => column);

  GeneratedColumn<String> get newValue =>
      $composableBuilder(column: $table.newValue, builder: (column) => column);

  GeneratedColumn<int> get clientUpdatedAt => $composableBuilder(
      column: $table.clientUpdatedAt, builder: (column) => column);

  GeneratedColumn<int> get syncedState => $composableBuilder(
      column: $table.syncedState, builder: (column) => column);
}

class $$SyncQueueTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncQueueTable,
    SyncQueueData,
    $$SyncQueueTableFilterComposer,
    $$SyncQueueTableOrderingComposer,
    $$SyncQueueTableAnnotationComposer,
    $$SyncQueueTableCreateCompanionBuilder,
    $$SyncQueueTableUpdateCompanionBuilder,
    (
      SyncQueueData,
      BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>
    ),
    SyncQueueData,
    PrefetchHooks Function()> {
  $$SyncQueueTableTableManager(_$AppDatabase db, $SyncQueueTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> targetTable = const Value.absent(),
            Value<String> recordId = const Value.absent(),
            Value<String> fieldName = const Value.absent(),
            Value<String?> oldValue = const Value.absent(),
            Value<String?> newValue = const Value.absent(),
            Value<int> clientUpdatedAt = const Value.absent(),
            Value<int> syncedState = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncQueueCompanion(
            id: id,
            targetTable: targetTable,
            recordId: recordId,
            fieldName: fieldName,
            oldValue: oldValue,
            newValue: newValue,
            clientUpdatedAt: clientUpdatedAt,
            syncedState: syncedState,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String targetTable,
            required String recordId,
            required String fieldName,
            Value<String?> oldValue = const Value.absent(),
            Value<String?> newValue = const Value.absent(),
            required int clientUpdatedAt,
            Value<int> syncedState = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncQueueCompanion.insert(
            id: id,
            targetTable: targetTable,
            recordId: recordId,
            fieldName: fieldName,
            oldValue: oldValue,
            newValue: newValue,
            clientUpdatedAt: clientUpdatedAt,
            syncedState: syncedState,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncQueueTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SyncQueueTable,
    SyncQueueData,
    $$SyncQueueTableFilterComposer,
    $$SyncQueueTableOrderingComposer,
    $$SyncQueueTableAnnotationComposer,
    $$SyncQueueTableCreateCompanionBuilder,
    $$SyncQueueTableUpdateCompanionBuilder,
    (
      SyncQueueData,
      BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>
    ),
    SyncQueueData,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LifeEntitiesTableTableManager get lifeEntities =>
      $$LifeEntitiesTableTableManager(_db, _db.lifeEntities);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
}
