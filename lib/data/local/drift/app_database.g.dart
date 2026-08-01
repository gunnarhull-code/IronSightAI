// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $InspectionsTable extends Inspections
    with TableInfo<$InspectionsTable, LocalInspectionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InspectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _companyIdMeta = const VerificationMeta(
    'companyId',
  );
  @override
  late final GeneratedColumn<String> companyId = GeneratedColumn<String>(
    'company_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _equipmentIdMeta = const VerificationMeta(
    'equipmentId',
  );
  @override
  late final GeneratedColumn<String> equipmentId = GeneratedColumn<String>(
    'equipment_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdByUserIdMeta = const VerificationMeta(
    'createdByUserId',
  );
  @override
  late final GeneratedColumn<String> createdByUserId = GeneratedColumn<String>(
    'created_by_user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedByUserIdMeta = const VerificationMeta(
    'updatedByUserId',
  );
  @override
  late final GeneratedColumn<String> updatedByUserId = GeneratedColumn<String>(
    'updated_by_user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completionStatusMeta = const VerificationMeta(
    'completionStatus',
  );
  @override
  late final GeneratedColumn<String> completionStatus = GeneratedColumn<String>(
    'completion_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localLifecycleMeta = const VerificationMeta(
    'localLifecycle',
  );
  @override
  late final GeneratedColumn<String> localLifecycle = GeneratedColumn<String>(
    'local_lifecycle',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _depthMeta = const VerificationMeta('depth');
  @override
  late final GeneratedColumn<String> depth = GeneratedColumn<String>(
    'depth',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reportStatusMeta = const VerificationMeta(
    'reportStatus',
  );
  @override
  late final GeneratedColumn<String> reportStatus = GeneratedColumn<String>(
    'report_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _overallNotesMeta = const VerificationMeta(
    'overallNotes',
  );
  @override
  late final GeneratedColumn<String> overallNotes = GeneratedColumn<String>(
    'overall_notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localUpdatedAtMeta = const VerificationMeta(
    'localUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> localUpdatedAt =
      GeneratedColumn<DateTime>(
        'local_updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _discardedAtMeta = const VerificationMeta(
    'discardedAt',
  );
  @override
  late final GeneratedColumn<DateTime> discardedAt = GeneratedColumn<DateTime>(
    'discarded_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    companyId,
    equipmentId,
    createdByUserId,
    updatedByUserId,
    completionStatus,
    localLifecycle,
    depth,
    syncStatus,
    reportStatus,
    remoteId,
    overallNotes,
    createdAt,
    updatedAt,
    localUpdatedAt,
    completedAt,
    discardedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inspections';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalInspectionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('company_id')) {
      context.handle(
        _companyIdMeta,
        companyId.isAcceptableOrUnknown(data['company_id']!, _companyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_companyIdMeta);
    }
    if (data.containsKey('equipment_id')) {
      context.handle(
        _equipmentIdMeta,
        equipmentId.isAcceptableOrUnknown(
          data['equipment_id']!,
          _equipmentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_equipmentIdMeta);
    }
    if (data.containsKey('created_by_user_id')) {
      context.handle(
        _createdByUserIdMeta,
        createdByUserId.isAcceptableOrUnknown(
          data['created_by_user_id']!,
          _createdByUserIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdByUserIdMeta);
    }
    if (data.containsKey('updated_by_user_id')) {
      context.handle(
        _updatedByUserIdMeta,
        updatedByUserId.isAcceptableOrUnknown(
          data['updated_by_user_id']!,
          _updatedByUserIdMeta,
        ),
      );
    }
    if (data.containsKey('completion_status')) {
      context.handle(
        _completionStatusMeta,
        completionStatus.isAcceptableOrUnknown(
          data['completion_status']!,
          _completionStatusMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completionStatusMeta);
    }
    if (data.containsKey('local_lifecycle')) {
      context.handle(
        _localLifecycleMeta,
        localLifecycle.isAcceptableOrUnknown(
          data['local_lifecycle']!,
          _localLifecycleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localLifecycleMeta);
    }
    if (data.containsKey('depth')) {
      context.handle(
        _depthMeta,
        depth.isAcceptableOrUnknown(data['depth']!, _depthMeta),
      );
    } else if (isInserting) {
      context.missing(_depthMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    } else if (isInserting) {
      context.missing(_syncStatusMeta);
    }
    if (data.containsKey('report_status')) {
      context.handle(
        _reportStatusMeta,
        reportStatus.isAcceptableOrUnknown(
          data['report_status']!,
          _reportStatusMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_reportStatusMeta);
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('overall_notes')) {
      context.handle(
        _overallNotesMeta,
        overallNotes.isAcceptableOrUnknown(
          data['overall_notes']!,
          _overallNotesMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('local_updated_at')) {
      context.handle(
        _localUpdatedAtMeta,
        localUpdatedAt.isAcceptableOrUnknown(
          data['local_updated_at']!,
          _localUpdatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localUpdatedAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('discarded_at')) {
      context.handle(
        _discardedAtMeta,
        discardedAt.isAcceptableOrUnknown(
          data['discarded_at']!,
          _discardedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalInspectionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalInspectionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      companyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_id'],
      )!,
      equipmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}equipment_id'],
      )!,
      createdByUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by_user_id'],
      )!,
      updatedByUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by_user_id'],
      ),
      completionStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}completion_status'],
      )!,
      localLifecycle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_lifecycle'],
      )!,
      depth: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}depth'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      reportStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}report_status'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
      overallNotes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}overall_notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      localUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}local_updated_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      discardedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}discarded_at'],
      ),
    );
  }

  @override
  $InspectionsTable createAlias(String alias) {
    return $InspectionsTable(attachedDatabase, alias);
  }
}

class LocalInspectionRow extends DataClass
    implements Insertable<LocalInspectionRow> {
  final String id;
  final String companyId;
  final String equipmentId;
  final String createdByUserId;
  final String? updatedByUserId;
  final String completionStatus;
  final String localLifecycle;
  final String depth;
  final String syncStatus;
  final String reportStatus;
  final String? remoteId;
  final String? overallNotes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime localUpdatedAt;
  final DateTime? completedAt;
  final DateTime? discardedAt;
  const LocalInspectionRow({
    required this.id,
    required this.companyId,
    required this.equipmentId,
    required this.createdByUserId,
    this.updatedByUserId,
    required this.completionStatus,
    required this.localLifecycle,
    required this.depth,
    required this.syncStatus,
    required this.reportStatus,
    this.remoteId,
    this.overallNotes,
    required this.createdAt,
    required this.updatedAt,
    required this.localUpdatedAt,
    this.completedAt,
    this.discardedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['company_id'] = Variable<String>(companyId);
    map['equipment_id'] = Variable<String>(equipmentId);
    map['created_by_user_id'] = Variable<String>(createdByUserId);
    if (!nullToAbsent || updatedByUserId != null) {
      map['updated_by_user_id'] = Variable<String>(updatedByUserId);
    }
    map['completion_status'] = Variable<String>(completionStatus);
    map['local_lifecycle'] = Variable<String>(localLifecycle);
    map['depth'] = Variable<String>(depth);
    map['sync_status'] = Variable<String>(syncStatus);
    map['report_status'] = Variable<String>(reportStatus);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    if (!nullToAbsent || overallNotes != null) {
      map['overall_notes'] = Variable<String>(overallNotes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['local_updated_at'] = Variable<DateTime>(localUpdatedAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    if (!nullToAbsent || discardedAt != null) {
      map['discarded_at'] = Variable<DateTime>(discardedAt);
    }
    return map;
  }

  InspectionsCompanion toCompanion(bool nullToAbsent) {
    return InspectionsCompanion(
      id: Value(id),
      companyId: Value(companyId),
      equipmentId: Value(equipmentId),
      createdByUserId: Value(createdByUserId),
      updatedByUserId: updatedByUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedByUserId),
      completionStatus: Value(completionStatus),
      localLifecycle: Value(localLifecycle),
      depth: Value(depth),
      syncStatus: Value(syncStatus),
      reportStatus: Value(reportStatus),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      overallNotes: overallNotes == null && nullToAbsent
          ? const Value.absent()
          : Value(overallNotes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      localUpdatedAt: Value(localUpdatedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      discardedAt: discardedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(discardedAt),
    );
  }

  factory LocalInspectionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalInspectionRow(
      id: serializer.fromJson<String>(json['id']),
      companyId: serializer.fromJson<String>(json['companyId']),
      equipmentId: serializer.fromJson<String>(json['equipmentId']),
      createdByUserId: serializer.fromJson<String>(json['createdByUserId']),
      updatedByUserId: serializer.fromJson<String?>(json['updatedByUserId']),
      completionStatus: serializer.fromJson<String>(json['completionStatus']),
      localLifecycle: serializer.fromJson<String>(json['localLifecycle']),
      depth: serializer.fromJson<String>(json['depth']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      reportStatus: serializer.fromJson<String>(json['reportStatus']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      overallNotes: serializer.fromJson<String?>(json['overallNotes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      localUpdatedAt: serializer.fromJson<DateTime>(json['localUpdatedAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      discardedAt: serializer.fromJson<DateTime?>(json['discardedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'companyId': serializer.toJson<String>(companyId),
      'equipmentId': serializer.toJson<String>(equipmentId),
      'createdByUserId': serializer.toJson<String>(createdByUserId),
      'updatedByUserId': serializer.toJson<String?>(updatedByUserId),
      'completionStatus': serializer.toJson<String>(completionStatus),
      'localLifecycle': serializer.toJson<String>(localLifecycle),
      'depth': serializer.toJson<String>(depth),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'reportStatus': serializer.toJson<String>(reportStatus),
      'remoteId': serializer.toJson<String?>(remoteId),
      'overallNotes': serializer.toJson<String?>(overallNotes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'localUpdatedAt': serializer.toJson<DateTime>(localUpdatedAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'discardedAt': serializer.toJson<DateTime?>(discardedAt),
    };
  }

  LocalInspectionRow copyWith({
    String? id,
    String? companyId,
    String? equipmentId,
    String? createdByUserId,
    Value<String?> updatedByUserId = const Value.absent(),
    String? completionStatus,
    String? localLifecycle,
    String? depth,
    String? syncStatus,
    String? reportStatus,
    Value<String?> remoteId = const Value.absent(),
    Value<String?> overallNotes = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? localUpdatedAt,
    Value<DateTime?> completedAt = const Value.absent(),
    Value<DateTime?> discardedAt = const Value.absent(),
  }) => LocalInspectionRow(
    id: id ?? this.id,
    companyId: companyId ?? this.companyId,
    equipmentId: equipmentId ?? this.equipmentId,
    createdByUserId: createdByUserId ?? this.createdByUserId,
    updatedByUserId: updatedByUserId.present
        ? updatedByUserId.value
        : this.updatedByUserId,
    completionStatus: completionStatus ?? this.completionStatus,
    localLifecycle: localLifecycle ?? this.localLifecycle,
    depth: depth ?? this.depth,
    syncStatus: syncStatus ?? this.syncStatus,
    reportStatus: reportStatus ?? this.reportStatus,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    overallNotes: overallNotes.present ? overallNotes.value : this.overallNotes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    discardedAt: discardedAt.present ? discardedAt.value : this.discardedAt,
  );
  LocalInspectionRow copyWithCompanion(InspectionsCompanion data) {
    return LocalInspectionRow(
      id: data.id.present ? data.id.value : this.id,
      companyId: data.companyId.present ? data.companyId.value : this.companyId,
      equipmentId: data.equipmentId.present
          ? data.equipmentId.value
          : this.equipmentId,
      createdByUserId: data.createdByUserId.present
          ? data.createdByUserId.value
          : this.createdByUserId,
      updatedByUserId: data.updatedByUserId.present
          ? data.updatedByUserId.value
          : this.updatedByUserId,
      completionStatus: data.completionStatus.present
          ? data.completionStatus.value
          : this.completionStatus,
      localLifecycle: data.localLifecycle.present
          ? data.localLifecycle.value
          : this.localLifecycle,
      depth: data.depth.present ? data.depth.value : this.depth,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      reportStatus: data.reportStatus.present
          ? data.reportStatus.value
          : this.reportStatus,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      overallNotes: data.overallNotes.present
          ? data.overallNotes.value
          : this.overallNotes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      localUpdatedAt: data.localUpdatedAt.present
          ? data.localUpdatedAt.value
          : this.localUpdatedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      discardedAt: data.discardedAt.present
          ? data.discardedAt.value
          : this.discardedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalInspectionRow(')
          ..write('id: $id, ')
          ..write('companyId: $companyId, ')
          ..write('equipmentId: $equipmentId, ')
          ..write('createdByUserId: $createdByUserId, ')
          ..write('updatedByUserId: $updatedByUserId, ')
          ..write('completionStatus: $completionStatus, ')
          ..write('localLifecycle: $localLifecycle, ')
          ..write('depth: $depth, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('reportStatus: $reportStatus, ')
          ..write('remoteId: $remoteId, ')
          ..write('overallNotes: $overallNotes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('localUpdatedAt: $localUpdatedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('discardedAt: $discardedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    companyId,
    equipmentId,
    createdByUserId,
    updatedByUserId,
    completionStatus,
    localLifecycle,
    depth,
    syncStatus,
    reportStatus,
    remoteId,
    overallNotes,
    createdAt,
    updatedAt,
    localUpdatedAt,
    completedAt,
    discardedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalInspectionRow &&
          other.id == this.id &&
          other.companyId == this.companyId &&
          other.equipmentId == this.equipmentId &&
          other.createdByUserId == this.createdByUserId &&
          other.updatedByUserId == this.updatedByUserId &&
          other.completionStatus == this.completionStatus &&
          other.localLifecycle == this.localLifecycle &&
          other.depth == this.depth &&
          other.syncStatus == this.syncStatus &&
          other.reportStatus == this.reportStatus &&
          other.remoteId == this.remoteId &&
          other.overallNotes == this.overallNotes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.localUpdatedAt == this.localUpdatedAt &&
          other.completedAt == this.completedAt &&
          other.discardedAt == this.discardedAt);
}

class InspectionsCompanion extends UpdateCompanion<LocalInspectionRow> {
  final Value<String> id;
  final Value<String> companyId;
  final Value<String> equipmentId;
  final Value<String> createdByUserId;
  final Value<String?> updatedByUserId;
  final Value<String> completionStatus;
  final Value<String> localLifecycle;
  final Value<String> depth;
  final Value<String> syncStatus;
  final Value<String> reportStatus;
  final Value<String?> remoteId;
  final Value<String?> overallNotes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime> localUpdatedAt;
  final Value<DateTime?> completedAt;
  final Value<DateTime?> discardedAt;
  final Value<int> rowid;
  const InspectionsCompanion({
    this.id = const Value.absent(),
    this.companyId = const Value.absent(),
    this.equipmentId = const Value.absent(),
    this.createdByUserId = const Value.absent(),
    this.updatedByUserId = const Value.absent(),
    this.completionStatus = const Value.absent(),
    this.localLifecycle = const Value.absent(),
    this.depth = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.reportStatus = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.overallNotes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.localUpdatedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.discardedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InspectionsCompanion.insert({
    required String id,
    required String companyId,
    required String equipmentId,
    required String createdByUserId,
    this.updatedByUserId = const Value.absent(),
    required String completionStatus,
    required String localLifecycle,
    required String depth,
    required String syncStatus,
    required String reportStatus,
    this.remoteId = const Value.absent(),
    this.overallNotes = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    required DateTime localUpdatedAt,
    this.completedAt = const Value.absent(),
    this.discardedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       companyId = Value(companyId),
       equipmentId = Value(equipmentId),
       createdByUserId = Value(createdByUserId),
       completionStatus = Value(completionStatus),
       localLifecycle = Value(localLifecycle),
       depth = Value(depth),
       syncStatus = Value(syncStatus),
       reportStatus = Value(reportStatus),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       localUpdatedAt = Value(localUpdatedAt);
  static Insertable<LocalInspectionRow> custom({
    Expression<String>? id,
    Expression<String>? companyId,
    Expression<String>? equipmentId,
    Expression<String>? createdByUserId,
    Expression<String>? updatedByUserId,
    Expression<String>? completionStatus,
    Expression<String>? localLifecycle,
    Expression<String>? depth,
    Expression<String>? syncStatus,
    Expression<String>? reportStatus,
    Expression<String>? remoteId,
    Expression<String>? overallNotes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? localUpdatedAt,
    Expression<DateTime>? completedAt,
    Expression<DateTime>? discardedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (companyId != null) 'company_id': companyId,
      if (equipmentId != null) 'equipment_id': equipmentId,
      if (createdByUserId != null) 'created_by_user_id': createdByUserId,
      if (updatedByUserId != null) 'updated_by_user_id': updatedByUserId,
      if (completionStatus != null) 'completion_status': completionStatus,
      if (localLifecycle != null) 'local_lifecycle': localLifecycle,
      if (depth != null) 'depth': depth,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (reportStatus != null) 'report_status': reportStatus,
      if (remoteId != null) 'remote_id': remoteId,
      if (overallNotes != null) 'overall_notes': overallNotes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (localUpdatedAt != null) 'local_updated_at': localUpdatedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (discardedAt != null) 'discarded_at': discardedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InspectionsCompanion copyWith({
    Value<String>? id,
    Value<String>? companyId,
    Value<String>? equipmentId,
    Value<String>? createdByUserId,
    Value<String?>? updatedByUserId,
    Value<String>? completionStatus,
    Value<String>? localLifecycle,
    Value<String>? depth,
    Value<String>? syncStatus,
    Value<String>? reportStatus,
    Value<String?>? remoteId,
    Value<String?>? overallNotes,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime>? localUpdatedAt,
    Value<DateTime?>? completedAt,
    Value<DateTime?>? discardedAt,
    Value<int>? rowid,
  }) {
    return InspectionsCompanion(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      equipmentId: equipmentId ?? this.equipmentId,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      updatedByUserId: updatedByUserId ?? this.updatedByUserId,
      completionStatus: completionStatus ?? this.completionStatus,
      localLifecycle: localLifecycle ?? this.localLifecycle,
      depth: depth ?? this.depth,
      syncStatus: syncStatus ?? this.syncStatus,
      reportStatus: reportStatus ?? this.reportStatus,
      remoteId: remoteId ?? this.remoteId,
      overallNotes: overallNotes ?? this.overallNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
      completedAt: completedAt ?? this.completedAt,
      discardedAt: discardedAt ?? this.discardedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (companyId.present) {
      map['company_id'] = Variable<String>(companyId.value);
    }
    if (equipmentId.present) {
      map['equipment_id'] = Variable<String>(equipmentId.value);
    }
    if (createdByUserId.present) {
      map['created_by_user_id'] = Variable<String>(createdByUserId.value);
    }
    if (updatedByUserId.present) {
      map['updated_by_user_id'] = Variable<String>(updatedByUserId.value);
    }
    if (completionStatus.present) {
      map['completion_status'] = Variable<String>(completionStatus.value);
    }
    if (localLifecycle.present) {
      map['local_lifecycle'] = Variable<String>(localLifecycle.value);
    }
    if (depth.present) {
      map['depth'] = Variable<String>(depth.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (reportStatus.present) {
      map['report_status'] = Variable<String>(reportStatus.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (overallNotes.present) {
      map['overall_notes'] = Variable<String>(overallNotes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (localUpdatedAt.present) {
      map['local_updated_at'] = Variable<DateTime>(localUpdatedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (discardedAt.present) {
      map['discarded_at'] = Variable<DateTime>(discardedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InspectionsCompanion(')
          ..write('id: $id, ')
          ..write('companyId: $companyId, ')
          ..write('equipmentId: $equipmentId, ')
          ..write('createdByUserId: $createdByUserId, ')
          ..write('updatedByUserId: $updatedByUserId, ')
          ..write('completionStatus: $completionStatus, ')
          ..write('localLifecycle: $localLifecycle, ')
          ..write('depth: $depth, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('reportStatus: $reportStatus, ')
          ..write('remoteId: $remoteId, ')
          ..write('overallNotes: $overallNotes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('localUpdatedAt: $localUpdatedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('discardedAt: $discardedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InspectionCategoryRatingsTable extends InspectionCategoryRatings
    with TableInfo<$InspectionCategoryRatingsTable, LocalCategoryRatingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InspectionCategoryRatingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inspectionIdMeta = const VerificationMeta(
    'inspectionId',
  );
  @override
  late final GeneratedColumn<String> inspectionId = GeneratedColumn<String>(
    'inspection_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES inspections (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _companyIdMeta = const VerificationMeta(
    'companyId',
  );
  @override
  late final GeneratedColumn<String> companyId = GeneratedColumn<String>(
    'company_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<String> rating = GeneratedColumn<String>(
    'rating',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    inspectionId,
    companyId,
    category,
    rating,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inspection_category_ratings';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalCategoryRatingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('inspection_id')) {
      context.handle(
        _inspectionIdMeta,
        inspectionId.isAcceptableOrUnknown(
          data['inspection_id']!,
          _inspectionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_inspectionIdMeta);
    }
    if (data.containsKey('company_id')) {
      context.handle(
        _companyIdMeta,
        companyId.isAcceptableOrUnknown(data['company_id']!, _companyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_companyIdMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    } else if (isInserting) {
      context.missing(_ratingMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {inspectionId, category},
  ];
  @override
  LocalCategoryRatingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalCategoryRatingRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      inspectionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}inspection_id'],
      )!,
      companyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_id'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rating'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $InspectionCategoryRatingsTable createAlias(String alias) {
    return $InspectionCategoryRatingsTable(attachedDatabase, alias);
  }
}

class LocalCategoryRatingRow extends DataClass
    implements Insertable<LocalCategoryRatingRow> {
  final String id;
  final String inspectionId;
  final String companyId;
  final String category;
  final String rating;
  final DateTime updatedAt;
  const LocalCategoryRatingRow({
    required this.id,
    required this.inspectionId,
    required this.companyId,
    required this.category,
    required this.rating,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['inspection_id'] = Variable<String>(inspectionId);
    map['company_id'] = Variable<String>(companyId);
    map['category'] = Variable<String>(category);
    map['rating'] = Variable<String>(rating);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  InspectionCategoryRatingsCompanion toCompanion(bool nullToAbsent) {
    return InspectionCategoryRatingsCompanion(
      id: Value(id),
      inspectionId: Value(inspectionId),
      companyId: Value(companyId),
      category: Value(category),
      rating: Value(rating),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalCategoryRatingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalCategoryRatingRow(
      id: serializer.fromJson<String>(json['id']),
      inspectionId: serializer.fromJson<String>(json['inspectionId']),
      companyId: serializer.fromJson<String>(json['companyId']),
      category: serializer.fromJson<String>(json['category']),
      rating: serializer.fromJson<String>(json['rating']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'inspectionId': serializer.toJson<String>(inspectionId),
      'companyId': serializer.toJson<String>(companyId),
      'category': serializer.toJson<String>(category),
      'rating': serializer.toJson<String>(rating),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalCategoryRatingRow copyWith({
    String? id,
    String? inspectionId,
    String? companyId,
    String? category,
    String? rating,
    DateTime? updatedAt,
  }) => LocalCategoryRatingRow(
    id: id ?? this.id,
    inspectionId: inspectionId ?? this.inspectionId,
    companyId: companyId ?? this.companyId,
    category: category ?? this.category,
    rating: rating ?? this.rating,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalCategoryRatingRow copyWithCompanion(
    InspectionCategoryRatingsCompanion data,
  ) {
    return LocalCategoryRatingRow(
      id: data.id.present ? data.id.value : this.id,
      inspectionId: data.inspectionId.present
          ? data.inspectionId.value
          : this.inspectionId,
      companyId: data.companyId.present ? data.companyId.value : this.companyId,
      category: data.category.present ? data.category.value : this.category,
      rating: data.rating.present ? data.rating.value : this.rating,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalCategoryRatingRow(')
          ..write('id: $id, ')
          ..write('inspectionId: $inspectionId, ')
          ..write('companyId: $companyId, ')
          ..write('category: $category, ')
          ..write('rating: $rating, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, inspectionId, companyId, category, rating, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalCategoryRatingRow &&
          other.id == this.id &&
          other.inspectionId == this.inspectionId &&
          other.companyId == this.companyId &&
          other.category == this.category &&
          other.rating == this.rating &&
          other.updatedAt == this.updatedAt);
}

class InspectionCategoryRatingsCompanion
    extends UpdateCompanion<LocalCategoryRatingRow> {
  final Value<String> id;
  final Value<String> inspectionId;
  final Value<String> companyId;
  final Value<String> category;
  final Value<String> rating;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const InspectionCategoryRatingsCompanion({
    this.id = const Value.absent(),
    this.inspectionId = const Value.absent(),
    this.companyId = const Value.absent(),
    this.category = const Value.absent(),
    this.rating = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InspectionCategoryRatingsCompanion.insert({
    required String id,
    required String inspectionId,
    required String companyId,
    required String category,
    required String rating,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       inspectionId = Value(inspectionId),
       companyId = Value(companyId),
       category = Value(category),
       rating = Value(rating),
       updatedAt = Value(updatedAt);
  static Insertable<LocalCategoryRatingRow> custom({
    Expression<String>? id,
    Expression<String>? inspectionId,
    Expression<String>? companyId,
    Expression<String>? category,
    Expression<String>? rating,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (inspectionId != null) 'inspection_id': inspectionId,
      if (companyId != null) 'company_id': companyId,
      if (category != null) 'category': category,
      if (rating != null) 'rating': rating,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InspectionCategoryRatingsCompanion copyWith({
    Value<String>? id,
    Value<String>? inspectionId,
    Value<String>? companyId,
    Value<String>? category,
    Value<String>? rating,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return InspectionCategoryRatingsCompanion(
      id: id ?? this.id,
      inspectionId: inspectionId ?? this.inspectionId,
      companyId: companyId ?? this.companyId,
      category: category ?? this.category,
      rating: rating ?? this.rating,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (inspectionId.present) {
      map['inspection_id'] = Variable<String>(inspectionId.value);
    }
    if (companyId.present) {
      map['company_id'] = Variable<String>(companyId.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (rating.present) {
      map['rating'] = Variable<String>(rating.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InspectionCategoryRatingsCompanion(')
          ..write('id: $id, ')
          ..write('inspectionId: $inspectionId, ')
          ..write('companyId: $companyId, ')
          ..write('category: $category, ')
          ..write('rating: $rating, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InspectionDetailedResponsesTable extends InspectionDetailedResponses
    with
        TableInfo<$InspectionDetailedResponsesTable, LocalDetailedResponseRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InspectionDetailedResponsesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inspectionIdMeta = const VerificationMeta(
    'inspectionId',
  );
  @override
  late final GeneratedColumn<String> inspectionId = GeneratedColumn<String>(
    'inspection_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES inspections (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _companyIdMeta = const VerificationMeta(
    'companyId',
  );
  @override
  late final GeneratedColumn<String> companyId = GeneratedColumn<String>(
    'company_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemKeyMeta = const VerificationMeta(
    'itemKey',
  );
  @override
  late final GeneratedColumn<String> itemKey = GeneratedColumn<String>(
    'item_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelSnapshotMeta = const VerificationMeta(
    'labelSnapshot',
  );
  @override
  late final GeneratedColumn<String> labelSnapshot = GeneratedColumn<String>(
    'label_snapshot',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<String> rating = GeneratedColumn<String>(
    'rating',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    inspectionId,
    companyId,
    category,
    itemKey,
    labelSnapshot,
    sortOrder,
    rating,
    notes,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inspection_detailed_responses';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalDetailedResponseRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('inspection_id')) {
      context.handle(
        _inspectionIdMeta,
        inspectionId.isAcceptableOrUnknown(
          data['inspection_id']!,
          _inspectionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_inspectionIdMeta);
    }
    if (data.containsKey('company_id')) {
      context.handle(
        _companyIdMeta,
        companyId.isAcceptableOrUnknown(data['company_id']!, _companyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_companyIdMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('item_key')) {
      context.handle(
        _itemKeyMeta,
        itemKey.isAcceptableOrUnknown(data['item_key']!, _itemKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_itemKeyMeta);
    }
    if (data.containsKey('label_snapshot')) {
      context.handle(
        _labelSnapshotMeta,
        labelSnapshot.isAcceptableOrUnknown(
          data['label_snapshot']!,
          _labelSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_labelSnapshotMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    } else if (isInserting) {
      context.missing(_ratingMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {inspectionId, category, itemKey},
  ];
  @override
  LocalDetailedResponseRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalDetailedResponseRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      inspectionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}inspection_id'],
      )!,
      companyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_id'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      itemKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_key'],
      )!,
      labelSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label_snapshot'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rating'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $InspectionDetailedResponsesTable createAlias(String alias) {
    return $InspectionDetailedResponsesTable(attachedDatabase, alias);
  }
}

class LocalDetailedResponseRow extends DataClass
    implements Insertable<LocalDetailedResponseRow> {
  final String id;
  final String inspectionId;
  final String companyId;
  final String category;
  final String itemKey;
  final String labelSnapshot;
  final int sortOrder;
  final String rating;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  const LocalDetailedResponseRow({
    required this.id,
    required this.inspectionId,
    required this.companyId,
    required this.category,
    required this.itemKey,
    required this.labelSnapshot,
    required this.sortOrder,
    required this.rating,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['inspection_id'] = Variable<String>(inspectionId);
    map['company_id'] = Variable<String>(companyId);
    map['category'] = Variable<String>(category);
    map['item_key'] = Variable<String>(itemKey);
    map['label_snapshot'] = Variable<String>(labelSnapshot);
    map['sort_order'] = Variable<int>(sortOrder);
    map['rating'] = Variable<String>(rating);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  InspectionDetailedResponsesCompanion toCompanion(bool nullToAbsent) {
    return InspectionDetailedResponsesCompanion(
      id: Value(id),
      inspectionId: Value(inspectionId),
      companyId: Value(companyId),
      category: Value(category),
      itemKey: Value(itemKey),
      labelSnapshot: Value(labelSnapshot),
      sortOrder: Value(sortOrder),
      rating: Value(rating),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalDetailedResponseRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalDetailedResponseRow(
      id: serializer.fromJson<String>(json['id']),
      inspectionId: serializer.fromJson<String>(json['inspectionId']),
      companyId: serializer.fromJson<String>(json['companyId']),
      category: serializer.fromJson<String>(json['category']),
      itemKey: serializer.fromJson<String>(json['itemKey']),
      labelSnapshot: serializer.fromJson<String>(json['labelSnapshot']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      rating: serializer.fromJson<String>(json['rating']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'inspectionId': serializer.toJson<String>(inspectionId),
      'companyId': serializer.toJson<String>(companyId),
      'category': serializer.toJson<String>(category),
      'itemKey': serializer.toJson<String>(itemKey),
      'labelSnapshot': serializer.toJson<String>(labelSnapshot),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'rating': serializer.toJson<String>(rating),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalDetailedResponseRow copyWith({
    String? id,
    String? inspectionId,
    String? companyId,
    String? category,
    String? itemKey,
    String? labelSnapshot,
    int? sortOrder,
    String? rating,
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => LocalDetailedResponseRow(
    id: id ?? this.id,
    inspectionId: inspectionId ?? this.inspectionId,
    companyId: companyId ?? this.companyId,
    category: category ?? this.category,
    itemKey: itemKey ?? this.itemKey,
    labelSnapshot: labelSnapshot ?? this.labelSnapshot,
    sortOrder: sortOrder ?? this.sortOrder,
    rating: rating ?? this.rating,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalDetailedResponseRow copyWithCompanion(
    InspectionDetailedResponsesCompanion data,
  ) {
    return LocalDetailedResponseRow(
      id: data.id.present ? data.id.value : this.id,
      inspectionId: data.inspectionId.present
          ? data.inspectionId.value
          : this.inspectionId,
      companyId: data.companyId.present ? data.companyId.value : this.companyId,
      category: data.category.present ? data.category.value : this.category,
      itemKey: data.itemKey.present ? data.itemKey.value : this.itemKey,
      labelSnapshot: data.labelSnapshot.present
          ? data.labelSnapshot.value
          : this.labelSnapshot,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      rating: data.rating.present ? data.rating.value : this.rating,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalDetailedResponseRow(')
          ..write('id: $id, ')
          ..write('inspectionId: $inspectionId, ')
          ..write('companyId: $companyId, ')
          ..write('category: $category, ')
          ..write('itemKey: $itemKey, ')
          ..write('labelSnapshot: $labelSnapshot, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rating: $rating, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    inspectionId,
    companyId,
    category,
    itemKey,
    labelSnapshot,
    sortOrder,
    rating,
    notes,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalDetailedResponseRow &&
          other.id == this.id &&
          other.inspectionId == this.inspectionId &&
          other.companyId == this.companyId &&
          other.category == this.category &&
          other.itemKey == this.itemKey &&
          other.labelSnapshot == this.labelSnapshot &&
          other.sortOrder == this.sortOrder &&
          other.rating == this.rating &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class InspectionDetailedResponsesCompanion
    extends UpdateCompanion<LocalDetailedResponseRow> {
  final Value<String> id;
  final Value<String> inspectionId;
  final Value<String> companyId;
  final Value<String> category;
  final Value<String> itemKey;
  final Value<String> labelSnapshot;
  final Value<int> sortOrder;
  final Value<String> rating;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const InspectionDetailedResponsesCompanion({
    this.id = const Value.absent(),
    this.inspectionId = const Value.absent(),
    this.companyId = const Value.absent(),
    this.category = const Value.absent(),
    this.itemKey = const Value.absent(),
    this.labelSnapshot = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rating = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InspectionDetailedResponsesCompanion.insert({
    required String id,
    required String inspectionId,
    required String companyId,
    required String category,
    required String itemKey,
    required String labelSnapshot,
    required int sortOrder,
    required String rating,
    this.notes = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       inspectionId = Value(inspectionId),
       companyId = Value(companyId),
       category = Value(category),
       itemKey = Value(itemKey),
       labelSnapshot = Value(labelSnapshot),
       sortOrder = Value(sortOrder),
       rating = Value(rating),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<LocalDetailedResponseRow> custom({
    Expression<String>? id,
    Expression<String>? inspectionId,
    Expression<String>? companyId,
    Expression<String>? category,
    Expression<String>? itemKey,
    Expression<String>? labelSnapshot,
    Expression<int>? sortOrder,
    Expression<String>? rating,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (inspectionId != null) 'inspection_id': inspectionId,
      if (companyId != null) 'company_id': companyId,
      if (category != null) 'category': category,
      if (itemKey != null) 'item_key': itemKey,
      if (labelSnapshot != null) 'label_snapshot': labelSnapshot,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rating != null) 'rating': rating,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InspectionDetailedResponsesCompanion copyWith({
    Value<String>? id,
    Value<String>? inspectionId,
    Value<String>? companyId,
    Value<String>? category,
    Value<String>? itemKey,
    Value<String>? labelSnapshot,
    Value<int>? sortOrder,
    Value<String>? rating,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return InspectionDetailedResponsesCompanion(
      id: id ?? this.id,
      inspectionId: inspectionId ?? this.inspectionId,
      companyId: companyId ?? this.companyId,
      category: category ?? this.category,
      itemKey: itemKey ?? this.itemKey,
      labelSnapshot: labelSnapshot ?? this.labelSnapshot,
      sortOrder: sortOrder ?? this.sortOrder,
      rating: rating ?? this.rating,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (inspectionId.present) {
      map['inspection_id'] = Variable<String>(inspectionId.value);
    }
    if (companyId.present) {
      map['company_id'] = Variable<String>(companyId.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (itemKey.present) {
      map['item_key'] = Variable<String>(itemKey.value);
    }
    if (labelSnapshot.present) {
      map['label_snapshot'] = Variable<String>(labelSnapshot.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rating.present) {
      map['rating'] = Variable<String>(rating.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InspectionDetailedResponsesCompanion(')
          ..write('id: $id, ')
          ..write('inspectionId: $inspectionId, ')
          ..write('companyId: $companyId, ')
          ..write('category: $category, ')
          ..write('itemKey: $itemKey, ')
          ..write('labelSnapshot: $labelSnapshot, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rating: $rating, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalTenantContextsTable extends LocalTenantContexts
    with TableInfo<$LocalTenantContextsTable, LocalTenantContextRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalTenantContextsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _companyIdMeta = const VerificationMeta(
    'companyId',
  );
  @override
  late final GeneratedColumn<String> companyId = GeneratedColumn<String>(
    'company_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activatedAtMeta = const VerificationMeta(
    'activatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> activatedAt = GeneratedColumn<DateTime>(
    'activated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, companyId, userId, activatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_tenant_contexts';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalTenantContextRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('company_id')) {
      context.handle(
        _companyIdMeta,
        companyId.isAcceptableOrUnknown(data['company_id']!, _companyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_companyIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('activated_at')) {
      context.handle(
        _activatedAtMeta,
        activatedAt.isAcceptableOrUnknown(
          data['activated_at']!,
          _activatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_activatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalTenantContextRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalTenantContextRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      companyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      activatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}activated_at'],
      )!,
    );
  }

  @override
  $LocalTenantContextsTable createAlias(String alias) {
    return $LocalTenantContextsTable(attachedDatabase, alias);
  }
}

class LocalTenantContextRow extends DataClass
    implements Insertable<LocalTenantContextRow> {
  final String id;
  final String companyId;
  final String userId;
  final DateTime activatedAt;
  const LocalTenantContextRow({
    required this.id,
    required this.companyId,
    required this.userId,
    required this.activatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['company_id'] = Variable<String>(companyId);
    map['user_id'] = Variable<String>(userId);
    map['activated_at'] = Variable<DateTime>(activatedAt);
    return map;
  }

  LocalTenantContextsCompanion toCompanion(bool nullToAbsent) {
    return LocalTenantContextsCompanion(
      id: Value(id),
      companyId: Value(companyId),
      userId: Value(userId),
      activatedAt: Value(activatedAt),
    );
  }

  factory LocalTenantContextRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalTenantContextRow(
      id: serializer.fromJson<String>(json['id']),
      companyId: serializer.fromJson<String>(json['companyId']),
      userId: serializer.fromJson<String>(json['userId']),
      activatedAt: serializer.fromJson<DateTime>(json['activatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'companyId': serializer.toJson<String>(companyId),
      'userId': serializer.toJson<String>(userId),
      'activatedAt': serializer.toJson<DateTime>(activatedAt),
    };
  }

  LocalTenantContextRow copyWith({
    String? id,
    String? companyId,
    String? userId,
    DateTime? activatedAt,
  }) => LocalTenantContextRow(
    id: id ?? this.id,
    companyId: companyId ?? this.companyId,
    userId: userId ?? this.userId,
    activatedAt: activatedAt ?? this.activatedAt,
  );
  LocalTenantContextRow copyWithCompanion(LocalTenantContextsCompanion data) {
    return LocalTenantContextRow(
      id: data.id.present ? data.id.value : this.id,
      companyId: data.companyId.present ? data.companyId.value : this.companyId,
      userId: data.userId.present ? data.userId.value : this.userId,
      activatedAt: data.activatedAt.present
          ? data.activatedAt.value
          : this.activatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalTenantContextRow(')
          ..write('id: $id, ')
          ..write('companyId: $companyId, ')
          ..write('userId: $userId, ')
          ..write('activatedAt: $activatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, companyId, userId, activatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalTenantContextRow &&
          other.id == this.id &&
          other.companyId == this.companyId &&
          other.userId == this.userId &&
          other.activatedAt == this.activatedAt);
}

class LocalTenantContextsCompanion
    extends UpdateCompanion<LocalTenantContextRow> {
  final Value<String> id;
  final Value<String> companyId;
  final Value<String> userId;
  final Value<DateTime> activatedAt;
  final Value<int> rowid;
  const LocalTenantContextsCompanion({
    this.id = const Value.absent(),
    this.companyId = const Value.absent(),
    this.userId = const Value.absent(),
    this.activatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalTenantContextsCompanion.insert({
    required String id,
    required String companyId,
    required String userId,
    required DateTime activatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       companyId = Value(companyId),
       userId = Value(userId),
       activatedAt = Value(activatedAt);
  static Insertable<LocalTenantContextRow> custom({
    Expression<String>? id,
    Expression<String>? companyId,
    Expression<String>? userId,
    Expression<DateTime>? activatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (companyId != null) 'company_id': companyId,
      if (userId != null) 'user_id': userId,
      if (activatedAt != null) 'activated_at': activatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalTenantContextsCompanion copyWith({
    Value<String>? id,
    Value<String>? companyId,
    Value<String>? userId,
    Value<DateTime>? activatedAt,
    Value<int>? rowid,
  }) {
    return LocalTenantContextsCompanion(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      userId: userId ?? this.userId,
      activatedAt: activatedAt ?? this.activatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (companyId.present) {
      map['company_id'] = Variable<String>(companyId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (activatedAt.present) {
      map['activated_at'] = Variable<DateTime>(activatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalTenantContextsCompanion(')
          ..write('id: $id, ')
          ..write('companyId: $companyId, ')
          ..write('userId: $userId, ')
          ..write('activatedAt: $activatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalEquipmentCacheTable extends LocalEquipmentCache
    with TableInfo<$LocalEquipmentCacheTable, LocalEquipmentCacheRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalEquipmentCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _companyIdMeta = const VerificationMeta(
    'companyId',
  );
  @override
  late final GeneratedColumn<String> companyId = GeneratedColumn<String>(
    'company_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _assetNameMeta = const VerificationMeta(
    'assetName',
  );
  @override
  late final GeneratedColumn<String> assetName = GeneratedColumn<String>(
    'asset_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _manufacturerMeta = const VerificationMeta(
    'manufacturer',
  );
  @override
  late final GeneratedColumn<String> manufacturer = GeneratedColumn<String>(
    'manufacturer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serialNumberMeta = const VerificationMeta(
    'serialNumber',
  );
  @override
  late final GeneratedColumn<String> serialNumber = GeneratedColumn<String>(
    'serial_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hoursMeta = const VerificationMeta('hours');
  @override
  late final GeneratedColumn<double> hours = GeneratedColumn<double>(
    'hours',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdByNameMeta = const VerificationMeta(
    'createdByName',
  );
  @override
  late final GeneratedColumn<String> createdByName = GeneratedColumn<String>(
    'created_by_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedByMeta = const VerificationMeta(
    'updatedBy',
  );
  @override
  late final GeneratedColumn<String> updatedBy = GeneratedColumn<String>(
    'updated_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedByNameMeta = const VerificationMeta(
    'updatedByName',
  );
  @override
  late final GeneratedColumn<String> updatedByName = GeneratedColumn<String>(
    'updated_by_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    companyId,
    assetName,
    manufacturer,
    model,
    serialNumber,
    year,
    hours,
    location,
    notes,
    createdBy,
    createdByName,
    updatedBy,
    updatedByName,
    createdAt,
    updatedAt,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_equipment_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalEquipmentCacheRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('company_id')) {
      context.handle(
        _companyIdMeta,
        companyId.isAcceptableOrUnknown(data['company_id']!, _companyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_companyIdMeta);
    }
    if (data.containsKey('asset_name')) {
      context.handle(
        _assetNameMeta,
        assetName.isAcceptableOrUnknown(data['asset_name']!, _assetNameMeta),
      );
    } else if (isInserting) {
      context.missing(_assetNameMeta);
    }
    if (data.containsKey('manufacturer')) {
      context.handle(
        _manufacturerMeta,
        manufacturer.isAcceptableOrUnknown(
          data['manufacturer']!,
          _manufacturerMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_manufacturerMeta);
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    } else if (isInserting) {
      context.missing(_modelMeta);
    }
    if (data.containsKey('serial_number')) {
      context.handle(
        _serialNumberMeta,
        serialNumber.isAcceptableOrUnknown(
          data['serial_number']!,
          _serialNumberMeta,
        ),
      );
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    }
    if (data.containsKey('hours')) {
      context.handle(
        _hoursMeta,
        hours.isAcceptableOrUnknown(data['hours']!, _hoursMeta),
      );
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    }
    if (data.containsKey('created_by_name')) {
      context.handle(
        _createdByNameMeta,
        createdByName.isAcceptableOrUnknown(
          data['created_by_name']!,
          _createdByNameMeta,
        ),
      );
    }
    if (data.containsKey('updated_by')) {
      context.handle(
        _updatedByMeta,
        updatedBy.isAcceptableOrUnknown(data['updated_by']!, _updatedByMeta),
      );
    }
    if (data.containsKey('updated_by_name')) {
      context.handle(
        _updatedByNameMeta,
        updatedByName.isAcceptableOrUnknown(
          data['updated_by_name']!,
          _updatedByNameMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalEquipmentCacheRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalEquipmentCacheRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      companyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_id'],
      )!,
      assetName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}asset_name'],
      )!,
      manufacturer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}manufacturer'],
      )!,
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      )!,
      serialNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}serial_number'],
      ),
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      ),
      hours: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}hours'],
      ),
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      ),
      createdByName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by_name'],
      ),
      updatedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by'],
      ),
      updatedByName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by_name'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $LocalEquipmentCacheTable createAlias(String alias) {
    return $LocalEquipmentCacheTable(attachedDatabase, alias);
  }
}

class LocalEquipmentCacheRow extends DataClass
    implements Insertable<LocalEquipmentCacheRow> {
  final String id;
  final String companyId;
  final String assetName;
  final String manufacturer;
  final String model;
  final String? serialNumber;
  final int? year;
  final double? hours;
  final String? location;
  final String? notes;
  final String? createdBy;
  final String? createdByName;
  final String? updatedBy;
  final String? updatedByName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime cachedAt;
  const LocalEquipmentCacheRow({
    required this.id,
    required this.companyId,
    required this.assetName,
    required this.manufacturer,
    required this.model,
    this.serialNumber,
    this.year,
    this.hours,
    this.location,
    this.notes,
    this.createdBy,
    this.createdByName,
    this.updatedBy,
    this.updatedByName,
    required this.createdAt,
    required this.updatedAt,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['company_id'] = Variable<String>(companyId);
    map['asset_name'] = Variable<String>(assetName);
    map['manufacturer'] = Variable<String>(manufacturer);
    map['model'] = Variable<String>(model);
    if (!nullToAbsent || serialNumber != null) {
      map['serial_number'] = Variable<String>(serialNumber);
    }
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<int>(year);
    }
    if (!nullToAbsent || hours != null) {
      map['hours'] = Variable<double>(hours);
    }
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || createdBy != null) {
      map['created_by'] = Variable<String>(createdBy);
    }
    if (!nullToAbsent || createdByName != null) {
      map['created_by_name'] = Variable<String>(createdByName);
    }
    if (!nullToAbsent || updatedBy != null) {
      map['updated_by'] = Variable<String>(updatedBy);
    }
    if (!nullToAbsent || updatedByName != null) {
      map['updated_by_name'] = Variable<String>(updatedByName);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  LocalEquipmentCacheCompanion toCompanion(bool nullToAbsent) {
    return LocalEquipmentCacheCompanion(
      id: Value(id),
      companyId: Value(companyId),
      assetName: Value(assetName),
      manufacturer: Value(manufacturer),
      model: Value(model),
      serialNumber: serialNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(serialNumber),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      hours: hours == null && nullToAbsent
          ? const Value.absent()
          : Value(hours),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdBy: createdBy == null && nullToAbsent
          ? const Value.absent()
          : Value(createdBy),
      createdByName: createdByName == null && nullToAbsent
          ? const Value.absent()
          : Value(createdByName),
      updatedBy: updatedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedBy),
      updatedByName: updatedByName == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedByName),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      cachedAt: Value(cachedAt),
    );
  }

  factory LocalEquipmentCacheRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalEquipmentCacheRow(
      id: serializer.fromJson<String>(json['id']),
      companyId: serializer.fromJson<String>(json['companyId']),
      assetName: serializer.fromJson<String>(json['assetName']),
      manufacturer: serializer.fromJson<String>(json['manufacturer']),
      model: serializer.fromJson<String>(json['model']),
      serialNumber: serializer.fromJson<String?>(json['serialNumber']),
      year: serializer.fromJson<int?>(json['year']),
      hours: serializer.fromJson<double?>(json['hours']),
      location: serializer.fromJson<String?>(json['location']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdBy: serializer.fromJson<String?>(json['createdBy']),
      createdByName: serializer.fromJson<String?>(json['createdByName']),
      updatedBy: serializer.fromJson<String?>(json['updatedBy']),
      updatedByName: serializer.fromJson<String?>(json['updatedByName']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'companyId': serializer.toJson<String>(companyId),
      'assetName': serializer.toJson<String>(assetName),
      'manufacturer': serializer.toJson<String>(manufacturer),
      'model': serializer.toJson<String>(model),
      'serialNumber': serializer.toJson<String?>(serialNumber),
      'year': serializer.toJson<int?>(year),
      'hours': serializer.toJson<double?>(hours),
      'location': serializer.toJson<String?>(location),
      'notes': serializer.toJson<String?>(notes),
      'createdBy': serializer.toJson<String?>(createdBy),
      'createdByName': serializer.toJson<String?>(createdByName),
      'updatedBy': serializer.toJson<String?>(updatedBy),
      'updatedByName': serializer.toJson<String?>(updatedByName),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  LocalEquipmentCacheRow copyWith({
    String? id,
    String? companyId,
    String? assetName,
    String? manufacturer,
    String? model,
    Value<String?> serialNumber = const Value.absent(),
    Value<int?> year = const Value.absent(),
    Value<double?> hours = const Value.absent(),
    Value<String?> location = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<String?> createdBy = const Value.absent(),
    Value<String?> createdByName = const Value.absent(),
    Value<String?> updatedBy = const Value.absent(),
    Value<String?> updatedByName = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? cachedAt,
  }) => LocalEquipmentCacheRow(
    id: id ?? this.id,
    companyId: companyId ?? this.companyId,
    assetName: assetName ?? this.assetName,
    manufacturer: manufacturer ?? this.manufacturer,
    model: model ?? this.model,
    serialNumber: serialNumber.present ? serialNumber.value : this.serialNumber,
    year: year.present ? year.value : this.year,
    hours: hours.present ? hours.value : this.hours,
    location: location.present ? location.value : this.location,
    notes: notes.present ? notes.value : this.notes,
    createdBy: createdBy.present ? createdBy.value : this.createdBy,
    createdByName: createdByName.present
        ? createdByName.value
        : this.createdByName,
    updatedBy: updatedBy.present ? updatedBy.value : this.updatedBy,
    updatedByName: updatedByName.present
        ? updatedByName.value
        : this.updatedByName,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  LocalEquipmentCacheRow copyWithCompanion(LocalEquipmentCacheCompanion data) {
    return LocalEquipmentCacheRow(
      id: data.id.present ? data.id.value : this.id,
      companyId: data.companyId.present ? data.companyId.value : this.companyId,
      assetName: data.assetName.present ? data.assetName.value : this.assetName,
      manufacturer: data.manufacturer.present
          ? data.manufacturer.value
          : this.manufacturer,
      model: data.model.present ? data.model.value : this.model,
      serialNumber: data.serialNumber.present
          ? data.serialNumber.value
          : this.serialNumber,
      year: data.year.present ? data.year.value : this.year,
      hours: data.hours.present ? data.hours.value : this.hours,
      location: data.location.present ? data.location.value : this.location,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      createdByName: data.createdByName.present
          ? data.createdByName.value
          : this.createdByName,
      updatedBy: data.updatedBy.present ? data.updatedBy.value : this.updatedBy,
      updatedByName: data.updatedByName.present
          ? data.updatedByName.value
          : this.updatedByName,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalEquipmentCacheRow(')
          ..write('id: $id, ')
          ..write('companyId: $companyId, ')
          ..write('assetName: $assetName, ')
          ..write('manufacturer: $manufacturer, ')
          ..write('model: $model, ')
          ..write('serialNumber: $serialNumber, ')
          ..write('year: $year, ')
          ..write('hours: $hours, ')
          ..write('location: $location, ')
          ..write('notes: $notes, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdByName: $createdByName, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('updatedByName: $updatedByName, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    companyId,
    assetName,
    manufacturer,
    model,
    serialNumber,
    year,
    hours,
    location,
    notes,
    createdBy,
    createdByName,
    updatedBy,
    updatedByName,
    createdAt,
    updatedAt,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalEquipmentCacheRow &&
          other.id == this.id &&
          other.companyId == this.companyId &&
          other.assetName == this.assetName &&
          other.manufacturer == this.manufacturer &&
          other.model == this.model &&
          other.serialNumber == this.serialNumber &&
          other.year == this.year &&
          other.hours == this.hours &&
          other.location == this.location &&
          other.notes == this.notes &&
          other.createdBy == this.createdBy &&
          other.createdByName == this.createdByName &&
          other.updatedBy == this.updatedBy &&
          other.updatedByName == this.updatedByName &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.cachedAt == this.cachedAt);
}

class LocalEquipmentCacheCompanion
    extends UpdateCompanion<LocalEquipmentCacheRow> {
  final Value<String> id;
  final Value<String> companyId;
  final Value<String> assetName;
  final Value<String> manufacturer;
  final Value<String> model;
  final Value<String?> serialNumber;
  final Value<int?> year;
  final Value<double?> hours;
  final Value<String?> location;
  final Value<String?> notes;
  final Value<String?> createdBy;
  final Value<String?> createdByName;
  final Value<String?> updatedBy;
  final Value<String?> updatedByName;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const LocalEquipmentCacheCompanion({
    this.id = const Value.absent(),
    this.companyId = const Value.absent(),
    this.assetName = const Value.absent(),
    this.manufacturer = const Value.absent(),
    this.model = const Value.absent(),
    this.serialNumber = const Value.absent(),
    this.year = const Value.absent(),
    this.hours = const Value.absent(),
    this.location = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.createdByName = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.updatedByName = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalEquipmentCacheCompanion.insert({
    required String id,
    required String companyId,
    required String assetName,
    required String manufacturer,
    required String model,
    this.serialNumber = const Value.absent(),
    this.year = const Value.absent(),
    this.hours = const Value.absent(),
    this.location = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.createdByName = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.updatedByName = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       companyId = Value(companyId),
       assetName = Value(assetName),
       manufacturer = Value(manufacturer),
       model = Value(model),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       cachedAt = Value(cachedAt);
  static Insertable<LocalEquipmentCacheRow> custom({
    Expression<String>? id,
    Expression<String>? companyId,
    Expression<String>? assetName,
    Expression<String>? manufacturer,
    Expression<String>? model,
    Expression<String>? serialNumber,
    Expression<int>? year,
    Expression<double>? hours,
    Expression<String>? location,
    Expression<String>? notes,
    Expression<String>? createdBy,
    Expression<String>? createdByName,
    Expression<String>? updatedBy,
    Expression<String>? updatedByName,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (companyId != null) 'company_id': companyId,
      if (assetName != null) 'asset_name': assetName,
      if (manufacturer != null) 'manufacturer': manufacturer,
      if (model != null) 'model': model,
      if (serialNumber != null) 'serial_number': serialNumber,
      if (year != null) 'year': year,
      if (hours != null) 'hours': hours,
      if (location != null) 'location': location,
      if (notes != null) 'notes': notes,
      if (createdBy != null) 'created_by': createdBy,
      if (createdByName != null) 'created_by_name': createdByName,
      if (updatedBy != null) 'updated_by': updatedBy,
      if (updatedByName != null) 'updated_by_name': updatedByName,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalEquipmentCacheCompanion copyWith({
    Value<String>? id,
    Value<String>? companyId,
    Value<String>? assetName,
    Value<String>? manufacturer,
    Value<String>? model,
    Value<String?>? serialNumber,
    Value<int?>? year,
    Value<double?>? hours,
    Value<String?>? location,
    Value<String?>? notes,
    Value<String?>? createdBy,
    Value<String?>? createdByName,
    Value<String?>? updatedBy,
    Value<String?>? updatedByName,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return LocalEquipmentCacheCompanion(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      assetName: assetName ?? this.assetName,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      serialNumber: serialNumber ?? this.serialNumber,
      year: year ?? this.year,
      hours: hours ?? this.hours,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedByName: updatedByName ?? this.updatedByName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (companyId.present) {
      map['company_id'] = Variable<String>(companyId.value);
    }
    if (assetName.present) {
      map['asset_name'] = Variable<String>(assetName.value);
    }
    if (manufacturer.present) {
      map['manufacturer'] = Variable<String>(manufacturer.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (serialNumber.present) {
      map['serial_number'] = Variable<String>(serialNumber.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (hours.present) {
      map['hours'] = Variable<double>(hours.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (createdByName.present) {
      map['created_by_name'] = Variable<String>(createdByName.value);
    }
    if (updatedBy.present) {
      map['updated_by'] = Variable<String>(updatedBy.value);
    }
    if (updatedByName.present) {
      map['updated_by_name'] = Variable<String>(updatedByName.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalEquipmentCacheCompanion(')
          ..write('id: $id, ')
          ..write('companyId: $companyId, ')
          ..write('assetName: $assetName, ')
          ..write('manufacturer: $manufacturer, ')
          ..write('model: $model, ')
          ..write('serialNumber: $serialNumber, ')
          ..write('year: $year, ')
          ..write('hours: $hours, ')
          ..write('location: $location, ')
          ..write('notes: $notes, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdByName: $createdByName, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('updatedByName: $updatedByName, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $InspectionsTable inspections = $InspectionsTable(this);
  late final $InspectionCategoryRatingsTable inspectionCategoryRatings =
      $InspectionCategoryRatingsTable(this);
  late final $InspectionDetailedResponsesTable inspectionDetailedResponses =
      $InspectionDetailedResponsesTable(this);
  late final $LocalTenantContextsTable localTenantContexts =
      $LocalTenantContextsTable(this);
  late final $LocalEquipmentCacheTable localEquipmentCache =
      $LocalEquipmentCacheTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    inspections,
    inspectionCategoryRatings,
    inspectionDetailedResponses,
    localTenantContexts,
    localEquipmentCache,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'inspections',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('inspection_category_ratings', kind: UpdateKind.delete),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'inspections',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('inspection_detailed_responses', kind: UpdateKind.delete),
      ],
    ),
  ]);
}

typedef $$InspectionsTableCreateCompanionBuilder =
    InspectionsCompanion Function({
      required String id,
      required String companyId,
      required String equipmentId,
      required String createdByUserId,
      Value<String?> updatedByUserId,
      required String completionStatus,
      required String localLifecycle,
      required String depth,
      required String syncStatus,
      required String reportStatus,
      Value<String?> remoteId,
      Value<String?> overallNotes,
      required DateTime createdAt,
      required DateTime updatedAt,
      required DateTime localUpdatedAt,
      Value<DateTime?> completedAt,
      Value<DateTime?> discardedAt,
      Value<int> rowid,
    });
typedef $$InspectionsTableUpdateCompanionBuilder =
    InspectionsCompanion Function({
      Value<String> id,
      Value<String> companyId,
      Value<String> equipmentId,
      Value<String> createdByUserId,
      Value<String?> updatedByUserId,
      Value<String> completionStatus,
      Value<String> localLifecycle,
      Value<String> depth,
      Value<String> syncStatus,
      Value<String> reportStatus,
      Value<String?> remoteId,
      Value<String?> overallNotes,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime> localUpdatedAt,
      Value<DateTime?> completedAt,
      Value<DateTime?> discardedAt,
      Value<int> rowid,
    });

final class $$InspectionsTableReferences
    extends
        BaseReferences<_$AppDatabase, $InspectionsTable, LocalInspectionRow> {
  $$InspectionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<
    $InspectionCategoryRatingsTable,
    List<LocalCategoryRatingRow>
  >
  _inspectionCategoryRatingsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.inspectionCategoryRatings,
        aliasName:
            'inspections__id__inspection_category_ratings__inspection_id',
      );

  $$InspectionCategoryRatingsTableProcessedTableManager
  get inspectionCategoryRatingsRefs {
    final manager = $$InspectionCategoryRatingsTableTableManager(
      $_db,
      $_db.inspectionCategoryRatings,
    ).filter((f) => f.inspectionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _inspectionCategoryRatingsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $InspectionDetailedResponsesTable,
    List<LocalDetailedResponseRow>
  >
  _inspectionDetailedResponsesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.inspectionDetailedResponses,
        aliasName:
            'inspections__id__inspection_detailed_responses__inspection_id',
      );

  $$InspectionDetailedResponsesTableProcessedTableManager
  get inspectionDetailedResponsesRefs {
    final manager = $$InspectionDetailedResponsesTableTableManager(
      $_db,
      $_db.inspectionDetailedResponses,
    ).filter((f) => f.inspectionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _inspectionDetailedResponsesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$InspectionsTableFilterComposer
    extends Composer<_$AppDatabase, $InspectionsTable> {
  $$InspectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get equipmentId => $composableBuilder(
    column: $table.equipmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdByUserId => $composableBuilder(
    column: $table.createdByUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedByUserId => $composableBuilder(
    column: $table.updatedByUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get completionStatus => $composableBuilder(
    column: $table.completionStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localLifecycle => $composableBuilder(
    column: $table.localLifecycle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get depth => $composableBuilder(
    column: $table.depth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reportStatus => $composableBuilder(
    column: $table.reportStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get overallNotes => $composableBuilder(
    column: $table.overallNotes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get discardedAt => $composableBuilder(
    column: $table.discardedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> inspectionCategoryRatingsRefs(
    Expression<bool> Function($$InspectionCategoryRatingsTableFilterComposer f)
    f,
  ) {
    final $$InspectionCategoryRatingsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.inspectionCategoryRatings,
          getReferencedColumn: (t) => t.inspectionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$InspectionCategoryRatingsTableFilterComposer(
                $db: $db,
                $table: $db.inspectionCategoryRatings,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> inspectionDetailedResponsesRefs(
    Expression<bool> Function(
      $$InspectionDetailedResponsesTableFilterComposer f,
    )
    f,
  ) {
    final $$InspectionDetailedResponsesTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.inspectionDetailedResponses,
          getReferencedColumn: (t) => t.inspectionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$InspectionDetailedResponsesTableFilterComposer(
                $db: $db,
                $table: $db.inspectionDetailedResponses,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$InspectionsTableOrderingComposer
    extends Composer<_$AppDatabase, $InspectionsTable> {
  $$InspectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get equipmentId => $composableBuilder(
    column: $table.equipmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdByUserId => $composableBuilder(
    column: $table.createdByUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedByUserId => $composableBuilder(
    column: $table.updatedByUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get completionStatus => $composableBuilder(
    column: $table.completionStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localLifecycle => $composableBuilder(
    column: $table.localLifecycle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get depth => $composableBuilder(
    column: $table.depth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reportStatus => $composableBuilder(
    column: $table.reportStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get overallNotes => $composableBuilder(
    column: $table.overallNotes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get discardedAt => $composableBuilder(
    column: $table.discardedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InspectionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InspectionsTable> {
  $$InspectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get companyId =>
      $composableBuilder(column: $table.companyId, builder: (column) => column);

  GeneratedColumn<String> get equipmentId => $composableBuilder(
    column: $table.equipmentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdByUserId => $composableBuilder(
    column: $table.createdByUserId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get updatedByUserId => $composableBuilder(
    column: $table.updatedByUserId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get completionStatus => $composableBuilder(
    column: $table.completionStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localLifecycle => $composableBuilder(
    column: $table.localLifecycle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get depth =>
      $composableBuilder(column: $table.depth, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reportStatus => $composableBuilder(
    column: $table.reportStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get overallNotes => $composableBuilder(
    column: $table.overallNotes,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get discardedAt => $composableBuilder(
    column: $table.discardedAt,
    builder: (column) => column,
  );

  Expression<T> inspectionCategoryRatingsRefs<T extends Object>(
    Expression<T> Function($$InspectionCategoryRatingsTableAnnotationComposer a)
    f,
  ) {
    final $$InspectionCategoryRatingsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.inspectionCategoryRatings,
          getReferencedColumn: (t) => t.inspectionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$InspectionCategoryRatingsTableAnnotationComposer(
                $db: $db,
                $table: $db.inspectionCategoryRatings,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> inspectionDetailedResponsesRefs<T extends Object>(
    Expression<T> Function(
      $$InspectionDetailedResponsesTableAnnotationComposer a,
    )
    f,
  ) {
    final $$InspectionDetailedResponsesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.inspectionDetailedResponses,
          getReferencedColumn: (t) => t.inspectionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$InspectionDetailedResponsesTableAnnotationComposer(
                $db: $db,
                $table: $db.inspectionDetailedResponses,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$InspectionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InspectionsTable,
          LocalInspectionRow,
          $$InspectionsTableFilterComposer,
          $$InspectionsTableOrderingComposer,
          $$InspectionsTableAnnotationComposer,
          $$InspectionsTableCreateCompanionBuilder,
          $$InspectionsTableUpdateCompanionBuilder,
          (LocalInspectionRow, $$InspectionsTableReferences),
          LocalInspectionRow,
          PrefetchHooks Function({
            bool inspectionCategoryRatingsRefs,
            bool inspectionDetailedResponsesRefs,
          })
        > {
  $$InspectionsTableTableManager(_$AppDatabase db, $InspectionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InspectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InspectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InspectionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> companyId = const Value.absent(),
                Value<String> equipmentId = const Value.absent(),
                Value<String> createdByUserId = const Value.absent(),
                Value<String?> updatedByUserId = const Value.absent(),
                Value<String> completionStatus = const Value.absent(),
                Value<String> localLifecycle = const Value.absent(),
                Value<String> depth = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<String> reportStatus = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<String?> overallNotes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime> localUpdatedAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<DateTime?> discardedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InspectionsCompanion(
                id: id,
                companyId: companyId,
                equipmentId: equipmentId,
                createdByUserId: createdByUserId,
                updatedByUserId: updatedByUserId,
                completionStatus: completionStatus,
                localLifecycle: localLifecycle,
                depth: depth,
                syncStatus: syncStatus,
                reportStatus: reportStatus,
                remoteId: remoteId,
                overallNotes: overallNotes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                localUpdatedAt: localUpdatedAt,
                completedAt: completedAt,
                discardedAt: discardedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String companyId,
                required String equipmentId,
                required String createdByUserId,
                Value<String?> updatedByUserId = const Value.absent(),
                required String completionStatus,
                required String localLifecycle,
                required String depth,
                required String syncStatus,
                required String reportStatus,
                Value<String?> remoteId = const Value.absent(),
                Value<String?> overallNotes = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                required DateTime localUpdatedAt,
                Value<DateTime?> completedAt = const Value.absent(),
                Value<DateTime?> discardedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InspectionsCompanion.insert(
                id: id,
                companyId: companyId,
                equipmentId: equipmentId,
                createdByUserId: createdByUserId,
                updatedByUserId: updatedByUserId,
                completionStatus: completionStatus,
                localLifecycle: localLifecycle,
                depth: depth,
                syncStatus: syncStatus,
                reportStatus: reportStatus,
                remoteId: remoteId,
                overallNotes: overallNotes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                localUpdatedAt: localUpdatedAt,
                completedAt: completedAt,
                discardedAt: discardedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$InspectionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                inspectionCategoryRatingsRefs = false,
                inspectionDetailedResponsesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (inspectionCategoryRatingsRefs)
                      db.inspectionCategoryRatings,
                    if (inspectionDetailedResponsesRefs)
                      db.inspectionDetailedResponses,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (inspectionCategoryRatingsRefs)
                        await $_getPrefetchedData<
                          LocalInspectionRow,
                          $InspectionsTable,
                          LocalCategoryRatingRow
                        >(
                          currentTable: table,
                          referencedTable: $$InspectionsTableReferences
                              ._inspectionCategoryRatingsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$InspectionsTableReferences(
                                db,
                                table,
                                p0,
                              ).inspectionCategoryRatingsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.inspectionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (inspectionDetailedResponsesRefs)
                        await $_getPrefetchedData<
                          LocalInspectionRow,
                          $InspectionsTable,
                          LocalDetailedResponseRow
                        >(
                          currentTable: table,
                          referencedTable: $$InspectionsTableReferences
                              ._inspectionDetailedResponsesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$InspectionsTableReferences(
                                db,
                                table,
                                p0,
                              ).inspectionDetailedResponsesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.inspectionId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$InspectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InspectionsTable,
      LocalInspectionRow,
      $$InspectionsTableFilterComposer,
      $$InspectionsTableOrderingComposer,
      $$InspectionsTableAnnotationComposer,
      $$InspectionsTableCreateCompanionBuilder,
      $$InspectionsTableUpdateCompanionBuilder,
      (LocalInspectionRow, $$InspectionsTableReferences),
      LocalInspectionRow,
      PrefetchHooks Function({
        bool inspectionCategoryRatingsRefs,
        bool inspectionDetailedResponsesRefs,
      })
    >;
typedef $$InspectionCategoryRatingsTableCreateCompanionBuilder =
    InspectionCategoryRatingsCompanion Function({
      required String id,
      required String inspectionId,
      required String companyId,
      required String category,
      required String rating,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$InspectionCategoryRatingsTableUpdateCompanionBuilder =
    InspectionCategoryRatingsCompanion Function({
      Value<String> id,
      Value<String> inspectionId,
      Value<String> companyId,
      Value<String> category,
      Value<String> rating,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$InspectionCategoryRatingsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $InspectionCategoryRatingsTable,
          LocalCategoryRatingRow
        > {
  $$InspectionCategoryRatingsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $InspectionsTable _inspectionIdTable(_$AppDatabase db) =>
      db.inspections.createAlias(
        'inspection_category_ratings__inspection_id__inspections__id',
      );

  $$InspectionsTableProcessedTableManager get inspectionId {
    final $_column = $_itemColumn<String>('inspection_id')!;

    final manager = $$InspectionsTableTableManager(
      $_db,
      $_db.inspections,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_inspectionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$InspectionCategoryRatingsTableFilterComposer
    extends Composer<_$AppDatabase, $InspectionCategoryRatingsTable> {
  $$InspectionCategoryRatingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$InspectionsTableFilterComposer get inspectionId {
    final $$InspectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.inspectionId,
      referencedTable: $db.inspections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InspectionsTableFilterComposer(
            $db: $db,
            $table: $db.inspections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InspectionCategoryRatingsTableOrderingComposer
    extends Composer<_$AppDatabase, $InspectionCategoryRatingsTable> {
  $$InspectionCategoryRatingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$InspectionsTableOrderingComposer get inspectionId {
    final $$InspectionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.inspectionId,
      referencedTable: $db.inspections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InspectionsTableOrderingComposer(
            $db: $db,
            $table: $db.inspections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InspectionCategoryRatingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InspectionCategoryRatingsTable> {
  $$InspectionCategoryRatingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get companyId =>
      $composableBuilder(column: $table.companyId, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$InspectionsTableAnnotationComposer get inspectionId {
    final $$InspectionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.inspectionId,
      referencedTable: $db.inspections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InspectionsTableAnnotationComposer(
            $db: $db,
            $table: $db.inspections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InspectionCategoryRatingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InspectionCategoryRatingsTable,
          LocalCategoryRatingRow,
          $$InspectionCategoryRatingsTableFilterComposer,
          $$InspectionCategoryRatingsTableOrderingComposer,
          $$InspectionCategoryRatingsTableAnnotationComposer,
          $$InspectionCategoryRatingsTableCreateCompanionBuilder,
          $$InspectionCategoryRatingsTableUpdateCompanionBuilder,
          (LocalCategoryRatingRow, $$InspectionCategoryRatingsTableReferences),
          LocalCategoryRatingRow,
          PrefetchHooks Function({bool inspectionId})
        > {
  $$InspectionCategoryRatingsTableTableManager(
    _$AppDatabase db,
    $InspectionCategoryRatingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InspectionCategoryRatingsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$InspectionCategoryRatingsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$InspectionCategoryRatingsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> inspectionId = const Value.absent(),
                Value<String> companyId = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> rating = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InspectionCategoryRatingsCompanion(
                id: id,
                inspectionId: inspectionId,
                companyId: companyId,
                category: category,
                rating: rating,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String inspectionId,
                required String companyId,
                required String category,
                required String rating,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => InspectionCategoryRatingsCompanion.insert(
                id: id,
                inspectionId: inspectionId,
                companyId: companyId,
                category: category,
                rating: rating,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$InspectionCategoryRatingsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({inspectionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (inspectionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.inspectionId,
                                referencedTable:
                                    $$InspectionCategoryRatingsTableReferences
                                        ._inspectionIdTable(db),
                                referencedColumn:
                                    $$InspectionCategoryRatingsTableReferences
                                        ._inspectionIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$InspectionCategoryRatingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InspectionCategoryRatingsTable,
      LocalCategoryRatingRow,
      $$InspectionCategoryRatingsTableFilterComposer,
      $$InspectionCategoryRatingsTableOrderingComposer,
      $$InspectionCategoryRatingsTableAnnotationComposer,
      $$InspectionCategoryRatingsTableCreateCompanionBuilder,
      $$InspectionCategoryRatingsTableUpdateCompanionBuilder,
      (LocalCategoryRatingRow, $$InspectionCategoryRatingsTableReferences),
      LocalCategoryRatingRow,
      PrefetchHooks Function({bool inspectionId})
    >;
typedef $$InspectionDetailedResponsesTableCreateCompanionBuilder =
    InspectionDetailedResponsesCompanion Function({
      required String id,
      required String inspectionId,
      required String companyId,
      required String category,
      required String itemKey,
      required String labelSnapshot,
      required int sortOrder,
      required String rating,
      Value<String?> notes,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$InspectionDetailedResponsesTableUpdateCompanionBuilder =
    InspectionDetailedResponsesCompanion Function({
      Value<String> id,
      Value<String> inspectionId,
      Value<String> companyId,
      Value<String> category,
      Value<String> itemKey,
      Value<String> labelSnapshot,
      Value<int> sortOrder,
      Value<String> rating,
      Value<String?> notes,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$InspectionDetailedResponsesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $InspectionDetailedResponsesTable,
          LocalDetailedResponseRow
        > {
  $$InspectionDetailedResponsesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $InspectionsTable _inspectionIdTable(_$AppDatabase db) =>
      db.inspections.createAlias(
        'inspection_detailed_responses__inspection_id__inspections__id',
      );

  $$InspectionsTableProcessedTableManager get inspectionId {
    final $_column = $_itemColumn<String>('inspection_id')!;

    final manager = $$InspectionsTableTableManager(
      $_db,
      $_db.inspections,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_inspectionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$InspectionDetailedResponsesTableFilterComposer
    extends Composer<_$AppDatabase, $InspectionDetailedResponsesTable> {
  $$InspectionDetailedResponsesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemKey => $composableBuilder(
    column: $table.itemKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get labelSnapshot => $composableBuilder(
    column: $table.labelSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$InspectionsTableFilterComposer get inspectionId {
    final $$InspectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.inspectionId,
      referencedTable: $db.inspections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InspectionsTableFilterComposer(
            $db: $db,
            $table: $db.inspections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InspectionDetailedResponsesTableOrderingComposer
    extends Composer<_$AppDatabase, $InspectionDetailedResponsesTable> {
  $$InspectionDetailedResponsesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemKey => $composableBuilder(
    column: $table.itemKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get labelSnapshot => $composableBuilder(
    column: $table.labelSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$InspectionsTableOrderingComposer get inspectionId {
    final $$InspectionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.inspectionId,
      referencedTable: $db.inspections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InspectionsTableOrderingComposer(
            $db: $db,
            $table: $db.inspections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InspectionDetailedResponsesTableAnnotationComposer
    extends Composer<_$AppDatabase, $InspectionDetailedResponsesTable> {
  $$InspectionDetailedResponsesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get companyId =>
      $composableBuilder(column: $table.companyId, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get itemKey =>
      $composableBuilder(column: $table.itemKey, builder: (column) => column);

  GeneratedColumn<String> get labelSnapshot => $composableBuilder(
    column: $table.labelSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$InspectionsTableAnnotationComposer get inspectionId {
    final $$InspectionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.inspectionId,
      referencedTable: $db.inspections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InspectionsTableAnnotationComposer(
            $db: $db,
            $table: $db.inspections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InspectionDetailedResponsesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InspectionDetailedResponsesTable,
          LocalDetailedResponseRow,
          $$InspectionDetailedResponsesTableFilterComposer,
          $$InspectionDetailedResponsesTableOrderingComposer,
          $$InspectionDetailedResponsesTableAnnotationComposer,
          $$InspectionDetailedResponsesTableCreateCompanionBuilder,
          $$InspectionDetailedResponsesTableUpdateCompanionBuilder,
          (
            LocalDetailedResponseRow,
            $$InspectionDetailedResponsesTableReferences,
          ),
          LocalDetailedResponseRow,
          PrefetchHooks Function({bool inspectionId})
        > {
  $$InspectionDetailedResponsesTableTableManager(
    _$AppDatabase db,
    $InspectionDetailedResponsesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InspectionDetailedResponsesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$InspectionDetailedResponsesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$InspectionDetailedResponsesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> inspectionId = const Value.absent(),
                Value<String> companyId = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> itemKey = const Value.absent(),
                Value<String> labelSnapshot = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String> rating = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InspectionDetailedResponsesCompanion(
                id: id,
                inspectionId: inspectionId,
                companyId: companyId,
                category: category,
                itemKey: itemKey,
                labelSnapshot: labelSnapshot,
                sortOrder: sortOrder,
                rating: rating,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String inspectionId,
                required String companyId,
                required String category,
                required String itemKey,
                required String labelSnapshot,
                required int sortOrder,
                required String rating,
                Value<String?> notes = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => InspectionDetailedResponsesCompanion.insert(
                id: id,
                inspectionId: inspectionId,
                companyId: companyId,
                category: category,
                itemKey: itemKey,
                labelSnapshot: labelSnapshot,
                sortOrder: sortOrder,
                rating: rating,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$InspectionDetailedResponsesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({inspectionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (inspectionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.inspectionId,
                                referencedTable:
                                    $$InspectionDetailedResponsesTableReferences
                                        ._inspectionIdTable(db),
                                referencedColumn:
                                    $$InspectionDetailedResponsesTableReferences
                                        ._inspectionIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$InspectionDetailedResponsesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InspectionDetailedResponsesTable,
      LocalDetailedResponseRow,
      $$InspectionDetailedResponsesTableFilterComposer,
      $$InspectionDetailedResponsesTableOrderingComposer,
      $$InspectionDetailedResponsesTableAnnotationComposer,
      $$InspectionDetailedResponsesTableCreateCompanionBuilder,
      $$InspectionDetailedResponsesTableUpdateCompanionBuilder,
      (LocalDetailedResponseRow, $$InspectionDetailedResponsesTableReferences),
      LocalDetailedResponseRow,
      PrefetchHooks Function({bool inspectionId})
    >;
typedef $$LocalTenantContextsTableCreateCompanionBuilder =
    LocalTenantContextsCompanion Function({
      required String id,
      required String companyId,
      required String userId,
      required DateTime activatedAt,
      Value<int> rowid,
    });
typedef $$LocalTenantContextsTableUpdateCompanionBuilder =
    LocalTenantContextsCompanion Function({
      Value<String> id,
      Value<String> companyId,
      Value<String> userId,
      Value<DateTime> activatedAt,
      Value<int> rowid,
    });

class $$LocalTenantContextsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalTenantContextsTable> {
  $$LocalTenantContextsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get activatedAt => $composableBuilder(
    column: $table.activatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalTenantContextsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalTenantContextsTable> {
  $$LocalTenantContextsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get activatedAt => $composableBuilder(
    column: $table.activatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalTenantContextsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalTenantContextsTable> {
  $$LocalTenantContextsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get companyId =>
      $composableBuilder(column: $table.companyId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<DateTime> get activatedAt => $composableBuilder(
    column: $table.activatedAt,
    builder: (column) => column,
  );
}

class $$LocalTenantContextsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalTenantContextsTable,
          LocalTenantContextRow,
          $$LocalTenantContextsTableFilterComposer,
          $$LocalTenantContextsTableOrderingComposer,
          $$LocalTenantContextsTableAnnotationComposer,
          $$LocalTenantContextsTableCreateCompanionBuilder,
          $$LocalTenantContextsTableUpdateCompanionBuilder,
          (
            LocalTenantContextRow,
            BaseReferences<
              _$AppDatabase,
              $LocalTenantContextsTable,
              LocalTenantContextRow
            >,
          ),
          LocalTenantContextRow,
          PrefetchHooks Function()
        > {
  $$LocalTenantContextsTableTableManager(
    _$AppDatabase db,
    $LocalTenantContextsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalTenantContextsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalTenantContextsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalTenantContextsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> companyId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<DateTime> activatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalTenantContextsCompanion(
                id: id,
                companyId: companyId,
                userId: userId,
                activatedAt: activatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String companyId,
                required String userId,
                required DateTime activatedAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalTenantContextsCompanion.insert(
                id: id,
                companyId: companyId,
                userId: userId,
                activatedAt: activatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalTenantContextsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalTenantContextsTable,
      LocalTenantContextRow,
      $$LocalTenantContextsTableFilterComposer,
      $$LocalTenantContextsTableOrderingComposer,
      $$LocalTenantContextsTableAnnotationComposer,
      $$LocalTenantContextsTableCreateCompanionBuilder,
      $$LocalTenantContextsTableUpdateCompanionBuilder,
      (
        LocalTenantContextRow,
        BaseReferences<
          _$AppDatabase,
          $LocalTenantContextsTable,
          LocalTenantContextRow
        >,
      ),
      LocalTenantContextRow,
      PrefetchHooks Function()
    >;
typedef $$LocalEquipmentCacheTableCreateCompanionBuilder =
    LocalEquipmentCacheCompanion Function({
      required String id,
      required String companyId,
      required String assetName,
      required String manufacturer,
      required String model,
      Value<String?> serialNumber,
      Value<int?> year,
      Value<double?> hours,
      Value<String?> location,
      Value<String?> notes,
      Value<String?> createdBy,
      Value<String?> createdByName,
      Value<String?> updatedBy,
      Value<String?> updatedByName,
      required DateTime createdAt,
      required DateTime updatedAt,
      required DateTime cachedAt,
      Value<int> rowid,
    });
typedef $$LocalEquipmentCacheTableUpdateCompanionBuilder =
    LocalEquipmentCacheCompanion Function({
      Value<String> id,
      Value<String> companyId,
      Value<String> assetName,
      Value<String> manufacturer,
      Value<String> model,
      Value<String?> serialNumber,
      Value<int?> year,
      Value<double?> hours,
      Value<String?> location,
      Value<String?> notes,
      Value<String?> createdBy,
      Value<String?> createdByName,
      Value<String?> updatedBy,
      Value<String?> updatedByName,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$LocalEquipmentCacheTableFilterComposer
    extends Composer<_$AppDatabase, $LocalEquipmentCacheTable> {
  $$LocalEquipmentCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assetName => $composableBuilder(
    column: $table.assetName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get manufacturer => $composableBuilder(
    column: $table.manufacturer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serialNumber => $composableBuilder(
    column: $table.serialNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get hours => $composableBuilder(
    column: $table.hours,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdByName => $composableBuilder(
    column: $table.createdByName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedByName => $composableBuilder(
    column: $table.updatedByName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalEquipmentCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalEquipmentCacheTable> {
  $$LocalEquipmentCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assetName => $composableBuilder(
    column: $table.assetName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get manufacturer => $composableBuilder(
    column: $table.manufacturer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serialNumber => $composableBuilder(
    column: $table.serialNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get hours => $composableBuilder(
    column: $table.hours,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdByName => $composableBuilder(
    column: $table.createdByName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedByName => $composableBuilder(
    column: $table.updatedByName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalEquipmentCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalEquipmentCacheTable> {
  $$LocalEquipmentCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get companyId =>
      $composableBuilder(column: $table.companyId, builder: (column) => column);

  GeneratedColumn<String> get assetName =>
      $composableBuilder(column: $table.assetName, builder: (column) => column);

  GeneratedColumn<String> get manufacturer => $composableBuilder(
    column: $table.manufacturer,
    builder: (column) => column,
  );

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<String> get serialNumber => $composableBuilder(
    column: $table.serialNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<double> get hours =>
      $composableBuilder(column: $table.hours, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<String> get createdByName => $composableBuilder(
    column: $table.createdByName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get updatedBy =>
      $composableBuilder(column: $table.updatedBy, builder: (column) => column);

  GeneratedColumn<String> get updatedByName => $composableBuilder(
    column: $table.updatedByName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$LocalEquipmentCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalEquipmentCacheTable,
          LocalEquipmentCacheRow,
          $$LocalEquipmentCacheTableFilterComposer,
          $$LocalEquipmentCacheTableOrderingComposer,
          $$LocalEquipmentCacheTableAnnotationComposer,
          $$LocalEquipmentCacheTableCreateCompanionBuilder,
          $$LocalEquipmentCacheTableUpdateCompanionBuilder,
          (
            LocalEquipmentCacheRow,
            BaseReferences<
              _$AppDatabase,
              $LocalEquipmentCacheTable,
              LocalEquipmentCacheRow
            >,
          ),
          LocalEquipmentCacheRow,
          PrefetchHooks Function()
        > {
  $$LocalEquipmentCacheTableTableManager(
    _$AppDatabase db,
    $LocalEquipmentCacheTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalEquipmentCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalEquipmentCacheTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalEquipmentCacheTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> companyId = const Value.absent(),
                Value<String> assetName = const Value.absent(),
                Value<String> manufacturer = const Value.absent(),
                Value<String> model = const Value.absent(),
                Value<String?> serialNumber = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<double?> hours = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> createdBy = const Value.absent(),
                Value<String?> createdByName = const Value.absent(),
                Value<String?> updatedBy = const Value.absent(),
                Value<String?> updatedByName = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalEquipmentCacheCompanion(
                id: id,
                companyId: companyId,
                assetName: assetName,
                manufacturer: manufacturer,
                model: model,
                serialNumber: serialNumber,
                year: year,
                hours: hours,
                location: location,
                notes: notes,
                createdBy: createdBy,
                createdByName: createdByName,
                updatedBy: updatedBy,
                updatedByName: updatedByName,
                createdAt: createdAt,
                updatedAt: updatedAt,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String companyId,
                required String assetName,
                required String manufacturer,
                required String model,
                Value<String?> serialNumber = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<double?> hours = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> createdBy = const Value.absent(),
                Value<String?> createdByName = const Value.absent(),
                Value<String?> updatedBy = const Value.absent(),
                Value<String?> updatedByName = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                required DateTime cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalEquipmentCacheCompanion.insert(
                id: id,
                companyId: companyId,
                assetName: assetName,
                manufacturer: manufacturer,
                model: model,
                serialNumber: serialNumber,
                year: year,
                hours: hours,
                location: location,
                notes: notes,
                createdBy: createdBy,
                createdByName: createdByName,
                updatedBy: updatedBy,
                updatedByName: updatedByName,
                createdAt: createdAt,
                updatedAt: updatedAt,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalEquipmentCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalEquipmentCacheTable,
      LocalEquipmentCacheRow,
      $$LocalEquipmentCacheTableFilterComposer,
      $$LocalEquipmentCacheTableOrderingComposer,
      $$LocalEquipmentCacheTableAnnotationComposer,
      $$LocalEquipmentCacheTableCreateCompanionBuilder,
      $$LocalEquipmentCacheTableUpdateCompanionBuilder,
      (
        LocalEquipmentCacheRow,
        BaseReferences<
          _$AppDatabase,
          $LocalEquipmentCacheTable,
          LocalEquipmentCacheRow
        >,
      ),
      LocalEquipmentCacheRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$InspectionsTableTableManager get inspections =>
      $$InspectionsTableTableManager(_db, _db.inspections);
  $$InspectionCategoryRatingsTableTableManager get inspectionCategoryRatings =>
      $$InspectionCategoryRatingsTableTableManager(
        _db,
        _db.inspectionCategoryRatings,
      );
  $$InspectionDetailedResponsesTableTableManager
  get inspectionDetailedResponses =>
      $$InspectionDetailedResponsesTableTableManager(
        _db,
        _db.inspectionDetailedResponses,
      );
  $$LocalTenantContextsTableTableManager get localTenantContexts =>
      $$LocalTenantContextsTableTableManager(_db, _db.localTenantContexts);
  $$LocalEquipmentCacheTableTableManager get localEquipmentCache =>
      $$LocalEquipmentCacheTableTableManager(_db, _db.localEquipmentCache);
}
