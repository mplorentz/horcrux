// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $VaultsTable extends Vaults with TableInfo<$VaultsTable, VaultRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VaultsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ownerPubkeyMeta =
      const VerificationMeta('ownerPubkey');
  @override
  late final GeneratedColumn<String> ownerPubkey = GeneratedColumn<String>(
      'owner_pubkey', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ownerNameMeta =
      const VerificationMeta('ownerName');
  @override
  late final GeneratedColumn<String> ownerName = GeneratedColumn<String>(
      'owner_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _thresholdMeta =
      const VerificationMeta('threshold');
  @override
  late final GeneratedColumn<int> threshold = GeneratedColumn<int>(
      'threshold', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _primeModMeta =
      const VerificationMeta('primeMod');
  @override
  late final GeneratedColumn<String> primeMod = GeneratedColumn<String>(
      'prime_mod', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _totalSharesMeta =
      const VerificationMeta('totalShares');
  @override
  late final GeneratedColumn<int> totalShares = GeneratedColumn<int>(
      'total_shares', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _currentDistributionVersionMeta =
      const VerificationMeta('currentDistributionVersion');
  @override
  late final GeneratedColumn<int> currentDistributionVersion =
      GeneratedColumn<int>('current_distribution_version', aliasedName, false,
          type: DriftSqlType.int,
          requiredDuringInsert: false,
          defaultValue: const Constant(0));
  static const VerificationMeta _instructionsMeta =
      const VerificationMeta('instructions');
  @override
  late final GeneratedColumn<String> instructions = GeneratedColumn<String>(
      'instructions', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _pushEnabledMeta =
      const VerificationMeta('pushEnabled');
  @override
  late final GeneratedColumn<bool> pushEnabled = GeneratedColumn<bool>(
      'push_enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("push_enabled" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _archivedAtMeta =
      const VerificationMeta('archivedAt');
  @override
  late final GeneratedColumn<int> archivedAt = GeneratedColumn<int>(
      'archived_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _archivedReasonMeta =
      const VerificationMeta('archivedReason');
  @override
  late final GeneratedColumn<String> archivedReason = GeneratedColumn<String>(
      'archived_reason', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastSyncedAtMeta =
      const VerificationMeta('lastSyncedAt');
  @override
  late final GeneratedColumn<int> lastSyncedAt = GeneratedColumn<int>(
      'last_synced_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        ownerPubkey,
        ownerName,
        threshold,
        primeMod,
        totalShares,
        currentDistributionVersion,
        instructions,
        pushEnabled,
        archivedAt,
        archivedReason,
        lastSyncedAt,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vaults';
  @override
  VerificationContext validateIntegrity(Insertable<VaultRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('owner_pubkey')) {
      context.handle(
          _ownerPubkeyMeta,
          ownerPubkey.isAcceptableOrUnknown(
              data['owner_pubkey']!, _ownerPubkeyMeta));
    } else if (isInserting) {
      context.missing(_ownerPubkeyMeta);
    }
    if (data.containsKey('owner_name')) {
      context.handle(_ownerNameMeta,
          ownerName.isAcceptableOrUnknown(data['owner_name']!, _ownerNameMeta));
    }
    if (data.containsKey('threshold')) {
      context.handle(_thresholdMeta,
          threshold.isAcceptableOrUnknown(data['threshold']!, _thresholdMeta));
    } else if (isInserting) {
      context.missing(_thresholdMeta);
    }
    if (data.containsKey('prime_mod')) {
      context.handle(_primeModMeta,
          primeMod.isAcceptableOrUnknown(data['prime_mod']!, _primeModMeta));
    }
    if (data.containsKey('total_shares')) {
      context.handle(
          _totalSharesMeta,
          totalShares.isAcceptableOrUnknown(
              data['total_shares']!, _totalSharesMeta));
    } else if (isInserting) {
      context.missing(_totalSharesMeta);
    }
    if (data.containsKey('current_distribution_version')) {
      context.handle(
          _currentDistributionVersionMeta,
          currentDistributionVersion.isAcceptableOrUnknown(
              data['current_distribution_version']!,
              _currentDistributionVersionMeta));
    }
    if (data.containsKey('instructions')) {
      context.handle(
          _instructionsMeta,
          instructions.isAcceptableOrUnknown(
              data['instructions']!, _instructionsMeta));
    }
    if (data.containsKey('push_enabled')) {
      context.handle(
          _pushEnabledMeta,
          pushEnabled.isAcceptableOrUnknown(
              data['push_enabled']!, _pushEnabledMeta));
    }
    if (data.containsKey('archived_at')) {
      context.handle(
          _archivedAtMeta,
          archivedAt.isAcceptableOrUnknown(
              data['archived_at']!, _archivedAtMeta));
    }
    if (data.containsKey('archived_reason')) {
      context.handle(
          _archivedReasonMeta,
          archivedReason.isAcceptableOrUnknown(
              data['archived_reason']!, _archivedReasonMeta));
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
          _lastSyncedAtMeta,
          lastSyncedAt.isAcceptableOrUnknown(
              data['last_synced_at']!, _lastSyncedAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VaultRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VaultRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      ownerPubkey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}owner_pubkey'])!,
      ownerName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}owner_name']),
      threshold: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}threshold'])!,
      primeMod: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}prime_mod']),
      totalShares: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_shares'])!,
      currentDistributionVersion: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}current_distribution_version'])!,
      instructions: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}instructions']),
      pushEnabled: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}push_enabled'])!,
      archivedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}archived_at']),
      archivedReason: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}archived_reason']),
      lastSyncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_synced_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $VaultsTable createAlias(String alias) {
    return $VaultsTable(attachedDatabase, alias);
  }
}

class VaultRow extends DataClass implements Insertable<VaultRow> {
  final String id;
  final String name;
  final String ownerPubkey;
  final String? ownerName;
  final int threshold;
  final String? primeMod;
  final int totalShares;

  /// Owner-side: highest distribution version this device has authored.
  /// Steward-side: version of the most recent ingested share for this vault.
  final int currentDistributionVersion;
  final String? instructions;

  /// Owner-authored gate. `false` suppresses all push send paths for this
  /// vault, regardless of any steward's local opt-in. See "Push notification
  /// flags" in the refactor plan.
  final bool pushEnabled;

  /// Local-only soft delete. Cascades happen on hard delete only.
  final int? archivedAt;
  final String? archivedReason;

  /// Steward-side timestamp for the last successful ingest from a relay; null
  /// on owner devices.
  final int? lastSyncedAt;
  final int createdAt;
  const VaultRow(
      {required this.id,
      required this.name,
      required this.ownerPubkey,
      this.ownerName,
      required this.threshold,
      this.primeMod,
      required this.totalShares,
      required this.currentDistributionVersion,
      this.instructions,
      required this.pushEnabled,
      this.archivedAt,
      this.archivedReason,
      this.lastSyncedAt,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['owner_pubkey'] = Variable<String>(ownerPubkey);
    if (!nullToAbsent || ownerName != null) {
      map['owner_name'] = Variable<String>(ownerName);
    }
    map['threshold'] = Variable<int>(threshold);
    if (!nullToAbsent || primeMod != null) {
      map['prime_mod'] = Variable<String>(primeMod);
    }
    map['total_shares'] = Variable<int>(totalShares);
    map['current_distribution_version'] =
        Variable<int>(currentDistributionVersion);
    if (!nullToAbsent || instructions != null) {
      map['instructions'] = Variable<String>(instructions);
    }
    map['push_enabled'] = Variable<bool>(pushEnabled);
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<int>(archivedAt);
    }
    if (!nullToAbsent || archivedReason != null) {
      map['archived_reason'] = Variable<String>(archivedReason);
    }
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<int>(lastSyncedAt);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  VaultsCompanion toCompanion(bool nullToAbsent) {
    return VaultsCompanion(
      id: Value(id),
      name: Value(name),
      ownerPubkey: Value(ownerPubkey),
      ownerName: ownerName == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerName),
      threshold: Value(threshold),
      primeMod: primeMod == null && nullToAbsent
          ? const Value.absent()
          : Value(primeMod),
      totalShares: Value(totalShares),
      currentDistributionVersion: Value(currentDistributionVersion),
      instructions: instructions == null && nullToAbsent
          ? const Value.absent()
          : Value(instructions),
      pushEnabled: Value(pushEnabled),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
      archivedReason: archivedReason == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedReason),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      createdAt: Value(createdAt),
    );
  }

  factory VaultRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VaultRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      ownerPubkey: serializer.fromJson<String>(json['ownerPubkey']),
      ownerName: serializer.fromJson<String?>(json['ownerName']),
      threshold: serializer.fromJson<int>(json['threshold']),
      primeMod: serializer.fromJson<String?>(json['primeMod']),
      totalShares: serializer.fromJson<int>(json['totalShares']),
      currentDistributionVersion:
          serializer.fromJson<int>(json['currentDistributionVersion']),
      instructions: serializer.fromJson<String?>(json['instructions']),
      pushEnabled: serializer.fromJson<bool>(json['pushEnabled']),
      archivedAt: serializer.fromJson<int?>(json['archivedAt']),
      archivedReason: serializer.fromJson<String?>(json['archivedReason']),
      lastSyncedAt: serializer.fromJson<int?>(json['lastSyncedAt']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'ownerPubkey': serializer.toJson<String>(ownerPubkey),
      'ownerName': serializer.toJson<String?>(ownerName),
      'threshold': serializer.toJson<int>(threshold),
      'primeMod': serializer.toJson<String?>(primeMod),
      'totalShares': serializer.toJson<int>(totalShares),
      'currentDistributionVersion':
          serializer.toJson<int>(currentDistributionVersion),
      'instructions': serializer.toJson<String?>(instructions),
      'pushEnabled': serializer.toJson<bool>(pushEnabled),
      'archivedAt': serializer.toJson<int?>(archivedAt),
      'archivedReason': serializer.toJson<String?>(archivedReason),
      'lastSyncedAt': serializer.toJson<int?>(lastSyncedAt),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  VaultRow copyWith(
          {String? id,
          String? name,
          String? ownerPubkey,
          Value<String?> ownerName = const Value.absent(),
          int? threshold,
          Value<String?> primeMod = const Value.absent(),
          int? totalShares,
          int? currentDistributionVersion,
          Value<String?> instructions = const Value.absent(),
          bool? pushEnabled,
          Value<int?> archivedAt = const Value.absent(),
          Value<String?> archivedReason = const Value.absent(),
          Value<int?> lastSyncedAt = const Value.absent(),
          int? createdAt}) =>
      VaultRow(
        id: id ?? this.id,
        name: name ?? this.name,
        ownerPubkey: ownerPubkey ?? this.ownerPubkey,
        ownerName: ownerName.present ? ownerName.value : this.ownerName,
        threshold: threshold ?? this.threshold,
        primeMod: primeMod.present ? primeMod.value : this.primeMod,
        totalShares: totalShares ?? this.totalShares,
        currentDistributionVersion:
            currentDistributionVersion ?? this.currentDistributionVersion,
        instructions:
            instructions.present ? instructions.value : this.instructions,
        pushEnabled: pushEnabled ?? this.pushEnabled,
        archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
        archivedReason:
            archivedReason.present ? archivedReason.value : this.archivedReason,
        lastSyncedAt:
            lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
        createdAt: createdAt ?? this.createdAt,
      );
  VaultRow copyWithCompanion(VaultsCompanion data) {
    return VaultRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      ownerPubkey:
          data.ownerPubkey.present ? data.ownerPubkey.value : this.ownerPubkey,
      ownerName: data.ownerName.present ? data.ownerName.value : this.ownerName,
      threshold: data.threshold.present ? data.threshold.value : this.threshold,
      primeMod: data.primeMod.present ? data.primeMod.value : this.primeMod,
      totalShares:
          data.totalShares.present ? data.totalShares.value : this.totalShares,
      currentDistributionVersion: data.currentDistributionVersion.present
          ? data.currentDistributionVersion.value
          : this.currentDistributionVersion,
      instructions: data.instructions.present
          ? data.instructions.value
          : this.instructions,
      pushEnabled:
          data.pushEnabled.present ? data.pushEnabled.value : this.pushEnabled,
      archivedAt:
          data.archivedAt.present ? data.archivedAt.value : this.archivedAt,
      archivedReason: data.archivedReason.present
          ? data.archivedReason.value
          : this.archivedReason,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VaultRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('ownerPubkey: $ownerPubkey, ')
          ..write('ownerName: $ownerName, ')
          ..write('threshold: $threshold, ')
          ..write('primeMod: $primeMod, ')
          ..write('totalShares: $totalShares, ')
          ..write('currentDistributionVersion: $currentDistributionVersion, ')
          ..write('instructions: $instructions, ')
          ..write('pushEnabled: $pushEnabled, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('archivedReason: $archivedReason, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      name,
      ownerPubkey,
      ownerName,
      threshold,
      primeMod,
      totalShares,
      currentDistributionVersion,
      instructions,
      pushEnabled,
      archivedAt,
      archivedReason,
      lastSyncedAt,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VaultRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.ownerPubkey == this.ownerPubkey &&
          other.ownerName == this.ownerName &&
          other.threshold == this.threshold &&
          other.primeMod == this.primeMod &&
          other.totalShares == this.totalShares &&
          other.currentDistributionVersion == this.currentDistributionVersion &&
          other.instructions == this.instructions &&
          other.pushEnabled == this.pushEnabled &&
          other.archivedAt == this.archivedAt &&
          other.archivedReason == this.archivedReason &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.createdAt == this.createdAt);
}

class VaultsCompanion extends UpdateCompanion<VaultRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> ownerPubkey;
  final Value<String?> ownerName;
  final Value<int> threshold;
  final Value<String?> primeMod;
  final Value<int> totalShares;
  final Value<int> currentDistributionVersion;
  final Value<String?> instructions;
  final Value<bool> pushEnabled;
  final Value<int?> archivedAt;
  final Value<String?> archivedReason;
  final Value<int?> lastSyncedAt;
  final Value<int> createdAt;
  final Value<int> rowid;
  const VaultsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.ownerPubkey = const Value.absent(),
    this.ownerName = const Value.absent(),
    this.threshold = const Value.absent(),
    this.primeMod = const Value.absent(),
    this.totalShares = const Value.absent(),
    this.currentDistributionVersion = const Value.absent(),
    this.instructions = const Value.absent(),
    this.pushEnabled = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.archivedReason = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VaultsCompanion.insert({
    required String id,
    required String name,
    required String ownerPubkey,
    this.ownerName = const Value.absent(),
    required int threshold,
    this.primeMod = const Value.absent(),
    required int totalShares,
    this.currentDistributionVersion = const Value.absent(),
    this.instructions = const Value.absent(),
    this.pushEnabled = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.archivedReason = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        ownerPubkey = Value(ownerPubkey),
        threshold = Value(threshold),
        totalShares = Value(totalShares),
        createdAt = Value(createdAt);
  static Insertable<VaultRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? ownerPubkey,
    Expression<String>? ownerName,
    Expression<int>? threshold,
    Expression<String>? primeMod,
    Expression<int>? totalShares,
    Expression<int>? currentDistributionVersion,
    Expression<String>? instructions,
    Expression<bool>? pushEnabled,
    Expression<int>? archivedAt,
    Expression<String>? archivedReason,
    Expression<int>? lastSyncedAt,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (ownerPubkey != null) 'owner_pubkey': ownerPubkey,
      if (ownerName != null) 'owner_name': ownerName,
      if (threshold != null) 'threshold': threshold,
      if (primeMod != null) 'prime_mod': primeMod,
      if (totalShares != null) 'total_shares': totalShares,
      if (currentDistributionVersion != null)
        'current_distribution_version': currentDistributionVersion,
      if (instructions != null) 'instructions': instructions,
      if (pushEnabled != null) 'push_enabled': pushEnabled,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (archivedReason != null) 'archived_reason': archivedReason,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VaultsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? ownerPubkey,
      Value<String?>? ownerName,
      Value<int>? threshold,
      Value<String?>? primeMod,
      Value<int>? totalShares,
      Value<int>? currentDistributionVersion,
      Value<String?>? instructions,
      Value<bool>? pushEnabled,
      Value<int?>? archivedAt,
      Value<String?>? archivedReason,
      Value<int?>? lastSyncedAt,
      Value<int>? createdAt,
      Value<int>? rowid}) {
    return VaultsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerPubkey: ownerPubkey ?? this.ownerPubkey,
      ownerName: ownerName ?? this.ownerName,
      threshold: threshold ?? this.threshold,
      primeMod: primeMod ?? this.primeMod,
      totalShares: totalShares ?? this.totalShares,
      currentDistributionVersion:
          currentDistributionVersion ?? this.currentDistributionVersion,
      instructions: instructions ?? this.instructions,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      archivedAt: archivedAt ?? this.archivedAt,
      archivedReason: archivedReason ?? this.archivedReason,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (ownerPubkey.present) {
      map['owner_pubkey'] = Variable<String>(ownerPubkey.value);
    }
    if (ownerName.present) {
      map['owner_name'] = Variable<String>(ownerName.value);
    }
    if (threshold.present) {
      map['threshold'] = Variable<int>(threshold.value);
    }
    if (primeMod.present) {
      map['prime_mod'] = Variable<String>(primeMod.value);
    }
    if (totalShares.present) {
      map['total_shares'] = Variable<int>(totalShares.value);
    }
    if (currentDistributionVersion.present) {
      map['current_distribution_version'] =
          Variable<int>(currentDistributionVersion.value);
    }
    if (instructions.present) {
      map['instructions'] = Variable<String>(instructions.value);
    }
    if (pushEnabled.present) {
      map['push_enabled'] = Variable<bool>(pushEnabled.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<int>(archivedAt.value);
    }
    if (archivedReason.present) {
      map['archived_reason'] = Variable<String>(archivedReason.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<int>(lastSyncedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VaultsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('ownerPubkey: $ownerPubkey, ')
          ..write('ownerName: $ownerName, ')
          ..write('threshold: $threshold, ')
          ..write('primeMod: $primeMod, ')
          ..write('totalShares: $totalShares, ')
          ..write('currentDistributionVersion: $currentDistributionVersion, ')
          ..write('instructions: $instructions, ')
          ..write('pushEnabled: $pushEnabled, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('archivedReason: $archivedReason, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VaultRelaysTable extends VaultRelays
    with TableInfo<$VaultRelaysTable, VaultRelayRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VaultRelaysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _vaultIdMeta =
      const VerificationMeta('vaultId');
  @override
  late final GeneratedColumn<String> vaultId = GeneratedColumn<String>(
      'vault_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES vaults (id) ON DELETE CASCADE'));
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
      'url', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
      'role', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _addedAtMeta =
      const VerificationMeta('addedAt');
  @override
  late final GeneratedColumn<int> addedAt = GeneratedColumn<int>(
      'added_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, vaultId, url, role, addedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vault_relays';
  @override
  VerificationContext validateIntegrity(Insertable<VaultRelayRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('vault_id')) {
      context.handle(_vaultIdMeta,
          vaultId.isAcceptableOrUnknown(data['vault_id']!, _vaultIdMeta));
    } else if (isInserting) {
      context.missing(_vaultIdMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
          _urlMeta, url.isAcceptableOrUnknown(data['url']!, _urlMeta));
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
          _roleMeta, role.isAcceptableOrUnknown(data['role']!, _roleMeta));
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('added_at')) {
      context.handle(_addedAtMeta,
          addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta));
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VaultRelayRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VaultRelayRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      vaultId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}vault_id'])!,
      url: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}url'])!,
      role: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}role'])!,
      addedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}added_at'])!,
    );
  }

  @override
  $VaultRelaysTable createAlias(String alias) {
    return $VaultRelaysTable(attachedDatabase, alias);
  }
}

class VaultRelayRow extends DataClass implements Insertable<VaultRelayRow> {
  final String id;
  final String vaultId;
  final String url;
  final String role;
  final int addedAt;
  const VaultRelayRow(
      {required this.id,
      required this.vaultId,
      required this.url,
      required this.role,
      required this.addedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['vault_id'] = Variable<String>(vaultId);
    map['url'] = Variable<String>(url);
    map['role'] = Variable<String>(role);
    map['added_at'] = Variable<int>(addedAt);
    return map;
  }

  VaultRelaysCompanion toCompanion(bool nullToAbsent) {
    return VaultRelaysCompanion(
      id: Value(id),
      vaultId: Value(vaultId),
      url: Value(url),
      role: Value(role),
      addedAt: Value(addedAt),
    );
  }

  factory VaultRelayRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VaultRelayRow(
      id: serializer.fromJson<String>(json['id']),
      vaultId: serializer.fromJson<String>(json['vaultId']),
      url: serializer.fromJson<String>(json['url']),
      role: serializer.fromJson<String>(json['role']),
      addedAt: serializer.fromJson<int>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'vaultId': serializer.toJson<String>(vaultId),
      'url': serializer.toJson<String>(url),
      'role': serializer.toJson<String>(role),
      'addedAt': serializer.toJson<int>(addedAt),
    };
  }

  VaultRelayRow copyWith(
          {String? id,
          String? vaultId,
          String? url,
          String? role,
          int? addedAt}) =>
      VaultRelayRow(
        id: id ?? this.id,
        vaultId: vaultId ?? this.vaultId,
        url: url ?? this.url,
        role: role ?? this.role,
        addedAt: addedAt ?? this.addedAt,
      );
  VaultRelayRow copyWithCompanion(VaultRelaysCompanion data) {
    return VaultRelayRow(
      id: data.id.present ? data.id.value : this.id,
      vaultId: data.vaultId.present ? data.vaultId.value : this.vaultId,
      url: data.url.present ? data.url.value : this.url,
      role: data.role.present ? data.role.value : this.role,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VaultRelayRow(')
          ..write('id: $id, ')
          ..write('vaultId: $vaultId, ')
          ..write('url: $url, ')
          ..write('role: $role, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, vaultId, url, role, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VaultRelayRow &&
          other.id == this.id &&
          other.vaultId == this.vaultId &&
          other.url == this.url &&
          other.role == this.role &&
          other.addedAt == this.addedAt);
}

class VaultRelaysCompanion extends UpdateCompanion<VaultRelayRow> {
  final Value<String> id;
  final Value<String> vaultId;
  final Value<String> url;
  final Value<String> role;
  final Value<int> addedAt;
  final Value<int> rowid;
  const VaultRelaysCompanion({
    this.id = const Value.absent(),
    this.vaultId = const Value.absent(),
    this.url = const Value.absent(),
    this.role = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VaultRelaysCompanion.insert({
    required String id,
    required String vaultId,
    required String url,
    required String role,
    required int addedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        vaultId = Value(vaultId),
        url = Value(url),
        role = Value(role),
        addedAt = Value(addedAt);
  static Insertable<VaultRelayRow> custom({
    Expression<String>? id,
    Expression<String>? vaultId,
    Expression<String>? url,
    Expression<String>? role,
    Expression<int>? addedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (vaultId != null) 'vault_id': vaultId,
      if (url != null) 'url': url,
      if (role != null) 'role': role,
      if (addedAt != null) 'added_at': addedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VaultRelaysCompanion copyWith(
      {Value<String>? id,
      Value<String>? vaultId,
      Value<String>? url,
      Value<String>? role,
      Value<int>? addedAt,
      Value<int>? rowid}) {
    return VaultRelaysCompanion(
      id: id ?? this.id,
      vaultId: vaultId ?? this.vaultId,
      url: url ?? this.url,
      role: role ?? this.role,
      addedAt: addedAt ?? this.addedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (vaultId.present) {
      map['vault_id'] = Variable<String>(vaultId.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<int>(addedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VaultRelaysCompanion(')
          ..write('id: $id, ')
          ..write('vaultId: $vaultId, ')
          ..write('url: $url, ')
          ..write('role: $role, ')
          ..write('addedAt: $addedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OwnedVaultsTable extends OwnedVaults
    with TableInfo<$OwnedVaultsTable, OwnedVaultRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OwnedVaultsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _vaultIdMeta =
      const VerificationMeta('vaultId');
  @override
  late final GeneratedColumn<String> vaultId = GeneratedColumn<String>(
      'vault_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES vaults (id) ON DELETE CASCADE'));
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contentHmacMeta =
      const VerificationMeta('contentHmac');
  @override
  late final GeneratedColumn<Uint8List> contentHmac =
      GeneratedColumn<Uint8List>('content_hmac', aliasedName, false,
          type: DriftSqlType.blob, requiredDuringInsert: true);
  static const VerificationMeta _createdBySelfAtMeta =
      const VerificationMeta('createdBySelfAt');
  @override
  late final GeneratedColumn<int> createdBySelfAt = GeneratedColumn<int>(
      'created_by_self_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [vaultId, content, contentHmac, createdBySelfAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'owned_vaults';
  @override
  VerificationContext validateIntegrity(Insertable<OwnedVaultRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('vault_id')) {
      context.handle(_vaultIdMeta,
          vaultId.isAcceptableOrUnknown(data['vault_id']!, _vaultIdMeta));
    } else if (isInserting) {
      context.missing(_vaultIdMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('content_hmac')) {
      context.handle(
          _contentHmacMeta,
          contentHmac.isAcceptableOrUnknown(
              data['content_hmac']!, _contentHmacMeta));
    } else if (isInserting) {
      context.missing(_contentHmacMeta);
    }
    if (data.containsKey('created_by_self_at')) {
      context.handle(
          _createdBySelfAtMeta,
          createdBySelfAt.isAcceptableOrUnknown(
              data['created_by_self_at']!, _createdBySelfAtMeta));
    } else if (isInserting) {
      context.missing(_createdBySelfAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {vaultId};
  @override
  OwnedVaultRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OwnedVaultRow(
      vaultId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}vault_id'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      contentHmac: attachedDatabase.typeMapping
          .read(DriftSqlType.blob, data['${effectivePrefix}content_hmac'])!,
      createdBySelfAt: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}created_by_self_at'])!,
    );
  }

  @override
  $OwnedVaultsTable createAlias(String alias) {
    return $OwnedVaultsTable(attachedDatabase, alias);
  }
}

class OwnedVaultRow extends DataClass implements Insertable<OwnedVaultRow> {
  final String vaultId;
  final String content;
  final Uint8List contentHmac;
  final int createdBySelfAt;
  const OwnedVaultRow(
      {required this.vaultId,
      required this.content,
      required this.contentHmac,
      required this.createdBySelfAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['vault_id'] = Variable<String>(vaultId);
    map['content'] = Variable<String>(content);
    map['content_hmac'] = Variable<Uint8List>(contentHmac);
    map['created_by_self_at'] = Variable<int>(createdBySelfAt);
    return map;
  }

  OwnedVaultsCompanion toCompanion(bool nullToAbsent) {
    return OwnedVaultsCompanion(
      vaultId: Value(vaultId),
      content: Value(content),
      contentHmac: Value(contentHmac),
      createdBySelfAt: Value(createdBySelfAt),
    );
  }

  factory OwnedVaultRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OwnedVaultRow(
      vaultId: serializer.fromJson<String>(json['vaultId']),
      content: serializer.fromJson<String>(json['content']),
      contentHmac: serializer.fromJson<Uint8List>(json['contentHmac']),
      createdBySelfAt: serializer.fromJson<int>(json['createdBySelfAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'vaultId': serializer.toJson<String>(vaultId),
      'content': serializer.toJson<String>(content),
      'contentHmac': serializer.toJson<Uint8List>(contentHmac),
      'createdBySelfAt': serializer.toJson<int>(createdBySelfAt),
    };
  }

  OwnedVaultRow copyWith(
          {String? vaultId,
          String? content,
          Uint8List? contentHmac,
          int? createdBySelfAt}) =>
      OwnedVaultRow(
        vaultId: vaultId ?? this.vaultId,
        content: content ?? this.content,
        contentHmac: contentHmac ?? this.contentHmac,
        createdBySelfAt: createdBySelfAt ?? this.createdBySelfAt,
      );
  OwnedVaultRow copyWithCompanion(OwnedVaultsCompanion data) {
    return OwnedVaultRow(
      vaultId: data.vaultId.present ? data.vaultId.value : this.vaultId,
      content: data.content.present ? data.content.value : this.content,
      contentHmac:
          data.contentHmac.present ? data.contentHmac.value : this.contentHmac,
      createdBySelfAt: data.createdBySelfAt.present
          ? data.createdBySelfAt.value
          : this.createdBySelfAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OwnedVaultRow(')
          ..write('vaultId: $vaultId, ')
          ..write('content: $content, ')
          ..write('contentHmac: $contentHmac, ')
          ..write('createdBySelfAt: $createdBySelfAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      vaultId, content, $driftBlobEquality.hash(contentHmac), createdBySelfAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OwnedVaultRow &&
          other.vaultId == this.vaultId &&
          other.content == this.content &&
          $driftBlobEquality.equals(other.contentHmac, this.contentHmac) &&
          other.createdBySelfAt == this.createdBySelfAt);
}

class OwnedVaultsCompanion extends UpdateCompanion<OwnedVaultRow> {
  final Value<String> vaultId;
  final Value<String> content;
  final Value<Uint8List> contentHmac;
  final Value<int> createdBySelfAt;
  final Value<int> rowid;
  const OwnedVaultsCompanion({
    this.vaultId = const Value.absent(),
    this.content = const Value.absent(),
    this.contentHmac = const Value.absent(),
    this.createdBySelfAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OwnedVaultsCompanion.insert({
    required String vaultId,
    required String content,
    required Uint8List contentHmac,
    required int createdBySelfAt,
    this.rowid = const Value.absent(),
  })  : vaultId = Value(vaultId),
        content = Value(content),
        contentHmac = Value(contentHmac),
        createdBySelfAt = Value(createdBySelfAt);
  static Insertable<OwnedVaultRow> custom({
    Expression<String>? vaultId,
    Expression<String>? content,
    Expression<Uint8List>? contentHmac,
    Expression<int>? createdBySelfAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (vaultId != null) 'vault_id': vaultId,
      if (content != null) 'content': content,
      if (contentHmac != null) 'content_hmac': contentHmac,
      if (createdBySelfAt != null) 'created_by_self_at': createdBySelfAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OwnedVaultsCompanion copyWith(
      {Value<String>? vaultId,
      Value<String>? content,
      Value<Uint8List>? contentHmac,
      Value<int>? createdBySelfAt,
      Value<int>? rowid}) {
    return OwnedVaultsCompanion(
      vaultId: vaultId ?? this.vaultId,
      content: content ?? this.content,
      contentHmac: contentHmac ?? this.contentHmac,
      createdBySelfAt: createdBySelfAt ?? this.createdBySelfAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (vaultId.present) {
      map['vault_id'] = Variable<String>(vaultId.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (contentHmac.present) {
      map['content_hmac'] = Variable<Uint8List>(contentHmac.value);
    }
    if (createdBySelfAt.present) {
      map['created_by_self_at'] = Variable<int>(createdBySelfAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OwnedVaultsCompanion(')
          ..write('vaultId: $vaultId, ')
          ..write('content: $content, ')
          ..write('contentHmac: $contentHmac, ')
          ..write('createdBySelfAt: $createdBySelfAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StewardsTable extends Stewards
    with TableInfo<$StewardsTable, StewardRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StewardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _vaultIdMeta =
      const VerificationMeta('vaultId');
  @override
  late final GeneratedColumn<String> vaultId = GeneratedColumn<String>(
      'vault_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES vaults (id) ON DELETE CASCADE'));
  static const VerificationMeta _shareIndexMeta =
      const VerificationMeta('shareIndex');
  @override
  late final GeneratedColumn<int> shareIndex = GeneratedColumn<int>(
      'share_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _pubkeyMeta = const VerificationMeta('pubkey');
  @override
  late final GeneratedColumn<String> pubkey = GeneratedColumn<String>(
      'pubkey', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _contactInfoMeta =
      const VerificationMeta('contactInfo');
  @override
  late final GeneratedColumn<String> contactInfo = GeneratedColumn<String>(
      'contact_info', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isOwnerMeta =
      const VerificationMeta('isOwner');
  @override
  late final GeneratedColumn<bool> isOwner = GeneratedColumn<bool>(
      'is_owner', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_owner" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _joinedAtMeta =
      const VerificationMeta('joinedAt');
  @override
  late final GeneratedColumn<int> joinedAt = GeneratedColumn<int>(
      'joined_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _leftAtMeta = const VerificationMeta('leftAt');
  @override
  late final GeneratedColumn<int> leftAt = GeneratedColumn<int>(
      'left_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _removalReasonMeta =
      const VerificationMeta('removalReason');
  @override
  late final GeneratedColumn<String> removalReason = GeneratedColumn<String>(
      'removal_reason', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        vaultId,
        shareIndex,
        pubkey,
        name,
        contactInfo,
        isOwner,
        joinedAt,
        leftAt,
        removalReason
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stewards';
  @override
  VerificationContext validateIntegrity(Insertable<StewardRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('vault_id')) {
      context.handle(_vaultIdMeta,
          vaultId.isAcceptableOrUnknown(data['vault_id']!, _vaultIdMeta));
    } else if (isInserting) {
      context.missing(_vaultIdMeta);
    }
    if (data.containsKey('share_index')) {
      context.handle(
          _shareIndexMeta,
          shareIndex.isAcceptableOrUnknown(
              data['share_index']!, _shareIndexMeta));
    } else if (isInserting) {
      context.missing(_shareIndexMeta);
    }
    if (data.containsKey('pubkey')) {
      context.handle(_pubkeyMeta,
          pubkey.isAcceptableOrUnknown(data['pubkey']!, _pubkeyMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    }
    if (data.containsKey('contact_info')) {
      context.handle(
          _contactInfoMeta,
          contactInfo.isAcceptableOrUnknown(
              data['contact_info']!, _contactInfoMeta));
    }
    if (data.containsKey('is_owner')) {
      context.handle(_isOwnerMeta,
          isOwner.isAcceptableOrUnknown(data['is_owner']!, _isOwnerMeta));
    }
    if (data.containsKey('joined_at')) {
      context.handle(_joinedAtMeta,
          joinedAt.isAcceptableOrUnknown(data['joined_at']!, _joinedAtMeta));
    } else if (isInserting) {
      context.missing(_joinedAtMeta);
    }
    if (data.containsKey('left_at')) {
      context.handle(_leftAtMeta,
          leftAt.isAcceptableOrUnknown(data['left_at']!, _leftAtMeta));
    }
    if (data.containsKey('removal_reason')) {
      context.handle(
          _removalReasonMeta,
          removalReason.isAcceptableOrUnknown(
              data['removal_reason']!, _removalReasonMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StewardRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StewardRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      vaultId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}vault_id'])!,
      shareIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}share_index'])!,
      pubkey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pubkey']),
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name']),
      contactInfo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}contact_info']),
      isOwner: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_owner'])!,
      joinedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}joined_at'])!,
      leftAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}left_at']),
      removalReason: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}removal_reason']),
    );
  }

  @override
  $StewardsTable createAlias(String alias) {
    return $StewardsTable(attachedDatabase, alias);
  }
}

class StewardRow extends DataClass implements Insertable<StewardRow> {
  final String id;
  final String vaultId;

  /// Shamir share position 1..N. Persists across replacement events.
  final int shareIndex;

  /// Nullable until the invitee accepts and we learn their pubkey.
  final String? pubkey;
  final String? name;

  /// Shared on the wire as part of the share event; UI hides it outside
  /// active recovery flows.
  final String? contactInfo;
  final bool isOwner;
  final int joinedAt;

  /// Null = active. Set when the steward leaves or is replaced.
  final int? leftAt;
  final String? removalReason;
  const StewardRow(
      {required this.id,
      required this.vaultId,
      required this.shareIndex,
      this.pubkey,
      this.name,
      this.contactInfo,
      required this.isOwner,
      required this.joinedAt,
      this.leftAt,
      this.removalReason});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['vault_id'] = Variable<String>(vaultId);
    map['share_index'] = Variable<int>(shareIndex);
    if (!nullToAbsent || pubkey != null) {
      map['pubkey'] = Variable<String>(pubkey);
    }
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || contactInfo != null) {
      map['contact_info'] = Variable<String>(contactInfo);
    }
    map['is_owner'] = Variable<bool>(isOwner);
    map['joined_at'] = Variable<int>(joinedAt);
    if (!nullToAbsent || leftAt != null) {
      map['left_at'] = Variable<int>(leftAt);
    }
    if (!nullToAbsent || removalReason != null) {
      map['removal_reason'] = Variable<String>(removalReason);
    }
    return map;
  }

  StewardsCompanion toCompanion(bool nullToAbsent) {
    return StewardsCompanion(
      id: Value(id),
      vaultId: Value(vaultId),
      shareIndex: Value(shareIndex),
      pubkey:
          pubkey == null && nullToAbsent ? const Value.absent() : Value(pubkey),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      contactInfo: contactInfo == null && nullToAbsent
          ? const Value.absent()
          : Value(contactInfo),
      isOwner: Value(isOwner),
      joinedAt: Value(joinedAt),
      leftAt:
          leftAt == null && nullToAbsent ? const Value.absent() : Value(leftAt),
      removalReason: removalReason == null && nullToAbsent
          ? const Value.absent()
          : Value(removalReason),
    );
  }

  factory StewardRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StewardRow(
      id: serializer.fromJson<String>(json['id']),
      vaultId: serializer.fromJson<String>(json['vaultId']),
      shareIndex: serializer.fromJson<int>(json['shareIndex']),
      pubkey: serializer.fromJson<String?>(json['pubkey']),
      name: serializer.fromJson<String?>(json['name']),
      contactInfo: serializer.fromJson<String?>(json['contactInfo']),
      isOwner: serializer.fromJson<bool>(json['isOwner']),
      joinedAt: serializer.fromJson<int>(json['joinedAt']),
      leftAt: serializer.fromJson<int?>(json['leftAt']),
      removalReason: serializer.fromJson<String?>(json['removalReason']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'vaultId': serializer.toJson<String>(vaultId),
      'shareIndex': serializer.toJson<int>(shareIndex),
      'pubkey': serializer.toJson<String?>(pubkey),
      'name': serializer.toJson<String?>(name),
      'contactInfo': serializer.toJson<String?>(contactInfo),
      'isOwner': serializer.toJson<bool>(isOwner),
      'joinedAt': serializer.toJson<int>(joinedAt),
      'leftAt': serializer.toJson<int?>(leftAt),
      'removalReason': serializer.toJson<String?>(removalReason),
    };
  }

  StewardRow copyWith(
          {String? id,
          String? vaultId,
          int? shareIndex,
          Value<String?> pubkey = const Value.absent(),
          Value<String?> name = const Value.absent(),
          Value<String?> contactInfo = const Value.absent(),
          bool? isOwner,
          int? joinedAt,
          Value<int?> leftAt = const Value.absent(),
          Value<String?> removalReason = const Value.absent()}) =>
      StewardRow(
        id: id ?? this.id,
        vaultId: vaultId ?? this.vaultId,
        shareIndex: shareIndex ?? this.shareIndex,
        pubkey: pubkey.present ? pubkey.value : this.pubkey,
        name: name.present ? name.value : this.name,
        contactInfo: contactInfo.present ? contactInfo.value : this.contactInfo,
        isOwner: isOwner ?? this.isOwner,
        joinedAt: joinedAt ?? this.joinedAt,
        leftAt: leftAt.present ? leftAt.value : this.leftAt,
        removalReason:
            removalReason.present ? removalReason.value : this.removalReason,
      );
  StewardRow copyWithCompanion(StewardsCompanion data) {
    return StewardRow(
      id: data.id.present ? data.id.value : this.id,
      vaultId: data.vaultId.present ? data.vaultId.value : this.vaultId,
      shareIndex:
          data.shareIndex.present ? data.shareIndex.value : this.shareIndex,
      pubkey: data.pubkey.present ? data.pubkey.value : this.pubkey,
      name: data.name.present ? data.name.value : this.name,
      contactInfo:
          data.contactInfo.present ? data.contactInfo.value : this.contactInfo,
      isOwner: data.isOwner.present ? data.isOwner.value : this.isOwner,
      joinedAt: data.joinedAt.present ? data.joinedAt.value : this.joinedAt,
      leftAt: data.leftAt.present ? data.leftAt.value : this.leftAt,
      removalReason: data.removalReason.present
          ? data.removalReason.value
          : this.removalReason,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StewardRow(')
          ..write('id: $id, ')
          ..write('vaultId: $vaultId, ')
          ..write('shareIndex: $shareIndex, ')
          ..write('pubkey: $pubkey, ')
          ..write('name: $name, ')
          ..write('contactInfo: $contactInfo, ')
          ..write('isOwner: $isOwner, ')
          ..write('joinedAt: $joinedAt, ')
          ..write('leftAt: $leftAt, ')
          ..write('removalReason: $removalReason')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, vaultId, shareIndex, pubkey, name,
      contactInfo, isOwner, joinedAt, leftAt, removalReason);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StewardRow &&
          other.id == this.id &&
          other.vaultId == this.vaultId &&
          other.shareIndex == this.shareIndex &&
          other.pubkey == this.pubkey &&
          other.name == this.name &&
          other.contactInfo == this.contactInfo &&
          other.isOwner == this.isOwner &&
          other.joinedAt == this.joinedAt &&
          other.leftAt == this.leftAt &&
          other.removalReason == this.removalReason);
}

class StewardsCompanion extends UpdateCompanion<StewardRow> {
  final Value<String> id;
  final Value<String> vaultId;
  final Value<int> shareIndex;
  final Value<String?> pubkey;
  final Value<String?> name;
  final Value<String?> contactInfo;
  final Value<bool> isOwner;
  final Value<int> joinedAt;
  final Value<int?> leftAt;
  final Value<String?> removalReason;
  final Value<int> rowid;
  const StewardsCompanion({
    this.id = const Value.absent(),
    this.vaultId = const Value.absent(),
    this.shareIndex = const Value.absent(),
    this.pubkey = const Value.absent(),
    this.name = const Value.absent(),
    this.contactInfo = const Value.absent(),
    this.isOwner = const Value.absent(),
    this.joinedAt = const Value.absent(),
    this.leftAt = const Value.absent(),
    this.removalReason = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StewardsCompanion.insert({
    required String id,
    required String vaultId,
    required int shareIndex,
    this.pubkey = const Value.absent(),
    this.name = const Value.absent(),
    this.contactInfo = const Value.absent(),
    this.isOwner = const Value.absent(),
    required int joinedAt,
    this.leftAt = const Value.absent(),
    this.removalReason = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        vaultId = Value(vaultId),
        shareIndex = Value(shareIndex),
        joinedAt = Value(joinedAt);
  static Insertable<StewardRow> custom({
    Expression<String>? id,
    Expression<String>? vaultId,
    Expression<int>? shareIndex,
    Expression<String>? pubkey,
    Expression<String>? name,
    Expression<String>? contactInfo,
    Expression<bool>? isOwner,
    Expression<int>? joinedAt,
    Expression<int>? leftAt,
    Expression<String>? removalReason,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (vaultId != null) 'vault_id': vaultId,
      if (shareIndex != null) 'share_index': shareIndex,
      if (pubkey != null) 'pubkey': pubkey,
      if (name != null) 'name': name,
      if (contactInfo != null) 'contact_info': contactInfo,
      if (isOwner != null) 'is_owner': isOwner,
      if (joinedAt != null) 'joined_at': joinedAt,
      if (leftAt != null) 'left_at': leftAt,
      if (removalReason != null) 'removal_reason': removalReason,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StewardsCompanion copyWith(
      {Value<String>? id,
      Value<String>? vaultId,
      Value<int>? shareIndex,
      Value<String?>? pubkey,
      Value<String?>? name,
      Value<String?>? contactInfo,
      Value<bool>? isOwner,
      Value<int>? joinedAt,
      Value<int?>? leftAt,
      Value<String?>? removalReason,
      Value<int>? rowid}) {
    return StewardsCompanion(
      id: id ?? this.id,
      vaultId: vaultId ?? this.vaultId,
      shareIndex: shareIndex ?? this.shareIndex,
      pubkey: pubkey ?? this.pubkey,
      name: name ?? this.name,
      contactInfo: contactInfo ?? this.contactInfo,
      isOwner: isOwner ?? this.isOwner,
      joinedAt: joinedAt ?? this.joinedAt,
      leftAt: leftAt ?? this.leftAt,
      removalReason: removalReason ?? this.removalReason,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (vaultId.present) {
      map['vault_id'] = Variable<String>(vaultId.value);
    }
    if (shareIndex.present) {
      map['share_index'] = Variable<int>(shareIndex.value);
    }
    if (pubkey.present) {
      map['pubkey'] = Variable<String>(pubkey.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (contactInfo.present) {
      map['contact_info'] = Variable<String>(contactInfo.value);
    }
    if (isOwner.present) {
      map['is_owner'] = Variable<bool>(isOwner.value);
    }
    if (joinedAt.present) {
      map['joined_at'] = Variable<int>(joinedAt.value);
    }
    if (leftAt.present) {
      map['left_at'] = Variable<int>(leftAt.value);
    }
    if (removalReason.present) {
      map['removal_reason'] = Variable<String>(removalReason.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StewardsCompanion(')
          ..write('id: $id, ')
          ..write('vaultId: $vaultId, ')
          ..write('shareIndex: $shareIndex, ')
          ..write('pubkey: $pubkey, ')
          ..write('name: $name, ')
          ..write('contactInfo: $contactInfo, ')
          ..write('isOwner: $isOwner, ')
          ..write('joinedAt: $joinedAt, ')
          ..write('leftAt: $leftAt, ')
          ..write('removalReason: $removalReason, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DistributionsTable extends Distributions
    with TableInfo<$DistributionsTable, DistributionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DistributionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _vaultIdMeta =
      const VerificationMeta('vaultId');
  @override
  late final GeneratedColumn<String> vaultId = GeneratedColumn<String>(
      'vault_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES vaults (id) ON DELETE CASCADE'));
  static const VerificationMeta _versionMeta =
      const VerificationMeta('version');
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
      'version', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _completedAtMeta =
      const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<int> completedAt = GeneratedColumn<int>(
      'completed_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _contentHmacMeta =
      const VerificationMeta('contentHmac');
  @override
  late final GeneratedColumn<Uint8List> contentHmac =
      GeneratedColumn<Uint8List>('content_hmac', aliasedName, false,
          type: DriftSqlType.blob, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, vaultId, version, createdAt, completedAt, contentHmac];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'distributions';
  @override
  VerificationContext validateIntegrity(Insertable<DistributionRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('vault_id')) {
      context.handle(_vaultIdMeta,
          vaultId.isAcceptableOrUnknown(data['vault_id']!, _vaultIdMeta));
    } else if (isInserting) {
      context.missing(_vaultIdMeta);
    }
    if (data.containsKey('version')) {
      context.handle(_versionMeta,
          version.isAcceptableOrUnknown(data['version']!, _versionMeta));
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
          _completedAtMeta,
          completedAt.isAcceptableOrUnknown(
              data['completed_at']!, _completedAtMeta));
    }
    if (data.containsKey('content_hmac')) {
      context.handle(
          _contentHmacMeta,
          contentHmac.isAcceptableOrUnknown(
              data['content_hmac']!, _contentHmacMeta));
    } else if (isInserting) {
      context.missing(_contentHmacMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DistributionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DistributionRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      vaultId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}vault_id'])!,
      version: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}version'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      completedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}completed_at']),
      contentHmac: attachedDatabase.typeMapping
          .read(DriftSqlType.blob, data['${effectivePrefix}content_hmac'])!,
    );
  }

  @override
  $DistributionsTable createAlias(String alias) {
    return $DistributionsTable(attachedDatabase, alias);
  }
}

class DistributionRow extends DataClass implements Insertable<DistributionRow> {
  final String id;
  final String vaultId;
  final int version;
  final int createdAt;
  final int? completedAt;
  final Uint8List contentHmac;
  const DistributionRow(
      {required this.id,
      required this.vaultId,
      required this.version,
      required this.createdAt,
      this.completedAt,
      required this.contentHmac});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['vault_id'] = Variable<String>(vaultId);
    map['version'] = Variable<int>(version);
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<int>(completedAt);
    }
    map['content_hmac'] = Variable<Uint8List>(contentHmac);
    return map;
  }

  DistributionsCompanion toCompanion(bool nullToAbsent) {
    return DistributionsCompanion(
      id: Value(id),
      vaultId: Value(vaultId),
      version: Value(version),
      createdAt: Value(createdAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      contentHmac: Value(contentHmac),
    );
  }

  factory DistributionRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DistributionRow(
      id: serializer.fromJson<String>(json['id']),
      vaultId: serializer.fromJson<String>(json['vaultId']),
      version: serializer.fromJson<int>(json['version']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      completedAt: serializer.fromJson<int?>(json['completedAt']),
      contentHmac: serializer.fromJson<Uint8List>(json['contentHmac']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'vaultId': serializer.toJson<String>(vaultId),
      'version': serializer.toJson<int>(version),
      'createdAt': serializer.toJson<int>(createdAt),
      'completedAt': serializer.toJson<int?>(completedAt),
      'contentHmac': serializer.toJson<Uint8List>(contentHmac),
    };
  }

  DistributionRow copyWith(
          {String? id,
          String? vaultId,
          int? version,
          int? createdAt,
          Value<int?> completedAt = const Value.absent(),
          Uint8List? contentHmac}) =>
      DistributionRow(
        id: id ?? this.id,
        vaultId: vaultId ?? this.vaultId,
        version: version ?? this.version,
        createdAt: createdAt ?? this.createdAt,
        completedAt: completedAt.present ? completedAt.value : this.completedAt,
        contentHmac: contentHmac ?? this.contentHmac,
      );
  DistributionRow copyWithCompanion(DistributionsCompanion data) {
    return DistributionRow(
      id: data.id.present ? data.id.value : this.id,
      vaultId: data.vaultId.present ? data.vaultId.value : this.vaultId,
      version: data.version.present ? data.version.value : this.version,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      completedAt:
          data.completedAt.present ? data.completedAt.value : this.completedAt,
      contentHmac:
          data.contentHmac.present ? data.contentHmac.value : this.contentHmac,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DistributionRow(')
          ..write('id: $id, ')
          ..write('vaultId: $vaultId, ')
          ..write('version: $version, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('contentHmac: $contentHmac')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, vaultId, version, createdAt, completedAt,
      $driftBlobEquality.hash(contentHmac));
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DistributionRow &&
          other.id == this.id &&
          other.vaultId == this.vaultId &&
          other.version == this.version &&
          other.createdAt == this.createdAt &&
          other.completedAt == this.completedAt &&
          $driftBlobEquality.equals(other.contentHmac, this.contentHmac));
}

class DistributionsCompanion extends UpdateCompanion<DistributionRow> {
  final Value<String> id;
  final Value<String> vaultId;
  final Value<int> version;
  final Value<int> createdAt;
  final Value<int?> completedAt;
  final Value<Uint8List> contentHmac;
  final Value<int> rowid;
  const DistributionsCompanion({
    this.id = const Value.absent(),
    this.vaultId = const Value.absent(),
    this.version = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.contentHmac = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DistributionsCompanion.insert({
    required String id,
    required String vaultId,
    required int version,
    required int createdAt,
    this.completedAt = const Value.absent(),
    required Uint8List contentHmac,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        vaultId = Value(vaultId),
        version = Value(version),
        createdAt = Value(createdAt),
        contentHmac = Value(contentHmac);
  static Insertable<DistributionRow> custom({
    Expression<String>? id,
    Expression<String>? vaultId,
    Expression<int>? version,
    Expression<int>? createdAt,
    Expression<int>? completedAt,
    Expression<Uint8List>? contentHmac,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (vaultId != null) 'vault_id': vaultId,
      if (version != null) 'version': version,
      if (createdAt != null) 'created_at': createdAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (contentHmac != null) 'content_hmac': contentHmac,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DistributionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? vaultId,
      Value<int>? version,
      Value<int>? createdAt,
      Value<int?>? completedAt,
      Value<Uint8List>? contentHmac,
      Value<int>? rowid}) {
    return DistributionsCompanion(
      id: id ?? this.id,
      vaultId: vaultId ?? this.vaultId,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      contentHmac: contentHmac ?? this.contentHmac,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (vaultId.present) {
      map['vault_id'] = Variable<String>(vaultId.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<int>(completedAt.value);
    }
    if (contentHmac.present) {
      map['content_hmac'] = Variable<Uint8List>(contentHmac.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DistributionsCompanion(')
          ..write('id: $id, ')
          ..write('vaultId: $vaultId, ')
          ..write('version: $version, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('contentHmac: $contentHmac, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DistributionSharesTable extends DistributionShares
    with TableInfo<$DistributionSharesTable, DistributionShareRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DistributionSharesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _distributionIdMeta =
      const VerificationMeta('distributionId');
  @override
  late final GeneratedColumn<String> distributionId = GeneratedColumn<String>(
      'distribution_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES distributions (id) ON DELETE CASCADE'));
  static const VerificationMeta _stewardIdMeta =
      const VerificationMeta('stewardId');
  @override
  late final GeneratedColumn<String> stewardId = GeneratedColumn<String>(
      'steward_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES stewards (id) ON DELETE RESTRICT'));
  static const VerificationMeta _giftWrapEventIdMeta =
      const VerificationMeta('giftWrapEventId');
  @override
  late final GeneratedColumn<String> giftWrapEventId = GeneratedColumn<String>(
      'gift_wrap_event_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sentAtMeta = const VerificationMeta('sentAt');
  @override
  late final GeneratedColumn<int> sentAt = GeneratedColumn<int>(
      'sent_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _acknowledgedAtMeta =
      const VerificationMeta('acknowledgedAt');
  @override
  late final GeneratedColumn<int> acknowledgedAt = GeneratedColumn<int>(
      'acknowledged_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _acknowledgmentEventIdMeta =
      const VerificationMeta('acknowledgmentEventId');
  @override
  late final GeneratedColumn<String> acknowledgmentEventId =
      GeneratedColumn<String>('acknowledgment_event_id', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _acknowledgmentDistributionVersionMeta =
      const VerificationMeta('acknowledgmentDistributionVersion');
  @override
  late final GeneratedColumn<int> acknowledgmentDistributionVersion =
      GeneratedColumn<int>(
          'acknowledgment_distribution_version', aliasedName, true,
          type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _acknowledgmentCreatedAtMeta =
      const VerificationMeta('acknowledgmentCreatedAt');
  @override
  late final GeneratedColumn<int> acknowledgmentCreatedAt =
      GeneratedColumn<int>('acknowledgment_created_at', aliasedName, true,
          type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        distributionId,
        stewardId,
        giftWrapEventId,
        sentAt,
        acknowledgedAt,
        acknowledgmentEventId,
        acknowledgmentDistributionVersion,
        acknowledgmentCreatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'distribution_shares';
  @override
  VerificationContext validateIntegrity(
      Insertable<DistributionShareRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('distribution_id')) {
      context.handle(
          _distributionIdMeta,
          distributionId.isAcceptableOrUnknown(
              data['distribution_id']!, _distributionIdMeta));
    } else if (isInserting) {
      context.missing(_distributionIdMeta);
    }
    if (data.containsKey('steward_id')) {
      context.handle(_stewardIdMeta,
          stewardId.isAcceptableOrUnknown(data['steward_id']!, _stewardIdMeta));
    } else if (isInserting) {
      context.missing(_stewardIdMeta);
    }
    if (data.containsKey('gift_wrap_event_id')) {
      context.handle(
          _giftWrapEventIdMeta,
          giftWrapEventId.isAcceptableOrUnknown(
              data['gift_wrap_event_id']!, _giftWrapEventIdMeta));
    } else if (isInserting) {
      context.missing(_giftWrapEventIdMeta);
    }
    if (data.containsKey('sent_at')) {
      context.handle(_sentAtMeta,
          sentAt.isAcceptableOrUnknown(data['sent_at']!, _sentAtMeta));
    }
    if (data.containsKey('acknowledged_at')) {
      context.handle(
          _acknowledgedAtMeta,
          acknowledgedAt.isAcceptableOrUnknown(
              data['acknowledged_at']!, _acknowledgedAtMeta));
    }
    if (data.containsKey('acknowledgment_event_id')) {
      context.handle(
          _acknowledgmentEventIdMeta,
          acknowledgmentEventId.isAcceptableOrUnknown(
              data['acknowledgment_event_id']!, _acknowledgmentEventIdMeta));
    }
    if (data.containsKey('acknowledgment_distribution_version')) {
      context.handle(
          _acknowledgmentDistributionVersionMeta,
          acknowledgmentDistributionVersion.isAcceptableOrUnknown(
              data['acknowledgment_distribution_version']!,
              _acknowledgmentDistributionVersionMeta));
    }
    if (data.containsKey('acknowledgment_created_at')) {
      context.handle(
          _acknowledgmentCreatedAtMeta,
          acknowledgmentCreatedAt.isAcceptableOrUnknown(
              data['acknowledgment_created_at']!,
              _acknowledgmentCreatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DistributionShareRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DistributionShareRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      distributionId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}distribution_id'])!,
      stewardId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}steward_id'])!,
      giftWrapEventId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}gift_wrap_event_id'])!,
      sentAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sent_at']),
      acknowledgedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}acknowledged_at']),
      acknowledgmentEventId: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}acknowledgment_event_id']),
      acknowledgmentDistributionVersion: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}acknowledgment_distribution_version']),
      acknowledgmentCreatedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}acknowledgment_created_at']),
    );
  }

  @override
  $DistributionSharesTable createAlias(String alias) {
    return $DistributionSharesTable(attachedDatabase, alias);
  }
}

class DistributionShareRow extends DataClass
    implements Insertable<DistributionShareRow> {
  final String id;
  final String distributionId;
  final String stewardId;
  final String giftWrapEventId;
  final int? sentAt;
  final int? acknowledgedAt;
  final String? acknowledgmentEventId;

  /// Distribution version the steward ack'd; lets us detect stale acks.
  final int? acknowledgmentDistributionVersion;

  /// Wire `created_at` of the ack event — kept for audit only, never used
  /// for "freshness" decisions (see "Time, monotonicity, clock skew").
  final int? acknowledgmentCreatedAt;
  const DistributionShareRow(
      {required this.id,
      required this.distributionId,
      required this.stewardId,
      required this.giftWrapEventId,
      this.sentAt,
      this.acknowledgedAt,
      this.acknowledgmentEventId,
      this.acknowledgmentDistributionVersion,
      this.acknowledgmentCreatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['distribution_id'] = Variable<String>(distributionId);
    map['steward_id'] = Variable<String>(stewardId);
    map['gift_wrap_event_id'] = Variable<String>(giftWrapEventId);
    if (!nullToAbsent || sentAt != null) {
      map['sent_at'] = Variable<int>(sentAt);
    }
    if (!nullToAbsent || acknowledgedAt != null) {
      map['acknowledged_at'] = Variable<int>(acknowledgedAt);
    }
    if (!nullToAbsent || acknowledgmentEventId != null) {
      map['acknowledgment_event_id'] = Variable<String>(acknowledgmentEventId);
    }
    if (!nullToAbsent || acknowledgmentDistributionVersion != null) {
      map['acknowledgment_distribution_version'] =
          Variable<int>(acknowledgmentDistributionVersion);
    }
    if (!nullToAbsent || acknowledgmentCreatedAt != null) {
      map['acknowledgment_created_at'] = Variable<int>(acknowledgmentCreatedAt);
    }
    return map;
  }

  DistributionSharesCompanion toCompanion(bool nullToAbsent) {
    return DistributionSharesCompanion(
      id: Value(id),
      distributionId: Value(distributionId),
      stewardId: Value(stewardId),
      giftWrapEventId: Value(giftWrapEventId),
      sentAt:
          sentAt == null && nullToAbsent ? const Value.absent() : Value(sentAt),
      acknowledgedAt: acknowledgedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(acknowledgedAt),
      acknowledgmentEventId: acknowledgmentEventId == null && nullToAbsent
          ? const Value.absent()
          : Value(acknowledgmentEventId),
      acknowledgmentDistributionVersion:
          acknowledgmentDistributionVersion == null && nullToAbsent
              ? const Value.absent()
              : Value(acknowledgmentDistributionVersion),
      acknowledgmentCreatedAt: acknowledgmentCreatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(acknowledgmentCreatedAt),
    );
  }

  factory DistributionShareRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DistributionShareRow(
      id: serializer.fromJson<String>(json['id']),
      distributionId: serializer.fromJson<String>(json['distributionId']),
      stewardId: serializer.fromJson<String>(json['stewardId']),
      giftWrapEventId: serializer.fromJson<String>(json['giftWrapEventId']),
      sentAt: serializer.fromJson<int?>(json['sentAt']),
      acknowledgedAt: serializer.fromJson<int?>(json['acknowledgedAt']),
      acknowledgmentEventId:
          serializer.fromJson<String?>(json['acknowledgmentEventId']),
      acknowledgmentDistributionVersion:
          serializer.fromJson<int?>(json['acknowledgmentDistributionVersion']),
      acknowledgmentCreatedAt:
          serializer.fromJson<int?>(json['acknowledgmentCreatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'distributionId': serializer.toJson<String>(distributionId),
      'stewardId': serializer.toJson<String>(stewardId),
      'giftWrapEventId': serializer.toJson<String>(giftWrapEventId),
      'sentAt': serializer.toJson<int?>(sentAt),
      'acknowledgedAt': serializer.toJson<int?>(acknowledgedAt),
      'acknowledgmentEventId':
          serializer.toJson<String?>(acknowledgmentEventId),
      'acknowledgmentDistributionVersion':
          serializer.toJson<int?>(acknowledgmentDistributionVersion),
      'acknowledgmentCreatedAt':
          serializer.toJson<int?>(acknowledgmentCreatedAt),
    };
  }

  DistributionShareRow copyWith(
          {String? id,
          String? distributionId,
          String? stewardId,
          String? giftWrapEventId,
          Value<int?> sentAt = const Value.absent(),
          Value<int?> acknowledgedAt = const Value.absent(),
          Value<String?> acknowledgmentEventId = const Value.absent(),
          Value<int?> acknowledgmentDistributionVersion = const Value.absent(),
          Value<int?> acknowledgmentCreatedAt = const Value.absent()}) =>
      DistributionShareRow(
        id: id ?? this.id,
        distributionId: distributionId ?? this.distributionId,
        stewardId: stewardId ?? this.stewardId,
        giftWrapEventId: giftWrapEventId ?? this.giftWrapEventId,
        sentAt: sentAt.present ? sentAt.value : this.sentAt,
        acknowledgedAt:
            acknowledgedAt.present ? acknowledgedAt.value : this.acknowledgedAt,
        acknowledgmentEventId: acknowledgmentEventId.present
            ? acknowledgmentEventId.value
            : this.acknowledgmentEventId,
        acknowledgmentDistributionVersion:
            acknowledgmentDistributionVersion.present
                ? acknowledgmentDistributionVersion.value
                : this.acknowledgmentDistributionVersion,
        acknowledgmentCreatedAt: acknowledgmentCreatedAt.present
            ? acknowledgmentCreatedAt.value
            : this.acknowledgmentCreatedAt,
      );
  DistributionShareRow copyWithCompanion(DistributionSharesCompanion data) {
    return DistributionShareRow(
      id: data.id.present ? data.id.value : this.id,
      distributionId: data.distributionId.present
          ? data.distributionId.value
          : this.distributionId,
      stewardId: data.stewardId.present ? data.stewardId.value : this.stewardId,
      giftWrapEventId: data.giftWrapEventId.present
          ? data.giftWrapEventId.value
          : this.giftWrapEventId,
      sentAt: data.sentAt.present ? data.sentAt.value : this.sentAt,
      acknowledgedAt: data.acknowledgedAt.present
          ? data.acknowledgedAt.value
          : this.acknowledgedAt,
      acknowledgmentEventId: data.acknowledgmentEventId.present
          ? data.acknowledgmentEventId.value
          : this.acknowledgmentEventId,
      acknowledgmentDistributionVersion:
          data.acknowledgmentDistributionVersion.present
              ? data.acknowledgmentDistributionVersion.value
              : this.acknowledgmentDistributionVersion,
      acknowledgmentCreatedAt: data.acknowledgmentCreatedAt.present
          ? data.acknowledgmentCreatedAt.value
          : this.acknowledgmentCreatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DistributionShareRow(')
          ..write('id: $id, ')
          ..write('distributionId: $distributionId, ')
          ..write('stewardId: $stewardId, ')
          ..write('giftWrapEventId: $giftWrapEventId, ')
          ..write('sentAt: $sentAt, ')
          ..write('acknowledgedAt: $acknowledgedAt, ')
          ..write('acknowledgmentEventId: $acknowledgmentEventId, ')
          ..write(
              'acknowledgmentDistributionVersion: $acknowledgmentDistributionVersion, ')
          ..write('acknowledgmentCreatedAt: $acknowledgmentCreatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      distributionId,
      stewardId,
      giftWrapEventId,
      sentAt,
      acknowledgedAt,
      acknowledgmentEventId,
      acknowledgmentDistributionVersion,
      acknowledgmentCreatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DistributionShareRow &&
          other.id == this.id &&
          other.distributionId == this.distributionId &&
          other.stewardId == this.stewardId &&
          other.giftWrapEventId == this.giftWrapEventId &&
          other.sentAt == this.sentAt &&
          other.acknowledgedAt == this.acknowledgedAt &&
          other.acknowledgmentEventId == this.acknowledgmentEventId &&
          other.acknowledgmentDistributionVersion ==
              this.acknowledgmentDistributionVersion &&
          other.acknowledgmentCreatedAt == this.acknowledgmentCreatedAt);
}

class DistributionSharesCompanion
    extends UpdateCompanion<DistributionShareRow> {
  final Value<String> id;
  final Value<String> distributionId;
  final Value<String> stewardId;
  final Value<String> giftWrapEventId;
  final Value<int?> sentAt;
  final Value<int?> acknowledgedAt;
  final Value<String?> acknowledgmentEventId;
  final Value<int?> acknowledgmentDistributionVersion;
  final Value<int?> acknowledgmentCreatedAt;
  final Value<int> rowid;
  const DistributionSharesCompanion({
    this.id = const Value.absent(),
    this.distributionId = const Value.absent(),
    this.stewardId = const Value.absent(),
    this.giftWrapEventId = const Value.absent(),
    this.sentAt = const Value.absent(),
    this.acknowledgedAt = const Value.absent(),
    this.acknowledgmentEventId = const Value.absent(),
    this.acknowledgmentDistributionVersion = const Value.absent(),
    this.acknowledgmentCreatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DistributionSharesCompanion.insert({
    required String id,
    required String distributionId,
    required String stewardId,
    required String giftWrapEventId,
    this.sentAt = const Value.absent(),
    this.acknowledgedAt = const Value.absent(),
    this.acknowledgmentEventId = const Value.absent(),
    this.acknowledgmentDistributionVersion = const Value.absent(),
    this.acknowledgmentCreatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        distributionId = Value(distributionId),
        stewardId = Value(stewardId),
        giftWrapEventId = Value(giftWrapEventId);
  static Insertable<DistributionShareRow> custom({
    Expression<String>? id,
    Expression<String>? distributionId,
    Expression<String>? stewardId,
    Expression<String>? giftWrapEventId,
    Expression<int>? sentAt,
    Expression<int>? acknowledgedAt,
    Expression<String>? acknowledgmentEventId,
    Expression<int>? acknowledgmentDistributionVersion,
    Expression<int>? acknowledgmentCreatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (distributionId != null) 'distribution_id': distributionId,
      if (stewardId != null) 'steward_id': stewardId,
      if (giftWrapEventId != null) 'gift_wrap_event_id': giftWrapEventId,
      if (sentAt != null) 'sent_at': sentAt,
      if (acknowledgedAt != null) 'acknowledged_at': acknowledgedAt,
      if (acknowledgmentEventId != null)
        'acknowledgment_event_id': acknowledgmentEventId,
      if (acknowledgmentDistributionVersion != null)
        'acknowledgment_distribution_version':
            acknowledgmentDistributionVersion,
      if (acknowledgmentCreatedAt != null)
        'acknowledgment_created_at': acknowledgmentCreatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DistributionSharesCompanion copyWith(
      {Value<String>? id,
      Value<String>? distributionId,
      Value<String>? stewardId,
      Value<String>? giftWrapEventId,
      Value<int?>? sentAt,
      Value<int?>? acknowledgedAt,
      Value<String?>? acknowledgmentEventId,
      Value<int?>? acknowledgmentDistributionVersion,
      Value<int?>? acknowledgmentCreatedAt,
      Value<int>? rowid}) {
    return DistributionSharesCompanion(
      id: id ?? this.id,
      distributionId: distributionId ?? this.distributionId,
      stewardId: stewardId ?? this.stewardId,
      giftWrapEventId: giftWrapEventId ?? this.giftWrapEventId,
      sentAt: sentAt ?? this.sentAt,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      acknowledgmentEventId:
          acknowledgmentEventId ?? this.acknowledgmentEventId,
      acknowledgmentDistributionVersion: acknowledgmentDistributionVersion ??
          this.acknowledgmentDistributionVersion,
      acknowledgmentCreatedAt:
          acknowledgmentCreatedAt ?? this.acknowledgmentCreatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (distributionId.present) {
      map['distribution_id'] = Variable<String>(distributionId.value);
    }
    if (stewardId.present) {
      map['steward_id'] = Variable<String>(stewardId.value);
    }
    if (giftWrapEventId.present) {
      map['gift_wrap_event_id'] = Variable<String>(giftWrapEventId.value);
    }
    if (sentAt.present) {
      map['sent_at'] = Variable<int>(sentAt.value);
    }
    if (acknowledgedAt.present) {
      map['acknowledged_at'] = Variable<int>(acknowledgedAt.value);
    }
    if (acknowledgmentEventId.present) {
      map['acknowledgment_event_id'] =
          Variable<String>(acknowledgmentEventId.value);
    }
    if (acknowledgmentDistributionVersion.present) {
      map['acknowledgment_distribution_version'] =
          Variable<int>(acknowledgmentDistributionVersion.value);
    }
    if (acknowledgmentCreatedAt.present) {
      map['acknowledgment_created_at'] =
          Variable<int>(acknowledgmentCreatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DistributionSharesCompanion(')
          ..write('id: $id, ')
          ..write('distributionId: $distributionId, ')
          ..write('stewardId: $stewardId, ')
          ..write('giftWrapEventId: $giftWrapEventId, ')
          ..write('sentAt: $sentAt, ')
          ..write('acknowledgedAt: $acknowledgedAt, ')
          ..write('acknowledgmentEventId: $acknowledgmentEventId, ')
          ..write(
              'acknowledgmentDistributionVersion: $acknowledgmentDistributionVersion, ')
          ..write('acknowledgmentCreatedAt: $acknowledgmentCreatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $VaultsTable vaults = $VaultsTable(this);
  late final $VaultRelaysTable vaultRelays = $VaultRelaysTable(this);
  late final $OwnedVaultsTable ownedVaults = $OwnedVaultsTable(this);
  late final $StewardsTable stewards = $StewardsTable(this);
  late final $DistributionsTable distributions = $DistributionsTable(this);
  late final $DistributionSharesTable distributionShares =
      $DistributionSharesTable(this);
  late final VaultDao vaultDao = VaultDao(this as AppDatabase);
  late final VaultRelayDao vaultRelayDao = VaultRelayDao(this as AppDatabase);
  late final OwnedVaultDao ownedVaultDao = OwnedVaultDao(this as AppDatabase);
  late final StewardDao stewardDao = StewardDao(this as AppDatabase);
  late final DistributionDao distributionDao =
      DistributionDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        vaults,
        vaultRelays,
        ownedVaults,
        stewards,
        distributions,
        distributionShares
      ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('vaults',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('vault_relays', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('vaults',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('owned_vaults', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('vaults',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('stewards', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('vaults',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('distributions', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('distributions',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('distribution_shares', kind: UpdateKind.delete),
            ],
          ),
        ],
      );
}

typedef $$VaultsTableCreateCompanionBuilder = VaultsCompanion Function({
  required String id,
  required String name,
  required String ownerPubkey,
  Value<String?> ownerName,
  required int threshold,
  Value<String?> primeMod,
  required int totalShares,
  Value<int> currentDistributionVersion,
  Value<String?> instructions,
  Value<bool> pushEnabled,
  Value<int?> archivedAt,
  Value<String?> archivedReason,
  Value<int?> lastSyncedAt,
  required int createdAt,
  Value<int> rowid,
});
typedef $$VaultsTableUpdateCompanionBuilder = VaultsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> ownerPubkey,
  Value<String?> ownerName,
  Value<int> threshold,
  Value<String?> primeMod,
  Value<int> totalShares,
  Value<int> currentDistributionVersion,
  Value<String?> instructions,
  Value<bool> pushEnabled,
  Value<int?> archivedAt,
  Value<String?> archivedReason,
  Value<int?> lastSyncedAt,
  Value<int> createdAt,
  Value<int> rowid,
});

final class $$VaultsTableReferences
    extends BaseReferences<_$AppDatabase, $VaultsTable, VaultRow> {
  $$VaultsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$VaultRelaysTable, List<VaultRelayRow>>
      _vaultRelaysRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.vaultRelays,
              aliasName:
                  $_aliasNameGenerator(db.vaults.id, db.vaultRelays.vaultId));

  $$VaultRelaysTableProcessedTableManager get vaultRelaysRefs {
    final manager = $$VaultRelaysTableTableManager($_db, $_db.vaultRelays)
        .filter((f) => f.vaultId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_vaultRelaysRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$OwnedVaultsTable, List<OwnedVaultRow>>
      _ownedVaultsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.ownedVaults,
              aliasName:
                  $_aliasNameGenerator(db.vaults.id, db.ownedVaults.vaultId));

  $$OwnedVaultsTableProcessedTableManager get ownedVaultsRefs {
    final manager = $$OwnedVaultsTableTableManager($_db, $_db.ownedVaults)
        .filter((f) => f.vaultId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_ownedVaultsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$StewardsTable, List<StewardRow>>
      _stewardsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.stewards,
          aliasName: $_aliasNameGenerator(db.vaults.id, db.stewards.vaultId));

  $$StewardsTableProcessedTableManager get stewardsRefs {
    final manager = $$StewardsTableTableManager($_db, $_db.stewards)
        .filter((f) => f.vaultId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_stewardsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$DistributionsTable, List<DistributionRow>>
      _distributionsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.distributions,
              aliasName:
                  $_aliasNameGenerator(db.vaults.id, db.distributions.vaultId));

  $$DistributionsTableProcessedTableManager get distributionsRefs {
    final manager = $$DistributionsTableTableManager($_db, $_db.distributions)
        .filter((f) => f.vaultId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_distributionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$VaultsTableFilterComposer
    extends Composer<_$AppDatabase, $VaultsTable> {
  $$VaultsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ownerPubkey => $composableBuilder(
      column: $table.ownerPubkey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ownerName => $composableBuilder(
      column: $table.ownerName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get threshold => $composableBuilder(
      column: $table.threshold, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get primeMod => $composableBuilder(
      column: $table.primeMod, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalShares => $composableBuilder(
      column: $table.totalShares, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get currentDistributionVersion => $composableBuilder(
      column: $table.currentDistributionVersion,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get instructions => $composableBuilder(
      column: $table.instructions, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get pushEnabled => $composableBuilder(
      column: $table.pushEnabled, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get archivedAt => $composableBuilder(
      column: $table.archivedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get archivedReason => $composableBuilder(
      column: $table.archivedReason,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  Expression<bool> vaultRelaysRefs(
      Expression<bool> Function($$VaultRelaysTableFilterComposer f) f) {
    final $$VaultRelaysTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.vaultRelays,
        getReferencedColumn: (t) => t.vaultId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VaultRelaysTableFilterComposer(
              $db: $db,
              $table: $db.vaultRelays,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> ownedVaultsRefs(
      Expression<bool> Function($$OwnedVaultsTableFilterComposer f) f) {
    final $$OwnedVaultsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.ownedVaults,
        getReferencedColumn: (t) => t.vaultId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OwnedVaultsTableFilterComposer(
              $db: $db,
              $table: $db.ownedVaults,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> stewardsRefs(
      Expression<bool> Function($$StewardsTableFilterComposer f) f) {
    final $$StewardsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.stewards,
        getReferencedColumn: (t) => t.vaultId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StewardsTableFilterComposer(
              $db: $db,
              $table: $db.stewards,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> distributionsRefs(
      Expression<bool> Function($$DistributionsTableFilterComposer f) f) {
    final $$DistributionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.distributions,
        getReferencedColumn: (t) => t.vaultId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DistributionsTableFilterComposer(
              $db: $db,
              $table: $db.distributions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$VaultsTableOrderingComposer
    extends Composer<_$AppDatabase, $VaultsTable> {
  $$VaultsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ownerPubkey => $composableBuilder(
      column: $table.ownerPubkey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ownerName => $composableBuilder(
      column: $table.ownerName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get threshold => $composableBuilder(
      column: $table.threshold, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get primeMod => $composableBuilder(
      column: $table.primeMod, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalShares => $composableBuilder(
      column: $table.totalShares, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get currentDistributionVersion => $composableBuilder(
      column: $table.currentDistributionVersion,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get instructions => $composableBuilder(
      column: $table.instructions,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get pushEnabled => $composableBuilder(
      column: $table.pushEnabled, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get archivedAt => $composableBuilder(
      column: $table.archivedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get archivedReason => $composableBuilder(
      column: $table.archivedReason,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$VaultsTableAnnotationComposer
    extends Composer<_$AppDatabase, $VaultsTable> {
  $$VaultsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get ownerPubkey => $composableBuilder(
      column: $table.ownerPubkey, builder: (column) => column);

  GeneratedColumn<String> get ownerName =>
      $composableBuilder(column: $table.ownerName, builder: (column) => column);

  GeneratedColumn<int> get threshold =>
      $composableBuilder(column: $table.threshold, builder: (column) => column);

  GeneratedColumn<String> get primeMod =>
      $composableBuilder(column: $table.primeMod, builder: (column) => column);

  GeneratedColumn<int> get totalShares => $composableBuilder(
      column: $table.totalShares, builder: (column) => column);

  GeneratedColumn<int> get currentDistributionVersion => $composableBuilder(
      column: $table.currentDistributionVersion, builder: (column) => column);

  GeneratedColumn<String> get instructions => $composableBuilder(
      column: $table.instructions, builder: (column) => column);

  GeneratedColumn<bool> get pushEnabled => $composableBuilder(
      column: $table.pushEnabled, builder: (column) => column);

  GeneratedColumn<int> get archivedAt => $composableBuilder(
      column: $table.archivedAt, builder: (column) => column);

  GeneratedColumn<String> get archivedReason => $composableBuilder(
      column: $table.archivedReason, builder: (column) => column);

  GeneratedColumn<int> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> vaultRelaysRefs<T extends Object>(
      Expression<T> Function($$VaultRelaysTableAnnotationComposer a) f) {
    final $$VaultRelaysTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.vaultRelays,
        getReferencedColumn: (t) => t.vaultId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VaultRelaysTableAnnotationComposer(
              $db: $db,
              $table: $db.vaultRelays,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> ownedVaultsRefs<T extends Object>(
      Expression<T> Function($$OwnedVaultsTableAnnotationComposer a) f) {
    final $$OwnedVaultsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.ownedVaults,
        getReferencedColumn: (t) => t.vaultId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OwnedVaultsTableAnnotationComposer(
              $db: $db,
              $table: $db.ownedVaults,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> stewardsRefs<T extends Object>(
      Expression<T> Function($$StewardsTableAnnotationComposer a) f) {
    final $$StewardsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.stewards,
        getReferencedColumn: (t) => t.vaultId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StewardsTableAnnotationComposer(
              $db: $db,
              $table: $db.stewards,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> distributionsRefs<T extends Object>(
      Expression<T> Function($$DistributionsTableAnnotationComposer a) f) {
    final $$DistributionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.distributions,
        getReferencedColumn: (t) => t.vaultId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DistributionsTableAnnotationComposer(
              $db: $db,
              $table: $db.distributions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$VaultsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $VaultsTable,
    VaultRow,
    $$VaultsTableFilterComposer,
    $$VaultsTableOrderingComposer,
    $$VaultsTableAnnotationComposer,
    $$VaultsTableCreateCompanionBuilder,
    $$VaultsTableUpdateCompanionBuilder,
    (VaultRow, $$VaultsTableReferences),
    VaultRow,
    PrefetchHooks Function(
        {bool vaultRelaysRefs,
        bool ownedVaultsRefs,
        bool stewardsRefs,
        bool distributionsRefs})> {
  $$VaultsTableTableManager(_$AppDatabase db, $VaultsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VaultsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VaultsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VaultsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> ownerPubkey = const Value.absent(),
            Value<String?> ownerName = const Value.absent(),
            Value<int> threshold = const Value.absent(),
            Value<String?> primeMod = const Value.absent(),
            Value<int> totalShares = const Value.absent(),
            Value<int> currentDistributionVersion = const Value.absent(),
            Value<String?> instructions = const Value.absent(),
            Value<bool> pushEnabled = const Value.absent(),
            Value<int?> archivedAt = const Value.absent(),
            Value<String?> archivedReason = const Value.absent(),
            Value<int?> lastSyncedAt = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              VaultsCompanion(
            id: id,
            name: name,
            ownerPubkey: ownerPubkey,
            ownerName: ownerName,
            threshold: threshold,
            primeMod: primeMod,
            totalShares: totalShares,
            currentDistributionVersion: currentDistributionVersion,
            instructions: instructions,
            pushEnabled: pushEnabled,
            archivedAt: archivedAt,
            archivedReason: archivedReason,
            lastSyncedAt: lastSyncedAt,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String ownerPubkey,
            Value<String?> ownerName = const Value.absent(),
            required int threshold,
            Value<String?> primeMod = const Value.absent(),
            required int totalShares,
            Value<int> currentDistributionVersion = const Value.absent(),
            Value<String?> instructions = const Value.absent(),
            Value<bool> pushEnabled = const Value.absent(),
            Value<int?> archivedAt = const Value.absent(),
            Value<String?> archivedReason = const Value.absent(),
            Value<int?> lastSyncedAt = const Value.absent(),
            required int createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              VaultsCompanion.insert(
            id: id,
            name: name,
            ownerPubkey: ownerPubkey,
            ownerName: ownerName,
            threshold: threshold,
            primeMod: primeMod,
            totalShares: totalShares,
            currentDistributionVersion: currentDistributionVersion,
            instructions: instructions,
            pushEnabled: pushEnabled,
            archivedAt: archivedAt,
            archivedReason: archivedReason,
            lastSyncedAt: lastSyncedAt,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$VaultsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {vaultRelaysRefs = false,
              ownedVaultsRefs = false,
              stewardsRefs = false,
              distributionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (vaultRelaysRefs) db.vaultRelays,
                if (ownedVaultsRefs) db.ownedVaults,
                if (stewardsRefs) db.stewards,
                if (distributionsRefs) db.distributions
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (vaultRelaysRefs)
                    await $_getPrefetchedData<VaultRow, $VaultsTable,
                            VaultRelayRow>(
                        currentTable: table,
                        referencedTable:
                            $$VaultsTableReferences._vaultRelaysRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$VaultsTableReferences(db, table, p0)
                                .vaultRelaysRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.vaultId == item.id),
                        typedResults: items),
                  if (ownedVaultsRefs)
                    await $_getPrefetchedData<VaultRow, $VaultsTable,
                            OwnedVaultRow>(
                        currentTable: table,
                        referencedTable:
                            $$VaultsTableReferences._ownedVaultsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$VaultsTableReferences(db, table, p0)
                                .ownedVaultsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.vaultId == item.id),
                        typedResults: items),
                  if (stewardsRefs)
                    await $_getPrefetchedData<VaultRow, $VaultsTable,
                            StewardRow>(
                        currentTable: table,
                        referencedTable:
                            $$VaultsTableReferences._stewardsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$VaultsTableReferences(db, table, p0).stewardsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.vaultId == item.id),
                        typedResults: items),
                  if (distributionsRefs)
                    await $_getPrefetchedData<VaultRow, $VaultsTable,
                            DistributionRow>(
                        currentTable: table,
                        referencedTable:
                            $$VaultsTableReferences._distributionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$VaultsTableReferences(db, table, p0)
                                .distributionsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.vaultId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$VaultsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $VaultsTable,
    VaultRow,
    $$VaultsTableFilterComposer,
    $$VaultsTableOrderingComposer,
    $$VaultsTableAnnotationComposer,
    $$VaultsTableCreateCompanionBuilder,
    $$VaultsTableUpdateCompanionBuilder,
    (VaultRow, $$VaultsTableReferences),
    VaultRow,
    PrefetchHooks Function(
        {bool vaultRelaysRefs,
        bool ownedVaultsRefs,
        bool stewardsRefs,
        bool distributionsRefs})>;
typedef $$VaultRelaysTableCreateCompanionBuilder = VaultRelaysCompanion
    Function({
  required String id,
  required String vaultId,
  required String url,
  required String role,
  required int addedAt,
  Value<int> rowid,
});
typedef $$VaultRelaysTableUpdateCompanionBuilder = VaultRelaysCompanion
    Function({
  Value<String> id,
  Value<String> vaultId,
  Value<String> url,
  Value<String> role,
  Value<int> addedAt,
  Value<int> rowid,
});

final class $$VaultRelaysTableReferences
    extends BaseReferences<_$AppDatabase, $VaultRelaysTable, VaultRelayRow> {
  $$VaultRelaysTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $VaultsTable _vaultIdTable(_$AppDatabase db) => db.vaults
      .createAlias($_aliasNameGenerator(db.vaultRelays.vaultId, db.vaults.id));

  $$VaultsTableProcessedTableManager get vaultId {
    final $_column = $_itemColumn<String>('vault_id')!;

    final manager = $$VaultsTableTableManager($_db, $_db.vaults)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_vaultIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$VaultRelaysTableFilterComposer
    extends Composer<_$AppDatabase, $VaultRelaysTable> {
  $$VaultRelaysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get url => $composableBuilder(
      column: $table.url, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get addedAt => $composableBuilder(
      column: $table.addedAt, builder: (column) => ColumnFilters(column));

  $$VaultsTableFilterComposer get vaultId {
    final $$VaultsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.vaultId,
        referencedTable: $db.vaults,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VaultsTableFilterComposer(
              $db: $db,
              $table: $db.vaults,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$VaultRelaysTableOrderingComposer
    extends Composer<_$AppDatabase, $VaultRelaysTable> {
  $$VaultRelaysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get url => $composableBuilder(
      column: $table.url, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get addedAt => $composableBuilder(
      column: $table.addedAt, builder: (column) => ColumnOrderings(column));

  $$VaultsTableOrderingComposer get vaultId {
    final $$VaultsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.vaultId,
        referencedTable: $db.vaults,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VaultsTableOrderingComposer(
              $db: $db,
              $table: $db.vaults,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$VaultRelaysTableAnnotationComposer
    extends Composer<_$AppDatabase, $VaultRelaysTable> {
  $$VaultRelaysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<int> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  $$VaultsTableAnnotationComposer get vaultId {
    final $$VaultsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.vaultId,
        referencedTable: $db.vaults,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VaultsTableAnnotationComposer(
              $db: $db,
              $table: $db.vaults,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$VaultRelaysTableTableManager extends RootTableManager<
    _$AppDatabase,
    $VaultRelaysTable,
    VaultRelayRow,
    $$VaultRelaysTableFilterComposer,
    $$VaultRelaysTableOrderingComposer,
    $$VaultRelaysTableAnnotationComposer,
    $$VaultRelaysTableCreateCompanionBuilder,
    $$VaultRelaysTableUpdateCompanionBuilder,
    (VaultRelayRow, $$VaultRelaysTableReferences),
    VaultRelayRow,
    PrefetchHooks Function({bool vaultId})> {
  $$VaultRelaysTableTableManager(_$AppDatabase db, $VaultRelaysTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VaultRelaysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VaultRelaysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VaultRelaysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> vaultId = const Value.absent(),
            Value<String> url = const Value.absent(),
            Value<String> role = const Value.absent(),
            Value<int> addedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              VaultRelaysCompanion(
            id: id,
            vaultId: vaultId,
            url: url,
            role: role,
            addedAt: addedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String vaultId,
            required String url,
            required String role,
            required int addedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              VaultRelaysCompanion.insert(
            id: id,
            vaultId: vaultId,
            url: url,
            role: role,
            addedAt: addedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$VaultRelaysTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({vaultId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (vaultId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.vaultId,
                    referencedTable:
                        $$VaultRelaysTableReferences._vaultIdTable(db),
                    referencedColumn:
                        $$VaultRelaysTableReferences._vaultIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$VaultRelaysTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $VaultRelaysTable,
    VaultRelayRow,
    $$VaultRelaysTableFilterComposer,
    $$VaultRelaysTableOrderingComposer,
    $$VaultRelaysTableAnnotationComposer,
    $$VaultRelaysTableCreateCompanionBuilder,
    $$VaultRelaysTableUpdateCompanionBuilder,
    (VaultRelayRow, $$VaultRelaysTableReferences),
    VaultRelayRow,
    PrefetchHooks Function({bool vaultId})>;
typedef $$OwnedVaultsTableCreateCompanionBuilder = OwnedVaultsCompanion
    Function({
  required String vaultId,
  required String content,
  required Uint8List contentHmac,
  required int createdBySelfAt,
  Value<int> rowid,
});
typedef $$OwnedVaultsTableUpdateCompanionBuilder = OwnedVaultsCompanion
    Function({
  Value<String> vaultId,
  Value<String> content,
  Value<Uint8List> contentHmac,
  Value<int> createdBySelfAt,
  Value<int> rowid,
});

final class $$OwnedVaultsTableReferences
    extends BaseReferences<_$AppDatabase, $OwnedVaultsTable, OwnedVaultRow> {
  $$OwnedVaultsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $VaultsTable _vaultIdTable(_$AppDatabase db) => db.vaults
      .createAlias($_aliasNameGenerator(db.ownedVaults.vaultId, db.vaults.id));

  $$VaultsTableProcessedTableManager get vaultId {
    final $_column = $_itemColumn<String>('vault_id')!;

    final manager = $$VaultsTableTableManager($_db, $_db.vaults)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_vaultIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$OwnedVaultsTableFilterComposer
    extends Composer<_$AppDatabase, $OwnedVaultsTable> {
  $$OwnedVaultsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<Uint8List> get contentHmac => $composableBuilder(
      column: $table.contentHmac, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdBySelfAt => $composableBuilder(
      column: $table.createdBySelfAt,
      builder: (column) => ColumnFilters(column));

  $$VaultsTableFilterComposer get vaultId {
    final $$VaultsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.vaultId,
        referencedTable: $db.vaults,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VaultsTableFilterComposer(
              $db: $db,
              $table: $db.vaults,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$OwnedVaultsTableOrderingComposer
    extends Composer<_$AppDatabase, $OwnedVaultsTable> {
  $$OwnedVaultsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<Uint8List> get contentHmac => $composableBuilder(
      column: $table.contentHmac, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdBySelfAt => $composableBuilder(
      column: $table.createdBySelfAt,
      builder: (column) => ColumnOrderings(column));

  $$VaultsTableOrderingComposer get vaultId {
    final $$VaultsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.vaultId,
        referencedTable: $db.vaults,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VaultsTableOrderingComposer(
              $db: $db,
              $table: $db.vaults,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$OwnedVaultsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OwnedVaultsTable> {
  $$OwnedVaultsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<Uint8List> get contentHmac => $composableBuilder(
      column: $table.contentHmac, builder: (column) => column);

  GeneratedColumn<int> get createdBySelfAt => $composableBuilder(
      column: $table.createdBySelfAt, builder: (column) => column);

  $$VaultsTableAnnotationComposer get vaultId {
    final $$VaultsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.vaultId,
        referencedTable: $db.vaults,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VaultsTableAnnotationComposer(
              $db: $db,
              $table: $db.vaults,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$OwnedVaultsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $OwnedVaultsTable,
    OwnedVaultRow,
    $$OwnedVaultsTableFilterComposer,
    $$OwnedVaultsTableOrderingComposer,
    $$OwnedVaultsTableAnnotationComposer,
    $$OwnedVaultsTableCreateCompanionBuilder,
    $$OwnedVaultsTableUpdateCompanionBuilder,
    (OwnedVaultRow, $$OwnedVaultsTableReferences),
    OwnedVaultRow,
    PrefetchHooks Function({bool vaultId})> {
  $$OwnedVaultsTableTableManager(_$AppDatabase db, $OwnedVaultsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OwnedVaultsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OwnedVaultsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OwnedVaultsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> vaultId = const Value.absent(),
            Value<String> content = const Value.absent(),
            Value<Uint8List> contentHmac = const Value.absent(),
            Value<int> createdBySelfAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              OwnedVaultsCompanion(
            vaultId: vaultId,
            content: content,
            contentHmac: contentHmac,
            createdBySelfAt: createdBySelfAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String vaultId,
            required String content,
            required Uint8List contentHmac,
            required int createdBySelfAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              OwnedVaultsCompanion.insert(
            vaultId: vaultId,
            content: content,
            contentHmac: contentHmac,
            createdBySelfAt: createdBySelfAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$OwnedVaultsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({vaultId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (vaultId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.vaultId,
                    referencedTable:
                        $$OwnedVaultsTableReferences._vaultIdTable(db),
                    referencedColumn:
                        $$OwnedVaultsTableReferences._vaultIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$OwnedVaultsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $OwnedVaultsTable,
    OwnedVaultRow,
    $$OwnedVaultsTableFilterComposer,
    $$OwnedVaultsTableOrderingComposer,
    $$OwnedVaultsTableAnnotationComposer,
    $$OwnedVaultsTableCreateCompanionBuilder,
    $$OwnedVaultsTableUpdateCompanionBuilder,
    (OwnedVaultRow, $$OwnedVaultsTableReferences),
    OwnedVaultRow,
    PrefetchHooks Function({bool vaultId})>;
typedef $$StewardsTableCreateCompanionBuilder = StewardsCompanion Function({
  required String id,
  required String vaultId,
  required int shareIndex,
  Value<String?> pubkey,
  Value<String?> name,
  Value<String?> contactInfo,
  Value<bool> isOwner,
  required int joinedAt,
  Value<int?> leftAt,
  Value<String?> removalReason,
  Value<int> rowid,
});
typedef $$StewardsTableUpdateCompanionBuilder = StewardsCompanion Function({
  Value<String> id,
  Value<String> vaultId,
  Value<int> shareIndex,
  Value<String?> pubkey,
  Value<String?> name,
  Value<String?> contactInfo,
  Value<bool> isOwner,
  Value<int> joinedAt,
  Value<int?> leftAt,
  Value<String?> removalReason,
  Value<int> rowid,
});

final class $$StewardsTableReferences
    extends BaseReferences<_$AppDatabase, $StewardsTable, StewardRow> {
  $$StewardsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $VaultsTable _vaultIdTable(_$AppDatabase db) => db.vaults
      .createAlias($_aliasNameGenerator(db.stewards.vaultId, db.vaults.id));

  $$VaultsTableProcessedTableManager get vaultId {
    final $_column = $_itemColumn<String>('vault_id')!;

    final manager = $$VaultsTableTableManager($_db, $_db.vaults)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_vaultIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$DistributionSharesTable,
      List<DistributionShareRow>> _distributionSharesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.distributionShares,
          aliasName: $_aliasNameGenerator(
              db.stewards.id, db.distributionShares.stewardId));

  $$DistributionSharesTableProcessedTableManager get distributionSharesRefs {
    final manager = $$DistributionSharesTableTableManager(
            $_db, $_db.distributionShares)
        .filter((f) => f.stewardId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_distributionSharesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$StewardsTableFilterComposer
    extends Composer<_$AppDatabase, $StewardsTable> {
  $$StewardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get shareIndex => $composableBuilder(
      column: $table.shareIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pubkey => $composableBuilder(
      column: $table.pubkey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get contactInfo => $composableBuilder(
      column: $table.contactInfo, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isOwner => $composableBuilder(
      column: $table.isOwner, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get joinedAt => $composableBuilder(
      column: $table.joinedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get leftAt => $composableBuilder(
      column: $table.leftAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get removalReason => $composableBuilder(
      column: $table.removalReason, builder: (column) => ColumnFilters(column));

  $$VaultsTableFilterComposer get vaultId {
    final $$VaultsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.vaultId,
        referencedTable: $db.vaults,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VaultsTableFilterComposer(
              $db: $db,
              $table: $db.vaults,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> distributionSharesRefs(
      Expression<bool> Function($$DistributionSharesTableFilterComposer f) f) {
    final $$DistributionSharesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.distributionShares,
        getReferencedColumn: (t) => t.stewardId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DistributionSharesTableFilterComposer(
              $db: $db,
              $table: $db.distributionShares,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$StewardsTableOrderingComposer
    extends Composer<_$AppDatabase, $StewardsTable> {
  $$StewardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get shareIndex => $composableBuilder(
      column: $table.shareIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pubkey => $composableBuilder(
      column: $table.pubkey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get contactInfo => $composableBuilder(
      column: $table.contactInfo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isOwner => $composableBuilder(
      column: $table.isOwner, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get joinedAt => $composableBuilder(
      column: $table.joinedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get leftAt => $composableBuilder(
      column: $table.leftAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get removalReason => $composableBuilder(
      column: $table.removalReason,
      builder: (column) => ColumnOrderings(column));

  $$VaultsTableOrderingComposer get vaultId {
    final $$VaultsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.vaultId,
        referencedTable: $db.vaults,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VaultsTableOrderingComposer(
              $db: $db,
              $table: $db.vaults,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$StewardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StewardsTable> {
  $$StewardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get shareIndex => $composableBuilder(
      column: $table.shareIndex, builder: (column) => column);

  GeneratedColumn<String> get pubkey =>
      $composableBuilder(column: $table.pubkey, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get contactInfo => $composableBuilder(
      column: $table.contactInfo, builder: (column) => column);

  GeneratedColumn<bool> get isOwner =>
      $composableBuilder(column: $table.isOwner, builder: (column) => column);

  GeneratedColumn<int> get joinedAt =>
      $composableBuilder(column: $table.joinedAt, builder: (column) => column);

  GeneratedColumn<int> get leftAt =>
      $composableBuilder(column: $table.leftAt, builder: (column) => column);

  GeneratedColumn<String> get removalReason => $composableBuilder(
      column: $table.removalReason, builder: (column) => column);

  $$VaultsTableAnnotationComposer get vaultId {
    final $$VaultsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.vaultId,
        referencedTable: $db.vaults,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VaultsTableAnnotationComposer(
              $db: $db,
              $table: $db.vaults,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> distributionSharesRefs<T extends Object>(
      Expression<T> Function($$DistributionSharesTableAnnotationComposer a) f) {
    final $$DistributionSharesTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.distributionShares,
            getReferencedColumn: (t) => t.stewardId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$DistributionSharesTableAnnotationComposer(
                  $db: $db,
                  $table: $db.distributionShares,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$StewardsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $StewardsTable,
    StewardRow,
    $$StewardsTableFilterComposer,
    $$StewardsTableOrderingComposer,
    $$StewardsTableAnnotationComposer,
    $$StewardsTableCreateCompanionBuilder,
    $$StewardsTableUpdateCompanionBuilder,
    (StewardRow, $$StewardsTableReferences),
    StewardRow,
    PrefetchHooks Function({bool vaultId, bool distributionSharesRefs})> {
  $$StewardsTableTableManager(_$AppDatabase db, $StewardsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StewardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StewardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StewardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> vaultId = const Value.absent(),
            Value<int> shareIndex = const Value.absent(),
            Value<String?> pubkey = const Value.absent(),
            Value<String?> name = const Value.absent(),
            Value<String?> contactInfo = const Value.absent(),
            Value<bool> isOwner = const Value.absent(),
            Value<int> joinedAt = const Value.absent(),
            Value<int?> leftAt = const Value.absent(),
            Value<String?> removalReason = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StewardsCompanion(
            id: id,
            vaultId: vaultId,
            shareIndex: shareIndex,
            pubkey: pubkey,
            name: name,
            contactInfo: contactInfo,
            isOwner: isOwner,
            joinedAt: joinedAt,
            leftAt: leftAt,
            removalReason: removalReason,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String vaultId,
            required int shareIndex,
            Value<String?> pubkey = const Value.absent(),
            Value<String?> name = const Value.absent(),
            Value<String?> contactInfo = const Value.absent(),
            Value<bool> isOwner = const Value.absent(),
            required int joinedAt,
            Value<int?> leftAt = const Value.absent(),
            Value<String?> removalReason = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StewardsCompanion.insert(
            id: id,
            vaultId: vaultId,
            shareIndex: shareIndex,
            pubkey: pubkey,
            name: name,
            contactInfo: contactInfo,
            isOwner: isOwner,
            joinedAt: joinedAt,
            leftAt: leftAt,
            removalReason: removalReason,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$StewardsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {vaultId = false, distributionSharesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (distributionSharesRefs) db.distributionShares
              ],
              addJoins: <
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
                      dynamic>>(state) {
                if (vaultId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.vaultId,
                    referencedTable:
                        $$StewardsTableReferences._vaultIdTable(db),
                    referencedColumn:
                        $$StewardsTableReferences._vaultIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (distributionSharesRefs)
                    await $_getPrefetchedData<StewardRow, $StewardsTable,
                            DistributionShareRow>(
                        currentTable: table,
                        referencedTable: $$StewardsTableReferences
                            ._distributionSharesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$StewardsTableReferences(db, table, p0)
                                .distributionSharesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.stewardId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$StewardsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $StewardsTable,
    StewardRow,
    $$StewardsTableFilterComposer,
    $$StewardsTableOrderingComposer,
    $$StewardsTableAnnotationComposer,
    $$StewardsTableCreateCompanionBuilder,
    $$StewardsTableUpdateCompanionBuilder,
    (StewardRow, $$StewardsTableReferences),
    StewardRow,
    PrefetchHooks Function({bool vaultId, bool distributionSharesRefs})>;
typedef $$DistributionsTableCreateCompanionBuilder = DistributionsCompanion
    Function({
  required String id,
  required String vaultId,
  required int version,
  required int createdAt,
  Value<int?> completedAt,
  required Uint8List contentHmac,
  Value<int> rowid,
});
typedef $$DistributionsTableUpdateCompanionBuilder = DistributionsCompanion
    Function({
  Value<String> id,
  Value<String> vaultId,
  Value<int> version,
  Value<int> createdAt,
  Value<int?> completedAt,
  Value<Uint8List> contentHmac,
  Value<int> rowid,
});

final class $$DistributionsTableReferences extends BaseReferences<_$AppDatabase,
    $DistributionsTable, DistributionRow> {
  $$DistributionsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $VaultsTable _vaultIdTable(_$AppDatabase db) => db.vaults.createAlias(
      $_aliasNameGenerator(db.distributions.vaultId, db.vaults.id));

  $$VaultsTableProcessedTableManager get vaultId {
    final $_column = $_itemColumn<String>('vault_id')!;

    final manager = $$VaultsTableTableManager($_db, $_db.vaults)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_vaultIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$DistributionSharesTable,
      List<DistributionShareRow>> _distributionSharesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.distributionShares,
          aliasName: $_aliasNameGenerator(
              db.distributions.id, db.distributionShares.distributionId));

  $$DistributionSharesTableProcessedTableManager get distributionSharesRefs {
    final manager = $$DistributionSharesTableTableManager(
            $_db, $_db.distributionShares)
        .filter(
            (f) => f.distributionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_distributionSharesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$DistributionsTableFilterComposer
    extends Composer<_$AppDatabase, $DistributionsTable> {
  $$DistributionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<Uint8List> get contentHmac => $composableBuilder(
      column: $table.contentHmac, builder: (column) => ColumnFilters(column));

  $$VaultsTableFilterComposer get vaultId {
    final $$VaultsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.vaultId,
        referencedTable: $db.vaults,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VaultsTableFilterComposer(
              $db: $db,
              $table: $db.vaults,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> distributionSharesRefs(
      Expression<bool> Function($$DistributionSharesTableFilterComposer f) f) {
    final $$DistributionSharesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.distributionShares,
        getReferencedColumn: (t) => t.distributionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DistributionSharesTableFilterComposer(
              $db: $db,
              $table: $db.distributionShares,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$DistributionsTableOrderingComposer
    extends Composer<_$AppDatabase, $DistributionsTable> {
  $$DistributionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<Uint8List> get contentHmac => $composableBuilder(
      column: $table.contentHmac, builder: (column) => ColumnOrderings(column));

  $$VaultsTableOrderingComposer get vaultId {
    final $$VaultsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.vaultId,
        referencedTable: $db.vaults,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VaultsTableOrderingComposer(
              $db: $db,
              $table: $db.vaults,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DistributionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DistributionsTable> {
  $$DistributionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => column);

  GeneratedColumn<Uint8List> get contentHmac => $composableBuilder(
      column: $table.contentHmac, builder: (column) => column);

  $$VaultsTableAnnotationComposer get vaultId {
    final $$VaultsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.vaultId,
        referencedTable: $db.vaults,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VaultsTableAnnotationComposer(
              $db: $db,
              $table: $db.vaults,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> distributionSharesRefs<T extends Object>(
      Expression<T> Function($$DistributionSharesTableAnnotationComposer a) f) {
    final $$DistributionSharesTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.distributionShares,
            getReferencedColumn: (t) => t.distributionId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$DistributionSharesTableAnnotationComposer(
                  $db: $db,
                  $table: $db.distributionShares,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$DistributionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DistributionsTable,
    DistributionRow,
    $$DistributionsTableFilterComposer,
    $$DistributionsTableOrderingComposer,
    $$DistributionsTableAnnotationComposer,
    $$DistributionsTableCreateCompanionBuilder,
    $$DistributionsTableUpdateCompanionBuilder,
    (DistributionRow, $$DistributionsTableReferences),
    DistributionRow,
    PrefetchHooks Function({bool vaultId, bool distributionSharesRefs})> {
  $$DistributionsTableTableManager(_$AppDatabase db, $DistributionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DistributionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DistributionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DistributionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> vaultId = const Value.absent(),
            Value<int> version = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int?> completedAt = const Value.absent(),
            Value<Uint8List> contentHmac = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DistributionsCompanion(
            id: id,
            vaultId: vaultId,
            version: version,
            createdAt: createdAt,
            completedAt: completedAt,
            contentHmac: contentHmac,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String vaultId,
            required int version,
            required int createdAt,
            Value<int?> completedAt = const Value.absent(),
            required Uint8List contentHmac,
            Value<int> rowid = const Value.absent(),
          }) =>
              DistributionsCompanion.insert(
            id: id,
            vaultId: vaultId,
            version: version,
            createdAt: createdAt,
            completedAt: completedAt,
            contentHmac: contentHmac,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$DistributionsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {vaultId = false, distributionSharesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (distributionSharesRefs) db.distributionShares
              ],
              addJoins: <
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
                      dynamic>>(state) {
                if (vaultId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.vaultId,
                    referencedTable:
                        $$DistributionsTableReferences._vaultIdTable(db),
                    referencedColumn:
                        $$DistributionsTableReferences._vaultIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (distributionSharesRefs)
                    await $_getPrefetchedData<DistributionRow,
                            $DistributionsTable, DistributionShareRow>(
                        currentTable: table,
                        referencedTable: $$DistributionsTableReferences
                            ._distributionSharesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$DistributionsTableReferences(db, table, p0)
                                .distributionSharesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.distributionId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$DistributionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DistributionsTable,
    DistributionRow,
    $$DistributionsTableFilterComposer,
    $$DistributionsTableOrderingComposer,
    $$DistributionsTableAnnotationComposer,
    $$DistributionsTableCreateCompanionBuilder,
    $$DistributionsTableUpdateCompanionBuilder,
    (DistributionRow, $$DistributionsTableReferences),
    DistributionRow,
    PrefetchHooks Function({bool vaultId, bool distributionSharesRefs})>;
typedef $$DistributionSharesTableCreateCompanionBuilder
    = DistributionSharesCompanion Function({
  required String id,
  required String distributionId,
  required String stewardId,
  required String giftWrapEventId,
  Value<int?> sentAt,
  Value<int?> acknowledgedAt,
  Value<String?> acknowledgmentEventId,
  Value<int?> acknowledgmentDistributionVersion,
  Value<int?> acknowledgmentCreatedAt,
  Value<int> rowid,
});
typedef $$DistributionSharesTableUpdateCompanionBuilder
    = DistributionSharesCompanion Function({
  Value<String> id,
  Value<String> distributionId,
  Value<String> stewardId,
  Value<String> giftWrapEventId,
  Value<int?> sentAt,
  Value<int?> acknowledgedAt,
  Value<String?> acknowledgmentEventId,
  Value<int?> acknowledgmentDistributionVersion,
  Value<int?> acknowledgmentCreatedAt,
  Value<int> rowid,
});

final class $$DistributionSharesTableReferences extends BaseReferences<
    _$AppDatabase, $DistributionSharesTable, DistributionShareRow> {
  $$DistributionSharesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $DistributionsTable _distributionIdTable(_$AppDatabase db) =>
      db.distributions.createAlias($_aliasNameGenerator(
          db.distributionShares.distributionId, db.distributions.id));

  $$DistributionsTableProcessedTableManager get distributionId {
    final $_column = $_itemColumn<String>('distribution_id')!;

    final manager = $$DistributionsTableTableManager($_db, $_db.distributions)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_distributionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $StewardsTable _stewardIdTable(_$AppDatabase db) =>
      db.stewards.createAlias($_aliasNameGenerator(
          db.distributionShares.stewardId, db.stewards.id));

  $$StewardsTableProcessedTableManager get stewardId {
    final $_column = $_itemColumn<String>('steward_id')!;

    final manager = $$StewardsTableTableManager($_db, $_db.stewards)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_stewardIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$DistributionSharesTableFilterComposer
    extends Composer<_$AppDatabase, $DistributionSharesTable> {
  $$DistributionSharesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get giftWrapEventId => $composableBuilder(
      column: $table.giftWrapEventId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sentAt => $composableBuilder(
      column: $table.sentAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get acknowledgedAt => $composableBuilder(
      column: $table.acknowledgedAt,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get acknowledgmentEventId => $composableBuilder(
      column: $table.acknowledgmentEventId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get acknowledgmentDistributionVersion =>
      $composableBuilder(
          column: $table.acknowledgmentDistributionVersion,
          builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get acknowledgmentCreatedAt => $composableBuilder(
      column: $table.acknowledgmentCreatedAt,
      builder: (column) => ColumnFilters(column));

  $$DistributionsTableFilterComposer get distributionId {
    final $$DistributionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.distributionId,
        referencedTable: $db.distributions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DistributionsTableFilterComposer(
              $db: $db,
              $table: $db.distributions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$StewardsTableFilterComposer get stewardId {
    final $$StewardsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.stewardId,
        referencedTable: $db.stewards,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StewardsTableFilterComposer(
              $db: $db,
              $table: $db.stewards,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DistributionSharesTableOrderingComposer
    extends Composer<_$AppDatabase, $DistributionSharesTable> {
  $$DistributionSharesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get giftWrapEventId => $composableBuilder(
      column: $table.giftWrapEventId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sentAt => $composableBuilder(
      column: $table.sentAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get acknowledgedAt => $composableBuilder(
      column: $table.acknowledgedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get acknowledgmentEventId => $composableBuilder(
      column: $table.acknowledgmentEventId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get acknowledgmentDistributionVersion =>
      $composableBuilder(
          column: $table.acknowledgmentDistributionVersion,
          builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get acknowledgmentCreatedAt => $composableBuilder(
      column: $table.acknowledgmentCreatedAt,
      builder: (column) => ColumnOrderings(column));

  $$DistributionsTableOrderingComposer get distributionId {
    final $$DistributionsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.distributionId,
        referencedTable: $db.distributions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DistributionsTableOrderingComposer(
              $db: $db,
              $table: $db.distributions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$StewardsTableOrderingComposer get stewardId {
    final $$StewardsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.stewardId,
        referencedTable: $db.stewards,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StewardsTableOrderingComposer(
              $db: $db,
              $table: $db.stewards,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DistributionSharesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DistributionSharesTable> {
  $$DistributionSharesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get giftWrapEventId => $composableBuilder(
      column: $table.giftWrapEventId, builder: (column) => column);

  GeneratedColumn<int> get sentAt =>
      $composableBuilder(column: $table.sentAt, builder: (column) => column);

  GeneratedColumn<int> get acknowledgedAt => $composableBuilder(
      column: $table.acknowledgedAt, builder: (column) => column);

  GeneratedColumn<String> get acknowledgmentEventId => $composableBuilder(
      column: $table.acknowledgmentEventId, builder: (column) => column);

  GeneratedColumn<int> get acknowledgmentDistributionVersion =>
      $composableBuilder(
          column: $table.acknowledgmentDistributionVersion,
          builder: (column) => column);

  GeneratedColumn<int> get acknowledgmentCreatedAt => $composableBuilder(
      column: $table.acknowledgmentCreatedAt, builder: (column) => column);

  $$DistributionsTableAnnotationComposer get distributionId {
    final $$DistributionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.distributionId,
        referencedTable: $db.distributions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DistributionsTableAnnotationComposer(
              $db: $db,
              $table: $db.distributions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$StewardsTableAnnotationComposer get stewardId {
    final $$StewardsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.stewardId,
        referencedTable: $db.stewards,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StewardsTableAnnotationComposer(
              $db: $db,
              $table: $db.stewards,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DistributionSharesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DistributionSharesTable,
    DistributionShareRow,
    $$DistributionSharesTableFilterComposer,
    $$DistributionSharesTableOrderingComposer,
    $$DistributionSharesTableAnnotationComposer,
    $$DistributionSharesTableCreateCompanionBuilder,
    $$DistributionSharesTableUpdateCompanionBuilder,
    (DistributionShareRow, $$DistributionSharesTableReferences),
    DistributionShareRow,
    PrefetchHooks Function({bool distributionId, bool stewardId})> {
  $$DistributionSharesTableTableManager(
      _$AppDatabase db, $DistributionSharesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DistributionSharesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DistributionSharesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DistributionSharesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> distributionId = const Value.absent(),
            Value<String> stewardId = const Value.absent(),
            Value<String> giftWrapEventId = const Value.absent(),
            Value<int?> sentAt = const Value.absent(),
            Value<int?> acknowledgedAt = const Value.absent(),
            Value<String?> acknowledgmentEventId = const Value.absent(),
            Value<int?> acknowledgmentDistributionVersion =
                const Value.absent(),
            Value<int?> acknowledgmentCreatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DistributionSharesCompanion(
            id: id,
            distributionId: distributionId,
            stewardId: stewardId,
            giftWrapEventId: giftWrapEventId,
            sentAt: sentAt,
            acknowledgedAt: acknowledgedAt,
            acknowledgmentEventId: acknowledgmentEventId,
            acknowledgmentDistributionVersion:
                acknowledgmentDistributionVersion,
            acknowledgmentCreatedAt: acknowledgmentCreatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String distributionId,
            required String stewardId,
            required String giftWrapEventId,
            Value<int?> sentAt = const Value.absent(),
            Value<int?> acknowledgedAt = const Value.absent(),
            Value<String?> acknowledgmentEventId = const Value.absent(),
            Value<int?> acknowledgmentDistributionVersion =
                const Value.absent(),
            Value<int?> acknowledgmentCreatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DistributionSharesCompanion.insert(
            id: id,
            distributionId: distributionId,
            stewardId: stewardId,
            giftWrapEventId: giftWrapEventId,
            sentAt: sentAt,
            acknowledgedAt: acknowledgedAt,
            acknowledgmentEventId: acknowledgmentEventId,
            acknowledgmentDistributionVersion:
                acknowledgmentDistributionVersion,
            acknowledgmentCreatedAt: acknowledgmentCreatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$DistributionSharesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({distributionId = false, stewardId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (distributionId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.distributionId,
                    referencedTable: $$DistributionSharesTableReferences
                        ._distributionIdTable(db),
                    referencedColumn: $$DistributionSharesTableReferences
                        ._distributionIdTable(db)
                        .id,
                  ) as T;
                }
                if (stewardId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.stewardId,
                    referencedTable:
                        $$DistributionSharesTableReferences._stewardIdTable(db),
                    referencedColumn: $$DistributionSharesTableReferences
                        ._stewardIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$DistributionSharesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DistributionSharesTable,
    DistributionShareRow,
    $$DistributionSharesTableFilterComposer,
    $$DistributionSharesTableOrderingComposer,
    $$DistributionSharesTableAnnotationComposer,
    $$DistributionSharesTableCreateCompanionBuilder,
    $$DistributionSharesTableUpdateCompanionBuilder,
    (DistributionShareRow, $$DistributionSharesTableReferences),
    DistributionShareRow,
    PrefetchHooks Function({bool distributionId, bool stewardId})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$VaultsTableTableManager get vaults =>
      $$VaultsTableTableManager(_db, _db.vaults);
  $$VaultRelaysTableTableManager get vaultRelays =>
      $$VaultRelaysTableTableManager(_db, _db.vaultRelays);
  $$OwnedVaultsTableTableManager get ownedVaults =>
      $$OwnedVaultsTableTableManager(_db, _db.ownedVaults);
  $$StewardsTableTableManager get stewards =>
      $$StewardsTableTableManager(_db, _db.stewards);
  $$DistributionsTableTableManager get distributions =>
      $$DistributionsTableTableManager(_db, _db.distributions);
  $$DistributionSharesTableTableManager get distributionShares =>
      $$DistributionSharesTableTableManager(_db, _db.distributionShares);
}
