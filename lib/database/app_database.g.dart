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
  late final GeneratedColumn<String> id = GeneratedColumn<String>('id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>('name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ownerPubkeyMeta = const VerificationMeta('ownerPubkey');
  @override
  late final GeneratedColumn<String> ownerPubkey = GeneratedColumn<String>(
      'owner_pubkey', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ownerNameMeta = const VerificationMeta('ownerName');
  @override
  late final GeneratedColumn<String> ownerName = GeneratedColumn<String>(
      'owner_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _thresholdMeta = const VerificationMeta('threshold');
  @override
  late final GeneratedColumn<int> threshold = GeneratedColumn<int>('threshold', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _primeModMeta = const VerificationMeta('primeMod');
  @override
  late final GeneratedColumn<String> primeMod = GeneratedColumn<String>(
      'prime_mod', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _totalSharesMeta = const VerificationMeta('totalShares');
  @override
  late final GeneratedColumn<int> totalShares = GeneratedColumn<int>(
      'total_shares', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _currentDistributionVersionMeta =
      const VerificationMeta('currentDistributionVersion');
  @override
  late final GeneratedColumn<int> currentDistributionVersion = GeneratedColumn<int>(
      'current_distribution_version', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false, defaultValue: const Constant(0));
  static const VerificationMeta _instructionsMeta = const VerificationMeta('instructions');
  @override
  late final GeneratedColumn<String> instructions = GeneratedColumn<String>(
      'instructions', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _pushEnabledMeta = const VerificationMeta('pushEnabled');
  @override
  late final GeneratedColumn<bool> pushEnabled = GeneratedColumn<bool>(
      'push_enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("push_enabled" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _archivedAtMeta = const VerificationMeta('archivedAt');
  @override
  late final GeneratedColumn<int> archivedAt = GeneratedColumn<int>(
      'archived_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _archivedReasonMeta = const VerificationMeta('archivedReason');
  @override
  late final GeneratedColumn<String> archivedReason = GeneratedColumn<String>(
      'archived_reason', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta('lastSyncedAt');
  @override
  late final GeneratedColumn<int> lastSyncedAt = GeneratedColumn<int>(
      'last_synced_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>('created_at', aliasedName, false,
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
  VerificationContext validateIntegrity(Insertable<VaultRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('owner_pubkey')) {
      context.handle(_ownerPubkeyMeta,
          ownerPubkey.isAcceptableOrUnknown(data['owner_pubkey']!, _ownerPubkeyMeta));
    } else if (isInserting) {
      context.missing(_ownerPubkeyMeta);
    }
    if (data.containsKey('owner_name')) {
      context.handle(
          _ownerNameMeta, ownerName.isAcceptableOrUnknown(data['owner_name']!, _ownerNameMeta));
    }
    if (data.containsKey('threshold')) {
      context.handle(
          _thresholdMeta, threshold.isAcceptableOrUnknown(data['threshold']!, _thresholdMeta));
    } else if (isInserting) {
      context.missing(_thresholdMeta);
    }
    if (data.containsKey('prime_mod')) {
      context.handle(
          _primeModMeta, primeMod.isAcceptableOrUnknown(data['prime_mod']!, _primeModMeta));
    }
    if (data.containsKey('total_shares')) {
      context.handle(_totalSharesMeta,
          totalShares.isAcceptableOrUnknown(data['total_shares']!, _totalSharesMeta));
    } else if (isInserting) {
      context.missing(_totalSharesMeta);
    }
    if (data.containsKey('current_distribution_version')) {
      context.handle(
          _currentDistributionVersionMeta,
          currentDistributionVersion.isAcceptableOrUnknown(
              data['current_distribution_version']!, _currentDistributionVersionMeta));
    }
    if (data.containsKey('instructions')) {
      context.handle(_instructionsMeta,
          instructions.isAcceptableOrUnknown(data['instructions']!, _instructionsMeta));
    }
    if (data.containsKey('push_enabled')) {
      context.handle(_pushEnabledMeta,
          pushEnabled.isAcceptableOrUnknown(data['push_enabled']!, _pushEnabledMeta));
    }
    if (data.containsKey('archived_at')) {
      context.handle(
          _archivedAtMeta, archivedAt.isAcceptableOrUnknown(data['archived_at']!, _archivedAtMeta));
    }
    if (data.containsKey('archived_reason')) {
      context.handle(_archivedReasonMeta,
          archivedReason.isAcceptableOrUnknown(data['archived_reason']!, _archivedReasonMeta));
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(_lastSyncedAtMeta,
          lastSyncedAt.isAcceptableOrUnknown(data['last_synced_at']!, _lastSyncedAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
          _createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
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
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      ownerPubkey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}owner_pubkey'])!,
      ownerName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}owner_name']),
      threshold:
          attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}threshold'])!,
      primeMod: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}prime_mod']),
      totalShares: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_shares'])!,
      currentDistributionVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}current_distribution_version'])!,
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
    map['current_distribution_version'] = Variable<int>(currentDistributionVersion);
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
      ownerName: ownerName == null && nullToAbsent ? const Value.absent() : Value(ownerName),
      threshold: Value(threshold),
      primeMod: primeMod == null && nullToAbsent ? const Value.absent() : Value(primeMod),
      totalShares: Value(totalShares),
      currentDistributionVersion: Value(currentDistributionVersion),
      instructions:
          instructions == null && nullToAbsent ? const Value.absent() : Value(instructions),
      pushEnabled: Value(pushEnabled),
      archivedAt: archivedAt == null && nullToAbsent ? const Value.absent() : Value(archivedAt),
      archivedReason:
          archivedReason == null && nullToAbsent ? const Value.absent() : Value(archivedReason),
      lastSyncedAt:
          lastSyncedAt == null && nullToAbsent ? const Value.absent() : Value(lastSyncedAt),
      createdAt: Value(createdAt),
    );
  }

  factory VaultRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VaultRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      ownerPubkey: serializer.fromJson<String>(json['ownerPubkey']),
      ownerName: serializer.fromJson<String?>(json['ownerName']),
      threshold: serializer.fromJson<int>(json['threshold']),
      primeMod: serializer.fromJson<String?>(json['primeMod']),
      totalShares: serializer.fromJson<int>(json['totalShares']),
      currentDistributionVersion: serializer.fromJson<int>(json['currentDistributionVersion']),
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
      'currentDistributionVersion': serializer.toJson<int>(currentDistributionVersion),
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
        currentDistributionVersion: currentDistributionVersion ?? this.currentDistributionVersion,
        instructions: instructions.present ? instructions.value : this.instructions,
        pushEnabled: pushEnabled ?? this.pushEnabled,
        archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
        archivedReason: archivedReason.present ? archivedReason.value : this.archivedReason,
        lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
        createdAt: createdAt ?? this.createdAt,
      );
  VaultRow copyWithCompanion(VaultsCompanion data) {
    return VaultRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      ownerPubkey: data.ownerPubkey.present ? data.ownerPubkey.value : this.ownerPubkey,
      ownerName: data.ownerName.present ? data.ownerName.value : this.ownerName,
      threshold: data.threshold.present ? data.threshold.value : this.threshold,
      primeMod: data.primeMod.present ? data.primeMod.value : this.primeMod,
      totalShares: data.totalShares.present ? data.totalShares.value : this.totalShares,
      currentDistributionVersion: data.currentDistributionVersion.present
          ? data.currentDistributionVersion.value
          : this.currentDistributionVersion,
      instructions: data.instructions.present ? data.instructions.value : this.instructions,
      pushEnabled: data.pushEnabled.present ? data.pushEnabled.value : this.pushEnabled,
      archivedAt: data.archivedAt.present ? data.archivedAt.value : this.archivedAt,
      archivedReason: data.archivedReason.present ? data.archivedReason.value : this.archivedReason,
      lastSyncedAt: data.lastSyncedAt.present ? data.lastSyncedAt.value : this.lastSyncedAt,
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
      currentDistributionVersion: currentDistributionVersion ?? this.currentDistributionVersion,
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
      map['current_distribution_version'] = Variable<int>(currentDistributionVersion.value);
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

class $VaultRelaysTable extends VaultRelays with TableInfo<$VaultRelaysTable, VaultRelayRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VaultRelaysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>('id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _vaultIdMeta = const VerificationMeta('vaultId');
  @override
  late final GeneratedColumn<String> vaultId = GeneratedColumn<String>(
      'vault_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES vaults (id) ON DELETE CASCADE'));
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>('url', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>('role', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _addedAtMeta = const VerificationMeta('addedAt');
  @override
  late final GeneratedColumn<int> addedAt = GeneratedColumn<int>('added_at', aliasedName, false,
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
      context.handle(_vaultIdMeta, vaultId.isAcceptableOrUnknown(data['vault_id']!, _vaultIdMeta));
    } else if (isInserting) {
      context.missing(_vaultIdMeta);
    }
    if (data.containsKey('url')) {
      context.handle(_urlMeta, url.isAcceptableOrUnknown(data['url']!, _urlMeta));
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('role')) {
      context.handle(_roleMeta, role.isAcceptableOrUnknown(data['role']!, _roleMeta));
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('added_at')) {
      context.handle(_addedAtMeta, addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta));
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
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      vaultId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}vault_id'])!,
      url: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}url'])!,
      role: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}role'])!,
      addedAt:
          attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}added_at'])!,
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

  factory VaultRelayRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
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

  VaultRelayRow copyWith({String? id, String? vaultId, String? url, String? role, int? addedAt}) =>
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

class $OwnedVaultsTable extends OwnedVaults with TableInfo<$OwnedVaultsTable, OwnedVaultRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OwnedVaultsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _vaultIdMeta = const VerificationMeta('vaultId');
  @override
  late final GeneratedColumn<String> vaultId = GeneratedColumn<String>(
      'vault_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES vaults (id) ON DELETE CASCADE'));
  static const VerificationMeta _contentMeta = const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contentHmacMeta = const VerificationMeta('contentHmac');
  @override
  late final GeneratedColumn<Uint8List> contentHmac = GeneratedColumn<Uint8List>(
      'content_hmac', aliasedName, false,
      type: DriftSqlType.blob, requiredDuringInsert: true);
  static const VerificationMeta _createdBySelfAtMeta = const VerificationMeta('createdBySelfAt');
  @override
  late final GeneratedColumn<int> createdBySelfAt = GeneratedColumn<int>(
      'created_by_self_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [vaultId, content, contentHmac, createdBySelfAt];
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
      context.handle(_vaultIdMeta, vaultId.isAcceptableOrUnknown(data['vault_id']!, _vaultIdMeta));
    } else if (isInserting) {
      context.missing(_vaultIdMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta, content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('content_hmac')) {
      context.handle(_contentHmacMeta,
          contentHmac.isAcceptableOrUnknown(data['content_hmac']!, _contentHmacMeta));
    } else if (isInserting) {
      context.missing(_contentHmacMeta);
    }
    if (data.containsKey('created_by_self_at')) {
      context.handle(_createdBySelfAtMeta,
          createdBySelfAt.isAcceptableOrUnknown(data['created_by_self_at']!, _createdBySelfAtMeta));
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
      createdBySelfAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_by_self_at'])!,
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

  factory OwnedVaultRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
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
          {String? vaultId, String? content, Uint8List? contentHmac, int? createdBySelfAt}) =>
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
      contentHmac: data.contentHmac.present ? data.contentHmac.value : this.contentHmac,
      createdBySelfAt:
          data.createdBySelfAt.present ? data.createdBySelfAt.value : this.createdBySelfAt,
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
  int get hashCode =>
      Object.hash(vaultId, content, $driftBlobEquality.hash(contentHmac), createdBySelfAt);
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

class $StewardsTable extends Stewards with TableInfo<$StewardsTable, StewardRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StewardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>('id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _vaultIdMeta = const VerificationMeta('vaultId');
  @override
  late final GeneratedColumn<String> vaultId = GeneratedColumn<String>(
      'vault_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES vaults (id) ON DELETE CASCADE'));
  static const VerificationMeta _shareIndexMeta = const VerificationMeta('shareIndex');
  @override
  late final GeneratedColumn<int> shareIndex = GeneratedColumn<int>(
      'share_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _pubkeyMeta = const VerificationMeta('pubkey');
  @override
  late final GeneratedColumn<String> pubkey = GeneratedColumn<String>('pubkey', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>('name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _contactInfoMeta = const VerificationMeta('contactInfo');
  @override
  late final GeneratedColumn<String> contactInfo = GeneratedColumn<String>(
      'contact_info', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isOwnerMeta = const VerificationMeta('isOwner');
  @override
  late final GeneratedColumn<bool> isOwner = GeneratedColumn<bool>('is_owner', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("is_owner" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _joinedAtMeta = const VerificationMeta('joinedAt');
  @override
  late final GeneratedColumn<int> joinedAt = GeneratedColumn<int>('joined_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _leftAtMeta = const VerificationMeta('leftAt');
  @override
  late final GeneratedColumn<int> leftAt = GeneratedColumn<int>('left_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _removalReasonMeta = const VerificationMeta('removalReason');
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
      context.handle(_vaultIdMeta, vaultId.isAcceptableOrUnknown(data['vault_id']!, _vaultIdMeta));
    } else if (isInserting) {
      context.missing(_vaultIdMeta);
    }
    if (data.containsKey('share_index')) {
      context.handle(
          _shareIndexMeta, shareIndex.isAcceptableOrUnknown(data['share_index']!, _shareIndexMeta));
    } else if (isInserting) {
      context.missing(_shareIndexMeta);
    }
    if (data.containsKey('pubkey')) {
      context.handle(_pubkeyMeta, pubkey.isAcceptableOrUnknown(data['pubkey']!, _pubkeyMeta));
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    }
    if (data.containsKey('contact_info')) {
      context.handle(_contactInfoMeta,
          contactInfo.isAcceptableOrUnknown(data['contact_info']!, _contactInfoMeta));
    }
    if (data.containsKey('is_owner')) {
      context.handle(_isOwnerMeta, isOwner.isAcceptableOrUnknown(data['is_owner']!, _isOwnerMeta));
    }
    if (data.containsKey('joined_at')) {
      context.handle(
          _joinedAtMeta, joinedAt.isAcceptableOrUnknown(data['joined_at']!, _joinedAtMeta));
    } else if (isInserting) {
      context.missing(_joinedAtMeta);
    }
    if (data.containsKey('left_at')) {
      context.handle(_leftAtMeta, leftAt.isAcceptableOrUnknown(data['left_at']!, _leftAtMeta));
    }
    if (data.containsKey('removal_reason')) {
      context.handle(_removalReasonMeta,
          removalReason.isAcceptableOrUnknown(data['removal_reason']!, _removalReasonMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StewardRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StewardRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      vaultId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}vault_id'])!,
      shareIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}share_index'])!,
      pubkey:
          attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}pubkey']),
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name']),
      contactInfo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}contact_info']),
      isOwner:
          attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}is_owner'])!,
      joinedAt:
          attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}joined_at'])!,
      leftAt:
          attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}left_at']),
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
      pubkey: pubkey == null && nullToAbsent ? const Value.absent() : Value(pubkey),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      contactInfo: contactInfo == null && nullToAbsent ? const Value.absent() : Value(contactInfo),
      isOwner: Value(isOwner),
      joinedAt: Value(joinedAt),
      leftAt: leftAt == null && nullToAbsent ? const Value.absent() : Value(leftAt),
      removalReason:
          removalReason == null && nullToAbsent ? const Value.absent() : Value(removalReason),
    );
  }

  factory StewardRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
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
        removalReason: removalReason.present ? removalReason.value : this.removalReason,
      );
  StewardRow copyWithCompanion(StewardsCompanion data) {
    return StewardRow(
      id: data.id.present ? data.id.value : this.id,
      vaultId: data.vaultId.present ? data.vaultId.value : this.vaultId,
      shareIndex: data.shareIndex.present ? data.shareIndex.value : this.shareIndex,
      pubkey: data.pubkey.present ? data.pubkey.value : this.pubkey,
      name: data.name.present ? data.name.value : this.name,
      contactInfo: data.contactInfo.present ? data.contactInfo.value : this.contactInfo,
      isOwner: data.isOwner.present ? data.isOwner.value : this.isOwner,
      joinedAt: data.joinedAt.present ? data.joinedAt.value : this.joinedAt,
      leftAt: data.leftAt.present ? data.leftAt.value : this.leftAt,
      removalReason: data.removalReason.present ? data.removalReason.value : this.removalReason,
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
  int get hashCode => Object.hash(
      id, vaultId, shareIndex, pubkey, name, contactInfo, isOwner, joinedAt, leftAt, removalReason);
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

class $InvitationsTable extends Invitations with TableInfo<$InvitationsTable, InvitationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InvitationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>('code', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _vaultIdMeta = const VerificationMeta('vaultId');
  @override
  late final GeneratedColumn<String> vaultId = GeneratedColumn<String>(
      'vault_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES vaults (id) ON DELETE CASCADE'));
  static const VerificationMeta _stewardIdMeta = const VerificationMeta('stewardId');
  @override
  late final GeneratedColumn<String> stewardId = GeneratedColumn<String>(
      'steward_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES stewards (id) ON DELETE CASCADE'));
  static const VerificationMeta _payloadMeta = const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
      'payload', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>('created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _expiresAtMeta = const VerificationMeta('expiresAt');
  @override
  late final GeneratedColumn<int> expiresAt = GeneratedColumn<int>('expires_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _acceptedAtMeta = const VerificationMeta('acceptedAt');
  @override
  late final GeneratedColumn<int> acceptedAt = GeneratedColumn<int>(
      'accepted_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _acceptedByPubkeyMeta = const VerificationMeta('acceptedByPubkey');
  @override
  late final GeneratedColumn<String> acceptedByPubkey = GeneratedColumn<String>(
      'accepted_by_pubkey', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _revokedAtMeta = const VerificationMeta('revokedAt');
  @override
  late final GeneratedColumn<int> revokedAt = GeneratedColumn<int>('revoked_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        code,
        vaultId,
        stewardId,
        payload,
        createdAt,
        expiresAt,
        acceptedAt,
        acceptedByPubkey,
        revokedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'invitations';
  @override
  VerificationContext validateIntegrity(Insertable<InvitationRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('code')) {
      context.handle(_codeMeta, code.isAcceptableOrUnknown(data['code']!, _codeMeta));
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('vault_id')) {
      context.handle(_vaultIdMeta, vaultId.isAcceptableOrUnknown(data['vault_id']!, _vaultIdMeta));
    } else if (isInserting) {
      context.missing(_vaultIdMeta);
    }
    if (data.containsKey('steward_id')) {
      context.handle(
          _stewardIdMeta, stewardId.isAcceptableOrUnknown(data['steward_id']!, _stewardIdMeta));
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta, payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
          _createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('expires_at')) {
      context.handle(
          _expiresAtMeta, expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta));
    }
    if (data.containsKey('accepted_at')) {
      context.handle(
          _acceptedAtMeta, acceptedAt.isAcceptableOrUnknown(data['accepted_at']!, _acceptedAtMeta));
    }
    if (data.containsKey('accepted_by_pubkey')) {
      context.handle(
          _acceptedByPubkeyMeta,
          acceptedByPubkey.isAcceptableOrUnknown(
              data['accepted_by_pubkey']!, _acceptedByPubkeyMeta));
    }
    if (data.containsKey('revoked_at')) {
      context.handle(
          _revokedAtMeta, revokedAt.isAcceptableOrUnknown(data['revoked_at']!, _revokedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {code};
  @override
  InvitationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InvitationRow(
      code: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}code'])!,
      vaultId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}vault_id'])!,
      stewardId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}steward_id']),
      payload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      expiresAt:
          attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}expires_at']),
      acceptedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}accepted_at']),
      acceptedByPubkey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}accepted_by_pubkey']),
      revokedAt:
          attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}revoked_at']),
    );
  }

  @override
  $InvitationsTable createAlias(String alias) {
    return $InvitationsTable(attachedDatabase, alias);
  }
}

class InvitationRow extends DataClass implements Insertable<InvitationRow> {
  /// Invite code (primary key).
  final String code;
  final String vaultId;
  final String? stewardId;

  /// JSON blob ([invitationLinkToJson]).
  final String payload;
  final int createdAt;
  final int? expiresAt;
  final int? acceptedAt;
  final String? acceptedByPubkey;
  final int? revokedAt;
  const InvitationRow(
      {required this.code,
      required this.vaultId,
      this.stewardId,
      required this.payload,
      required this.createdAt,
      this.expiresAt,
      this.acceptedAt,
      this.acceptedByPubkey,
      this.revokedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['code'] = Variable<String>(code);
    map['vault_id'] = Variable<String>(vaultId);
    if (!nullToAbsent || stewardId != null) {
      map['steward_id'] = Variable<String>(stewardId);
    }
    map['payload'] = Variable<String>(payload);
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || expiresAt != null) {
      map['expires_at'] = Variable<int>(expiresAt);
    }
    if (!nullToAbsent || acceptedAt != null) {
      map['accepted_at'] = Variable<int>(acceptedAt);
    }
    if (!nullToAbsent || acceptedByPubkey != null) {
      map['accepted_by_pubkey'] = Variable<String>(acceptedByPubkey);
    }
    if (!nullToAbsent || revokedAt != null) {
      map['revoked_at'] = Variable<int>(revokedAt);
    }
    return map;
  }

  InvitationsCompanion toCompanion(bool nullToAbsent) {
    return InvitationsCompanion(
      code: Value(code),
      vaultId: Value(vaultId),
      stewardId: stewardId == null && nullToAbsent ? const Value.absent() : Value(stewardId),
      payload: Value(payload),
      createdAt: Value(createdAt),
      expiresAt: expiresAt == null && nullToAbsent ? const Value.absent() : Value(expiresAt),
      acceptedAt: acceptedAt == null && nullToAbsent ? const Value.absent() : Value(acceptedAt),
      acceptedByPubkey:
          acceptedByPubkey == null && nullToAbsent ? const Value.absent() : Value(acceptedByPubkey),
      revokedAt: revokedAt == null && nullToAbsent ? const Value.absent() : Value(revokedAt),
    );
  }

  factory InvitationRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InvitationRow(
      code: serializer.fromJson<String>(json['code']),
      vaultId: serializer.fromJson<String>(json['vaultId']),
      stewardId: serializer.fromJson<String?>(json['stewardId']),
      payload: serializer.fromJson<String>(json['payload']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      expiresAt: serializer.fromJson<int?>(json['expiresAt']),
      acceptedAt: serializer.fromJson<int?>(json['acceptedAt']),
      acceptedByPubkey: serializer.fromJson<String?>(json['acceptedByPubkey']),
      revokedAt: serializer.fromJson<int?>(json['revokedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'code': serializer.toJson<String>(code),
      'vaultId': serializer.toJson<String>(vaultId),
      'stewardId': serializer.toJson<String?>(stewardId),
      'payload': serializer.toJson<String>(payload),
      'createdAt': serializer.toJson<int>(createdAt),
      'expiresAt': serializer.toJson<int?>(expiresAt),
      'acceptedAt': serializer.toJson<int?>(acceptedAt),
      'acceptedByPubkey': serializer.toJson<String?>(acceptedByPubkey),
      'revokedAt': serializer.toJson<int?>(revokedAt),
    };
  }

  InvitationRow copyWith(
          {String? code,
          String? vaultId,
          Value<String?> stewardId = const Value.absent(),
          String? payload,
          int? createdAt,
          Value<int?> expiresAt = const Value.absent(),
          Value<int?> acceptedAt = const Value.absent(),
          Value<String?> acceptedByPubkey = const Value.absent(),
          Value<int?> revokedAt = const Value.absent()}) =>
      InvitationRow(
        code: code ?? this.code,
        vaultId: vaultId ?? this.vaultId,
        stewardId: stewardId.present ? stewardId.value : this.stewardId,
        payload: payload ?? this.payload,
        createdAt: createdAt ?? this.createdAt,
        expiresAt: expiresAt.present ? expiresAt.value : this.expiresAt,
        acceptedAt: acceptedAt.present ? acceptedAt.value : this.acceptedAt,
        acceptedByPubkey: acceptedByPubkey.present ? acceptedByPubkey.value : this.acceptedByPubkey,
        revokedAt: revokedAt.present ? revokedAt.value : this.revokedAt,
      );
  InvitationRow copyWithCompanion(InvitationsCompanion data) {
    return InvitationRow(
      code: data.code.present ? data.code.value : this.code,
      vaultId: data.vaultId.present ? data.vaultId.value : this.vaultId,
      stewardId: data.stewardId.present ? data.stewardId.value : this.stewardId,
      payload: data.payload.present ? data.payload.value : this.payload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      acceptedAt: data.acceptedAt.present ? data.acceptedAt.value : this.acceptedAt,
      acceptedByPubkey:
          data.acceptedByPubkey.present ? data.acceptedByPubkey.value : this.acceptedByPubkey,
      revokedAt: data.revokedAt.present ? data.revokedAt.value : this.revokedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InvitationRow(')
          ..write('code: $code, ')
          ..write('vaultId: $vaultId, ')
          ..write('stewardId: $stewardId, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('acceptedAt: $acceptedAt, ')
          ..write('acceptedByPubkey: $acceptedByPubkey, ')
          ..write('revokedAt: $revokedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(code, vaultId, stewardId, payload, createdAt, expiresAt,
      acceptedAt, acceptedByPubkey, revokedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InvitationRow &&
          other.code == this.code &&
          other.vaultId == this.vaultId &&
          other.stewardId == this.stewardId &&
          other.payload == this.payload &&
          other.createdAt == this.createdAt &&
          other.expiresAt == this.expiresAt &&
          other.acceptedAt == this.acceptedAt &&
          other.acceptedByPubkey == this.acceptedByPubkey &&
          other.revokedAt == this.revokedAt);
}

class InvitationsCompanion extends UpdateCompanion<InvitationRow> {
  final Value<String> code;
  final Value<String> vaultId;
  final Value<String?> stewardId;
  final Value<String> payload;
  final Value<int> createdAt;
  final Value<int?> expiresAt;
  final Value<int?> acceptedAt;
  final Value<String?> acceptedByPubkey;
  final Value<int?> revokedAt;
  final Value<int> rowid;
  const InvitationsCompanion({
    this.code = const Value.absent(),
    this.vaultId = const Value.absent(),
    this.stewardId = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.acceptedAt = const Value.absent(),
    this.acceptedByPubkey = const Value.absent(),
    this.revokedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InvitationsCompanion.insert({
    required String code,
    required String vaultId,
    this.stewardId = const Value.absent(),
    required String payload,
    required int createdAt,
    this.expiresAt = const Value.absent(),
    this.acceptedAt = const Value.absent(),
    this.acceptedByPubkey = const Value.absent(),
    this.revokedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : code = Value(code),
        vaultId = Value(vaultId),
        payload = Value(payload),
        createdAt = Value(createdAt);
  static Insertable<InvitationRow> custom({
    Expression<String>? code,
    Expression<String>? vaultId,
    Expression<String>? stewardId,
    Expression<String>? payload,
    Expression<int>? createdAt,
    Expression<int>? expiresAt,
    Expression<int>? acceptedAt,
    Expression<String>? acceptedByPubkey,
    Expression<int>? revokedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (code != null) 'code': code,
      if (vaultId != null) 'vault_id': vaultId,
      if (stewardId != null) 'steward_id': stewardId,
      if (payload != null) 'payload': payload,
      if (createdAt != null) 'created_at': createdAt,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (acceptedAt != null) 'accepted_at': acceptedAt,
      if (acceptedByPubkey != null) 'accepted_by_pubkey': acceptedByPubkey,
      if (revokedAt != null) 'revoked_at': revokedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InvitationsCompanion copyWith(
      {Value<String>? code,
      Value<String>? vaultId,
      Value<String?>? stewardId,
      Value<String>? payload,
      Value<int>? createdAt,
      Value<int?>? expiresAt,
      Value<int?>? acceptedAt,
      Value<String?>? acceptedByPubkey,
      Value<int?>? revokedAt,
      Value<int>? rowid}) {
    return InvitationsCompanion(
      code: code ?? this.code,
      vaultId: vaultId ?? this.vaultId,
      stewardId: stewardId ?? this.stewardId,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      acceptedByPubkey: acceptedByPubkey ?? this.acceptedByPubkey,
      revokedAt: revokedAt ?? this.revokedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (vaultId.present) {
      map['vault_id'] = Variable<String>(vaultId.value);
    }
    if (stewardId.present) {
      map['steward_id'] = Variable<String>(stewardId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<int>(expiresAt.value);
    }
    if (acceptedAt.present) {
      map['accepted_at'] = Variable<int>(acceptedAt.value);
    }
    if (acceptedByPubkey.present) {
      map['accepted_by_pubkey'] = Variable<String>(acceptedByPubkey.value);
    }
    if (revokedAt.present) {
      map['revoked_at'] = Variable<int>(revokedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InvitationsCompanion(')
          ..write('code: $code, ')
          ..write('vaultId: $vaultId, ')
          ..write('stewardId: $stewardId, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('acceptedAt: $acceptedAt, ')
          ..write('acceptedByPubkey: $acceptedByPubkey, ')
          ..write('revokedAt: $revokedAt, ')
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
  late final GeneratedColumn<String> id = GeneratedColumn<String>('id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _vaultIdMeta = const VerificationMeta('vaultId');
  @override
  late final GeneratedColumn<String> vaultId = GeneratedColumn<String>(
      'vault_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES vaults (id) ON DELETE CASCADE'));
  static const VerificationMeta _versionMeta = const VerificationMeta('version');
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>('version', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>('created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _completedAtMeta = const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<int> completedAt = GeneratedColumn<int>(
      'completed_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _contentHmacMeta = const VerificationMeta('contentHmac');
  @override
  late final GeneratedColumn<Uint8List> contentHmac = GeneratedColumn<Uint8List>(
      'content_hmac', aliasedName, false,
      type: DriftSqlType.blob, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, vaultId, version, createdAt, completedAt, contentHmac];
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
      context.handle(_vaultIdMeta, vaultId.isAcceptableOrUnknown(data['vault_id']!, _vaultIdMeta));
    } else if (isInserting) {
      context.missing(_vaultIdMeta);
    }
    if (data.containsKey('version')) {
      context.handle(_versionMeta, version.isAcceptableOrUnknown(data['version']!, _versionMeta));
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
          _createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(_completedAtMeta,
          completedAt.isAcceptableOrUnknown(data['completed_at']!, _completedAtMeta));
    }
    if (data.containsKey('content_hmac')) {
      context.handle(_contentHmacMeta,
          contentHmac.isAcceptableOrUnknown(data['content_hmac']!, _contentHmacMeta));
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
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      vaultId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}vault_id'])!,
      version:
          attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}version'])!,
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
      completedAt: completedAt == null && nullToAbsent ? const Value.absent() : Value(completedAt),
      contentHmac: Value(contentHmac),
    );
  }

  factory DistributionRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
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
      completedAt: data.completedAt.present ? data.completedAt.value : this.completedAt,
      contentHmac: data.contentHmac.present ? data.contentHmac.value : this.contentHmac,
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
  int get hashCode => Object.hash(
      id, vaultId, version, createdAt, completedAt, $driftBlobEquality.hash(contentHmac));
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
  late final GeneratedColumn<String> id = GeneratedColumn<String>('id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _distributionIdMeta = const VerificationMeta('distributionId');
  @override
  late final GeneratedColumn<String> distributionId = GeneratedColumn<String>(
      'distribution_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES distributions (id) ON DELETE CASCADE'));
  static const VerificationMeta _stewardIdMeta = const VerificationMeta('stewardId');
  @override
  late final GeneratedColumn<String> stewardId = GeneratedColumn<String>(
      'steward_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES stewards (id) ON DELETE RESTRICT'));
  static const VerificationMeta _giftWrapEventIdMeta = const VerificationMeta('giftWrapEventId');
  @override
  late final GeneratedColumn<String> giftWrapEventId = GeneratedColumn<String>(
      'gift_wrap_event_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sentAtMeta = const VerificationMeta('sentAt');
  @override
  late final GeneratedColumn<int> sentAt = GeneratedColumn<int>('sent_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _acknowledgedAtMeta = const VerificationMeta('acknowledgedAt');
  @override
  late final GeneratedColumn<int> acknowledgedAt = GeneratedColumn<int>(
      'acknowledged_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _acknowledgmentEventIdMeta =
      const VerificationMeta('acknowledgmentEventId');
  @override
  late final GeneratedColumn<String> acknowledgmentEventId = GeneratedColumn<String>(
      'acknowledgment_event_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _acknowledgmentDistributionVersionMeta =
      const VerificationMeta('acknowledgmentDistributionVersion');
  @override
  late final GeneratedColumn<int> acknowledgmentDistributionVersion = GeneratedColumn<int>(
      'acknowledgment_distribution_version', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _acknowledgmentCreatedAtMeta =
      const VerificationMeta('acknowledgmentCreatedAt');
  @override
  late final GeneratedColumn<int> acknowledgmentCreatedAt = GeneratedColumn<int>(
      'acknowledgment_created_at', aliasedName, true,
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
  VerificationContext validateIntegrity(Insertable<DistributionShareRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('distribution_id')) {
      context.handle(_distributionIdMeta,
          distributionId.isAcceptableOrUnknown(data['distribution_id']!, _distributionIdMeta));
    } else if (isInserting) {
      context.missing(_distributionIdMeta);
    }
    if (data.containsKey('steward_id')) {
      context.handle(
          _stewardIdMeta, stewardId.isAcceptableOrUnknown(data['steward_id']!, _stewardIdMeta));
    } else if (isInserting) {
      context.missing(_stewardIdMeta);
    }
    if (data.containsKey('gift_wrap_event_id')) {
      context.handle(_giftWrapEventIdMeta,
          giftWrapEventId.isAcceptableOrUnknown(data['gift_wrap_event_id']!, _giftWrapEventIdMeta));
    } else if (isInserting) {
      context.missing(_giftWrapEventIdMeta);
    }
    if (data.containsKey('sent_at')) {
      context.handle(_sentAtMeta, sentAt.isAcceptableOrUnknown(data['sent_at']!, _sentAtMeta));
    }
    if (data.containsKey('acknowledged_at')) {
      context.handle(_acknowledgedAtMeta,
          acknowledgedAt.isAcceptableOrUnknown(data['acknowledged_at']!, _acknowledgedAtMeta));
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
              data['acknowledgment_created_at']!, _acknowledgmentCreatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DistributionShareRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DistributionShareRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      distributionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}distribution_id'])!,
      stewardId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}steward_id'])!,
      giftWrapEventId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}gift_wrap_event_id'])!,
      sentAt:
          attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}sent_at']),
      acknowledgedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}acknowledged_at']),
      acknowledgmentEventId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}acknowledgment_event_id']),
      acknowledgmentDistributionVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}acknowledgment_distribution_version']),
      acknowledgmentCreatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}acknowledgment_created_at']),
    );
  }

  @override
  $DistributionSharesTable createAlias(String alias) {
    return $DistributionSharesTable(attachedDatabase, alias);
  }
}

class DistributionShareRow extends DataClass implements Insertable<DistributionShareRow> {
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
      map['acknowledgment_distribution_version'] = Variable<int>(acknowledgmentDistributionVersion);
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
      sentAt: sentAt == null && nullToAbsent ? const Value.absent() : Value(sentAt),
      acknowledgedAt:
          acknowledgedAt == null && nullToAbsent ? const Value.absent() : Value(acknowledgedAt),
      acknowledgmentEventId: acknowledgmentEventId == null && nullToAbsent
          ? const Value.absent()
          : Value(acknowledgmentEventId),
      acknowledgmentDistributionVersion: acknowledgmentDistributionVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(acknowledgmentDistributionVersion),
      acknowledgmentCreatedAt: acknowledgmentCreatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(acknowledgmentCreatedAt),
    );
  }

  factory DistributionShareRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DistributionShareRow(
      id: serializer.fromJson<String>(json['id']),
      distributionId: serializer.fromJson<String>(json['distributionId']),
      stewardId: serializer.fromJson<String>(json['stewardId']),
      giftWrapEventId: serializer.fromJson<String>(json['giftWrapEventId']),
      sentAt: serializer.fromJson<int?>(json['sentAt']),
      acknowledgedAt: serializer.fromJson<int?>(json['acknowledgedAt']),
      acknowledgmentEventId: serializer.fromJson<String?>(json['acknowledgmentEventId']),
      acknowledgmentDistributionVersion:
          serializer.fromJson<int?>(json['acknowledgmentDistributionVersion']),
      acknowledgmentCreatedAt: serializer.fromJson<int?>(json['acknowledgmentCreatedAt']),
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
      'acknowledgmentEventId': serializer.toJson<String?>(acknowledgmentEventId),
      'acknowledgmentDistributionVersion':
          serializer.toJson<int?>(acknowledgmentDistributionVersion),
      'acknowledgmentCreatedAt': serializer.toJson<int?>(acknowledgmentCreatedAt),
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
        acknowledgedAt: acknowledgedAt.present ? acknowledgedAt.value : this.acknowledgedAt,
        acknowledgmentEventId: acknowledgmentEventId.present
            ? acknowledgmentEventId.value
            : this.acknowledgmentEventId,
        acknowledgmentDistributionVersion: acknowledgmentDistributionVersion.present
            ? acknowledgmentDistributionVersion.value
            : this.acknowledgmentDistributionVersion,
        acknowledgmentCreatedAt: acknowledgmentCreatedAt.present
            ? acknowledgmentCreatedAt.value
            : this.acknowledgmentCreatedAt,
      );
  DistributionShareRow copyWithCompanion(DistributionSharesCompanion data) {
    return DistributionShareRow(
      id: data.id.present ? data.id.value : this.id,
      distributionId: data.distributionId.present ? data.distributionId.value : this.distributionId,
      stewardId: data.stewardId.present ? data.stewardId.value : this.stewardId,
      giftWrapEventId:
          data.giftWrapEventId.present ? data.giftWrapEventId.value : this.giftWrapEventId,
      sentAt: data.sentAt.present ? data.sentAt.value : this.sentAt,
      acknowledgedAt: data.acknowledgedAt.present ? data.acknowledgedAt.value : this.acknowledgedAt,
      acknowledgmentEventId: data.acknowledgmentEventId.present
          ? data.acknowledgmentEventId.value
          : this.acknowledgmentEventId,
      acknowledgmentDistributionVersion: data.acknowledgmentDistributionVersion.present
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
          ..write('acknowledgmentDistributionVersion: $acknowledgmentDistributionVersion, ')
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
          other.acknowledgmentDistributionVersion == this.acknowledgmentDistributionVersion &&
          other.acknowledgmentCreatedAt == this.acknowledgmentCreatedAt);
}

class DistributionSharesCompanion extends UpdateCompanion<DistributionShareRow> {
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
      if (acknowledgmentEventId != null) 'acknowledgment_event_id': acknowledgmentEventId,
      if (acknowledgmentDistributionVersion != null)
        'acknowledgment_distribution_version': acknowledgmentDistributionVersion,
      if (acknowledgmentCreatedAt != null) 'acknowledgment_created_at': acknowledgmentCreatedAt,
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
      acknowledgmentEventId: acknowledgmentEventId ?? this.acknowledgmentEventId,
      acknowledgmentDistributionVersion:
          acknowledgmentDistributionVersion ?? this.acknowledgmentDistributionVersion,
      acknowledgmentCreatedAt: acknowledgmentCreatedAt ?? this.acknowledgmentCreatedAt,
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
      map['acknowledgment_event_id'] = Variable<String>(acknowledgmentEventId.value);
    }
    if (acknowledgmentDistributionVersion.present) {
      map['acknowledgment_distribution_version'] =
          Variable<int>(acknowledgmentDistributionVersion.value);
    }
    if (acknowledgmentCreatedAt.present) {
      map['acknowledgment_created_at'] = Variable<int>(acknowledgmentCreatedAt.value);
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
          ..write('acknowledgmentDistributionVersion: $acknowledgmentDistributionVersion, ')
          ..write('acknowledgmentCreatedAt: $acknowledgmentCreatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HeldSharesTable extends HeldShares with TableInfo<$HeldSharesTable, HeldShareRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HeldSharesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>('id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _vaultIdMeta = const VerificationMeta('vaultId');
  @override
  late final GeneratedColumn<String> vaultId = GeneratedColumn<String>(
      'vault_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES vaults (id) ON DELETE CASCADE'));
  static const VerificationMeta _shareIndexMeta = const VerificationMeta('shareIndex');
  @override
  late final GeneratedColumn<int> shareIndex = GeneratedColumn<int>(
      'share_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _sharePayloadMeta = const VerificationMeta('sharePayload');
  @override
  late final GeneratedColumn<String> sharePayload = GeneratedColumn<String>(
      'share_payload', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _distributionVersionMeta =
      const VerificationMeta('distributionVersion');
  @override
  late final GeneratedColumn<int> distributionVersion = GeneratedColumn<int>(
      'distribution_version', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _receivedAtMeta = const VerificationMeta('receivedAt');
  @override
  late final GeneratedColumn<int> receivedAt = GeneratedColumn<int>(
      'received_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _nostrEventIdMeta = const VerificationMeta('nostrEventId');
  @override
  late final GeneratedColumn<String> nostrEventId = GeneratedColumn<String>(
      'nostr_event_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastSeenRelayMeta = const VerificationMeta('lastSeenRelay');
  @override
  late final GeneratedColumn<String> lastSeenRelay = GeneratedColumn<String>(
      'last_seen_relay', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _pushEnabledMeta = const VerificationMeta('pushEnabled');
  @override
  late final GeneratedColumn<bool> pushEnabled = GeneratedColumn<bool>(
      'push_enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("push_enabled" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        vaultId,
        shareIndex,
        sharePayload,
        distributionVersion,
        receivedAt,
        nostrEventId,
        lastSeenRelay,
        pushEnabled
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'held_shares';
  @override
  VerificationContext validateIntegrity(Insertable<HeldShareRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('vault_id')) {
      context.handle(_vaultIdMeta, vaultId.isAcceptableOrUnknown(data['vault_id']!, _vaultIdMeta));
    } else if (isInserting) {
      context.missing(_vaultIdMeta);
    }
    if (data.containsKey('share_index')) {
      context.handle(
          _shareIndexMeta, shareIndex.isAcceptableOrUnknown(data['share_index']!, _shareIndexMeta));
    } else if (isInserting) {
      context.missing(_shareIndexMeta);
    }
    if (data.containsKey('share_payload')) {
      context.handle(_sharePayloadMeta,
          sharePayload.isAcceptableOrUnknown(data['share_payload']!, _sharePayloadMeta));
    } else if (isInserting) {
      context.missing(_sharePayloadMeta);
    }
    if (data.containsKey('distribution_version')) {
      context.handle(
          _distributionVersionMeta,
          distributionVersion.isAcceptableOrUnknown(
              data['distribution_version']!, _distributionVersionMeta));
    } else if (isInserting) {
      context.missing(_distributionVersionMeta);
    }
    if (data.containsKey('received_at')) {
      context.handle(
          _receivedAtMeta, receivedAt.isAcceptableOrUnknown(data['received_at']!, _receivedAtMeta));
    } else if (isInserting) {
      context.missing(_receivedAtMeta);
    }
    if (data.containsKey('nostr_event_id')) {
      context.handle(_nostrEventIdMeta,
          nostrEventId.isAcceptableOrUnknown(data['nostr_event_id']!, _nostrEventIdMeta));
    }
    if (data.containsKey('last_seen_relay')) {
      context.handle(_lastSeenRelayMeta,
          lastSeenRelay.isAcceptableOrUnknown(data['last_seen_relay']!, _lastSeenRelayMeta));
    }
    if (data.containsKey('push_enabled')) {
      context.handle(_pushEnabledMeta,
          pushEnabled.isAcceptableOrUnknown(data['push_enabled']!, _pushEnabledMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HeldShareRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HeldShareRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      vaultId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}vault_id'])!,
      shareIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}share_index'])!,
      sharePayload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}share_payload'])!,
      distributionVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}distribution_version'])!,
      receivedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}received_at'])!,
      nostrEventId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}nostr_event_id']),
      lastSeenRelay: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_seen_relay']),
      pushEnabled: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}push_enabled'])!,
    );
  }

  @override
  $HeldSharesTable createAlias(String alias) {
    return $HeldSharesTable(attachedDatabase, alias);
  }
}

class HeldShareRow extends DataClass implements Insertable<HeldShareRow> {
  final String id;
  final String vaultId;

  /// 0-based Shamir share position (matches [Share.shareIndex] and wire
  /// `shard_index`).
  final int shareIndex;

  /// Raw Shamir share bytes. Application-layer plaintext protected by
  /// SQLCipher whole-DB encryption. See "Share material lifecycle" in the
  /// data layer refactor plan.
  final String sharePayload;

  /// Distribution version at which this share was generated. Used for
  /// retention pruning and for serving a specific version during recovery.
  final int distributionVersion;

  /// Local clock timestamp (ms since epoch) when this row was first written.
  /// Never sourced from the Nostr event `created_at` — see "Time,
  /// monotonicity, clock skew" in the refactor plan.
  final int receivedAt;

  /// Nostr event ID of the gift-wrap that delivered this share. Used for
  /// dedup (see unique index `held_shares_vault_version_event`).
  final String? nostrEventId;

  /// Relay URL this share was first ingested from. Lets the steward publish
  /// an ack to a sensible relay without re-guessing.
  final String? lastSeenRelay;

  /// Mirrors the owner's push preference at distribution time. Combined with
  /// `vaults.push_enabled` to determine whether to fire local push
  /// notifications for this vault.
  final bool pushEnabled;
  const HeldShareRow(
      {required this.id,
      required this.vaultId,
      required this.shareIndex,
      required this.sharePayload,
      required this.distributionVersion,
      required this.receivedAt,
      this.nostrEventId,
      this.lastSeenRelay,
      required this.pushEnabled});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['vault_id'] = Variable<String>(vaultId);
    map['share_index'] = Variable<int>(shareIndex);
    map['share_payload'] = Variable<String>(sharePayload);
    map['distribution_version'] = Variable<int>(distributionVersion);
    map['received_at'] = Variable<int>(receivedAt);
    if (!nullToAbsent || nostrEventId != null) {
      map['nostr_event_id'] = Variable<String>(nostrEventId);
    }
    if (!nullToAbsent || lastSeenRelay != null) {
      map['last_seen_relay'] = Variable<String>(lastSeenRelay);
    }
    map['push_enabled'] = Variable<bool>(pushEnabled);
    return map;
  }

  HeldSharesCompanion toCompanion(bool nullToAbsent) {
    return HeldSharesCompanion(
      id: Value(id),
      vaultId: Value(vaultId),
      shareIndex: Value(shareIndex),
      sharePayload: Value(sharePayload),
      distributionVersion: Value(distributionVersion),
      receivedAt: Value(receivedAt),
      nostrEventId:
          nostrEventId == null && nullToAbsent ? const Value.absent() : Value(nostrEventId),
      lastSeenRelay:
          lastSeenRelay == null && nullToAbsent ? const Value.absent() : Value(lastSeenRelay),
      pushEnabled: Value(pushEnabled),
    );
  }

  factory HeldShareRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HeldShareRow(
      id: serializer.fromJson<String>(json['id']),
      vaultId: serializer.fromJson<String>(json['vaultId']),
      shareIndex: serializer.fromJson<int>(json['shareIndex']),
      sharePayload: serializer.fromJson<String>(json['sharePayload']),
      distributionVersion: serializer.fromJson<int>(json['distributionVersion']),
      receivedAt: serializer.fromJson<int>(json['receivedAt']),
      nostrEventId: serializer.fromJson<String?>(json['nostrEventId']),
      lastSeenRelay: serializer.fromJson<String?>(json['lastSeenRelay']),
      pushEnabled: serializer.fromJson<bool>(json['pushEnabled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'vaultId': serializer.toJson<String>(vaultId),
      'shareIndex': serializer.toJson<int>(shareIndex),
      'sharePayload': serializer.toJson<String>(sharePayload),
      'distributionVersion': serializer.toJson<int>(distributionVersion),
      'receivedAt': serializer.toJson<int>(receivedAt),
      'nostrEventId': serializer.toJson<String?>(nostrEventId),
      'lastSeenRelay': serializer.toJson<String?>(lastSeenRelay),
      'pushEnabled': serializer.toJson<bool>(pushEnabled),
    };
  }

  HeldShareRow copyWith(
          {String? id,
          String? vaultId,
          int? shareIndex,
          String? sharePayload,
          int? distributionVersion,
          int? receivedAt,
          Value<String?> nostrEventId = const Value.absent(),
          Value<String?> lastSeenRelay = const Value.absent(),
          bool? pushEnabled}) =>
      HeldShareRow(
        id: id ?? this.id,
        vaultId: vaultId ?? this.vaultId,
        shareIndex: shareIndex ?? this.shareIndex,
        sharePayload: sharePayload ?? this.sharePayload,
        distributionVersion: distributionVersion ?? this.distributionVersion,
        receivedAt: receivedAt ?? this.receivedAt,
        nostrEventId: nostrEventId.present ? nostrEventId.value : this.nostrEventId,
        lastSeenRelay: lastSeenRelay.present ? lastSeenRelay.value : this.lastSeenRelay,
        pushEnabled: pushEnabled ?? this.pushEnabled,
      );
  HeldShareRow copyWithCompanion(HeldSharesCompanion data) {
    return HeldShareRow(
      id: data.id.present ? data.id.value : this.id,
      vaultId: data.vaultId.present ? data.vaultId.value : this.vaultId,
      shareIndex: data.shareIndex.present ? data.shareIndex.value : this.shareIndex,
      sharePayload: data.sharePayload.present ? data.sharePayload.value : this.sharePayload,
      distributionVersion: data.distributionVersion.present
          ? data.distributionVersion.value
          : this.distributionVersion,
      receivedAt: data.receivedAt.present ? data.receivedAt.value : this.receivedAt,
      nostrEventId: data.nostrEventId.present ? data.nostrEventId.value : this.nostrEventId,
      lastSeenRelay: data.lastSeenRelay.present ? data.lastSeenRelay.value : this.lastSeenRelay,
      pushEnabled: data.pushEnabled.present ? data.pushEnabled.value : this.pushEnabled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HeldShareRow(')
          ..write('id: $id, ')
          ..write('vaultId: $vaultId, ')
          ..write('shareIndex: $shareIndex, ')
          ..write('sharePayload: $sharePayload, ')
          ..write('distributionVersion: $distributionVersion, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('nostrEventId: $nostrEventId, ')
          ..write('lastSeenRelay: $lastSeenRelay, ')
          ..write('pushEnabled: $pushEnabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, vaultId, shareIndex, sharePayload, distributionVersion,
      receivedAt, nostrEventId, lastSeenRelay, pushEnabled);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HeldShareRow &&
          other.id == this.id &&
          other.vaultId == this.vaultId &&
          other.shareIndex == this.shareIndex &&
          other.sharePayload == this.sharePayload &&
          other.distributionVersion == this.distributionVersion &&
          other.receivedAt == this.receivedAt &&
          other.nostrEventId == this.nostrEventId &&
          other.lastSeenRelay == this.lastSeenRelay &&
          other.pushEnabled == this.pushEnabled);
}

class HeldSharesCompanion extends UpdateCompanion<HeldShareRow> {
  final Value<String> id;
  final Value<String> vaultId;
  final Value<int> shareIndex;
  final Value<String> sharePayload;
  final Value<int> distributionVersion;
  final Value<int> receivedAt;
  final Value<String?> nostrEventId;
  final Value<String?> lastSeenRelay;
  final Value<bool> pushEnabled;
  final Value<int> rowid;
  const HeldSharesCompanion({
    this.id = const Value.absent(),
    this.vaultId = const Value.absent(),
    this.shareIndex = const Value.absent(),
    this.sharePayload = const Value.absent(),
    this.distributionVersion = const Value.absent(),
    this.receivedAt = const Value.absent(),
    this.nostrEventId = const Value.absent(),
    this.lastSeenRelay = const Value.absent(),
    this.pushEnabled = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HeldSharesCompanion.insert({
    required String id,
    required String vaultId,
    required int shareIndex,
    required String sharePayload,
    required int distributionVersion,
    required int receivedAt,
    this.nostrEventId = const Value.absent(),
    this.lastSeenRelay = const Value.absent(),
    this.pushEnabled = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        vaultId = Value(vaultId),
        shareIndex = Value(shareIndex),
        sharePayload = Value(sharePayload),
        distributionVersion = Value(distributionVersion),
        receivedAt = Value(receivedAt);
  static Insertable<HeldShareRow> custom({
    Expression<String>? id,
    Expression<String>? vaultId,
    Expression<int>? shareIndex,
    Expression<String>? sharePayload,
    Expression<int>? distributionVersion,
    Expression<int>? receivedAt,
    Expression<String>? nostrEventId,
    Expression<String>? lastSeenRelay,
    Expression<bool>? pushEnabled,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (vaultId != null) 'vault_id': vaultId,
      if (shareIndex != null) 'share_index': shareIndex,
      if (sharePayload != null) 'share_payload': sharePayload,
      if (distributionVersion != null) 'distribution_version': distributionVersion,
      if (receivedAt != null) 'received_at': receivedAt,
      if (nostrEventId != null) 'nostr_event_id': nostrEventId,
      if (lastSeenRelay != null) 'last_seen_relay': lastSeenRelay,
      if (pushEnabled != null) 'push_enabled': pushEnabled,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HeldSharesCompanion copyWith(
      {Value<String>? id,
      Value<String>? vaultId,
      Value<int>? shareIndex,
      Value<String>? sharePayload,
      Value<int>? distributionVersion,
      Value<int>? receivedAt,
      Value<String?>? nostrEventId,
      Value<String?>? lastSeenRelay,
      Value<bool>? pushEnabled,
      Value<int>? rowid}) {
    return HeldSharesCompanion(
      id: id ?? this.id,
      vaultId: vaultId ?? this.vaultId,
      shareIndex: shareIndex ?? this.shareIndex,
      sharePayload: sharePayload ?? this.sharePayload,
      distributionVersion: distributionVersion ?? this.distributionVersion,
      receivedAt: receivedAt ?? this.receivedAt,
      nostrEventId: nostrEventId ?? this.nostrEventId,
      lastSeenRelay: lastSeenRelay ?? this.lastSeenRelay,
      pushEnabled: pushEnabled ?? this.pushEnabled,
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
    if (sharePayload.present) {
      map['share_payload'] = Variable<String>(sharePayload.value);
    }
    if (distributionVersion.present) {
      map['distribution_version'] = Variable<int>(distributionVersion.value);
    }
    if (receivedAt.present) {
      map['received_at'] = Variable<int>(receivedAt.value);
    }
    if (nostrEventId.present) {
      map['nostr_event_id'] = Variable<String>(nostrEventId.value);
    }
    if (lastSeenRelay.present) {
      map['last_seen_relay'] = Variable<String>(lastSeenRelay.value);
    }
    if (pushEnabled.present) {
      map['push_enabled'] = Variable<bool>(pushEnabled.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HeldSharesCompanion(')
          ..write('id: $id, ')
          ..write('vaultId: $vaultId, ')
          ..write('shareIndex: $shareIndex, ')
          ..write('sharePayload: $sharePayload, ')
          ..write('distributionVersion: $distributionVersion, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('nostrEventId: $nostrEventId, ')
          ..write('lastSeenRelay: $lastSeenRelay, ')
          ..write('pushEnabled: $pushEnabled, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecoveryRequestsTable extends RecoveryRequests
    with TableInfo<$RecoveryRequestsTable, RecoveryRequestRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecoveryRequestsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>('id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _vaultIdMeta = const VerificationMeta('vaultId');
  @override
  late final GeneratedColumn<String> vaultId = GeneratedColumn<String>(
      'vault_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES vaults (id) ON DELETE CASCADE'));
  static const VerificationMeta _requestEventIdMeta = const VerificationMeta('requestEventId');
  @override
  late final GeneratedColumn<String> requestEventId = GeneratedColumn<String>(
      'request_event_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _initiatorPubkeyMeta = const VerificationMeta('initiatorPubkey');
  @override
  late final GeneratedColumn<String> initiatorPubkey = GeneratedColumn<String>(
      'initiator_pubkey', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _startedAtMeta = const VerificationMeta('startedAt');
  @override
  late final GeneratedColumn<int> startedAt = GeneratedColumn<int>('started_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _expiresAtMeta = const VerificationMeta('expiresAt');
  @override
  late final GeneratedColumn<int> expiresAt = GeneratedColumn<int>('expires_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _cancelledAtMeta = const VerificationMeta('cancelledAt');
  @override
  late final GeneratedColumn<int> cancelledAt = GeneratedColumn<int>(
      'cancelled_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _completedAtMeta = const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<int> completedAt = GeneratedColumn<int>(
      'completed_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _distributionVersionAtStartMeta =
      const VerificationMeta('distributionVersionAtStart');
  @override
  late final GeneratedColumn<int> distributionVersionAtStart = GeneratedColumn<int>(
      'distribution_version_at_start', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _thresholdAtStartMeta = const VerificationMeta('thresholdAtStart');
  @override
  late final GeneratedColumn<int> thresholdAtStart = GeneratedColumn<int>(
      'threshold_at_start', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>('status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isPracticeMeta = const VerificationMeta('isPractice');
  @override
  late final GeneratedColumn<bool> isPractice = GeneratedColumn<bool>(
      'is_practice', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("is_practice" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _errorMessageMeta = const VerificationMeta('errorMessage');
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
      'error_message', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _eventCreationTimeMsMeta =
      const VerificationMeta('eventCreationTimeMs');
  @override
  late final GeneratedColumn<int> eventCreationTimeMs = GeneratedColumn<int>(
      'event_creation_time_ms', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        vaultId,
        requestEventId,
        initiatorPubkey,
        startedAt,
        expiresAt,
        cancelledAt,
        completedAt,
        distributionVersionAtStart,
        thresholdAtStart,
        status,
        isPractice,
        errorMessage,
        eventCreationTimeMs
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recovery_requests';
  @override
  VerificationContext validateIntegrity(Insertable<RecoveryRequestRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('vault_id')) {
      context.handle(_vaultIdMeta, vaultId.isAcceptableOrUnknown(data['vault_id']!, _vaultIdMeta));
    } else if (isInserting) {
      context.missing(_vaultIdMeta);
    }
    if (data.containsKey('request_event_id')) {
      context.handle(_requestEventIdMeta,
          requestEventId.isAcceptableOrUnknown(data['request_event_id']!, _requestEventIdMeta));
    }
    if (data.containsKey('initiator_pubkey')) {
      context.handle(_initiatorPubkeyMeta,
          initiatorPubkey.isAcceptableOrUnknown(data['initiator_pubkey']!, _initiatorPubkeyMeta));
    } else if (isInserting) {
      context.missing(_initiatorPubkeyMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
          _startedAtMeta, startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta));
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('expires_at')) {
      context.handle(
          _expiresAtMeta, expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta));
    }
    if (data.containsKey('cancelled_at')) {
      context.handle(_cancelledAtMeta,
          cancelledAt.isAcceptableOrUnknown(data['cancelled_at']!, _cancelledAtMeta));
    }
    if (data.containsKey('completed_at')) {
      context.handle(_completedAtMeta,
          completedAt.isAcceptableOrUnknown(data['completed_at']!, _completedAtMeta));
    }
    if (data.containsKey('distribution_version_at_start')) {
      context.handle(
          _distributionVersionAtStartMeta,
          distributionVersionAtStart.isAcceptableOrUnknown(
              data['distribution_version_at_start']!, _distributionVersionAtStartMeta));
    } else if (isInserting) {
      context.missing(_distributionVersionAtStartMeta);
    }
    if (data.containsKey('threshold_at_start')) {
      context.handle(
          _thresholdAtStartMeta,
          thresholdAtStart.isAcceptableOrUnknown(
              data['threshold_at_start']!, _thresholdAtStartMeta));
    } else if (isInserting) {
      context.missing(_thresholdAtStartMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta, status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('is_practice')) {
      context.handle(
          _isPracticeMeta, isPractice.isAcceptableOrUnknown(data['is_practice']!, _isPracticeMeta));
    }
    if (data.containsKey('error_message')) {
      context.handle(_errorMessageMeta,
          errorMessage.isAcceptableOrUnknown(data['error_message']!, _errorMessageMeta));
    }
    if (data.containsKey('event_creation_time_ms')) {
      context.handle(
          _eventCreationTimeMsMeta,
          eventCreationTimeMs.isAcceptableOrUnknown(
              data['event_creation_time_ms']!, _eventCreationTimeMsMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecoveryRequestRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecoveryRequestRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      vaultId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}vault_id'])!,
      requestEventId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}request_event_id']),
      initiatorPubkey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}initiator_pubkey'])!,
      startedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}started_at'])!,
      expiresAt:
          attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}expires_at']),
      cancelledAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}cancelled_at']),
      completedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}completed_at']),
      distributionVersionAtStart: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}distribution_version_at_start'])!,
      thresholdAtStart: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}threshold_at_start'])!,
      status:
          attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      isPractice: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_practice'])!,
      errorMessage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}error_message']),
      eventCreationTimeMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}event_creation_time_ms']),
    );
  }

  @override
  $RecoveryRequestsTable createAlias(String alias) {
    return $RecoveryRequestsTable(attachedDatabase, alias);
  }
}

class RecoveryRequestRow extends DataClass implements Insertable<RecoveryRequestRow> {
  final String id;
  final String vaultId;

  /// Nostr id of the inner recovery request rumor (nullable until sent).
  final String? requestEventId;
  final String initiatorPubkey;

  /// Local clock (ms since epoch) when the session started.
  final int startedAt;
  final int? expiresAt;
  final int? cancelledAt;
  final int? completedAt;
  final int distributionVersionAtStart;
  final int thresholdAtStart;

  /// [RecoveryRequestStatus.name]
  final String status;
  final bool isPractice;
  final String? errorMessage;

  /// Wire `created_at` of inner event (ms UTC) for notification policy only.
  final int? eventCreationTimeMs;
  const RecoveryRequestRow(
      {required this.id,
      required this.vaultId,
      this.requestEventId,
      required this.initiatorPubkey,
      required this.startedAt,
      this.expiresAt,
      this.cancelledAt,
      this.completedAt,
      required this.distributionVersionAtStart,
      required this.thresholdAtStart,
      required this.status,
      required this.isPractice,
      this.errorMessage,
      this.eventCreationTimeMs});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['vault_id'] = Variable<String>(vaultId);
    if (!nullToAbsent || requestEventId != null) {
      map['request_event_id'] = Variable<String>(requestEventId);
    }
    map['initiator_pubkey'] = Variable<String>(initiatorPubkey);
    map['started_at'] = Variable<int>(startedAt);
    if (!nullToAbsent || expiresAt != null) {
      map['expires_at'] = Variable<int>(expiresAt);
    }
    if (!nullToAbsent || cancelledAt != null) {
      map['cancelled_at'] = Variable<int>(cancelledAt);
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<int>(completedAt);
    }
    map['distribution_version_at_start'] = Variable<int>(distributionVersionAtStart);
    map['threshold_at_start'] = Variable<int>(thresholdAtStart);
    map['status'] = Variable<String>(status);
    map['is_practice'] = Variable<bool>(isPractice);
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    if (!nullToAbsent || eventCreationTimeMs != null) {
      map['event_creation_time_ms'] = Variable<int>(eventCreationTimeMs);
    }
    return map;
  }

  RecoveryRequestsCompanion toCompanion(bool nullToAbsent) {
    return RecoveryRequestsCompanion(
      id: Value(id),
      vaultId: Value(vaultId),
      requestEventId:
          requestEventId == null && nullToAbsent ? const Value.absent() : Value(requestEventId),
      initiatorPubkey: Value(initiatorPubkey),
      startedAt: Value(startedAt),
      expiresAt: expiresAt == null && nullToAbsent ? const Value.absent() : Value(expiresAt),
      cancelledAt: cancelledAt == null && nullToAbsent ? const Value.absent() : Value(cancelledAt),
      completedAt: completedAt == null && nullToAbsent ? const Value.absent() : Value(completedAt),
      distributionVersionAtStart: Value(distributionVersionAtStart),
      thresholdAtStart: Value(thresholdAtStart),
      status: Value(status),
      isPractice: Value(isPractice),
      errorMessage:
          errorMessage == null && nullToAbsent ? const Value.absent() : Value(errorMessage),
      eventCreationTimeMs: eventCreationTimeMs == null && nullToAbsent
          ? const Value.absent()
          : Value(eventCreationTimeMs),
    );
  }

  factory RecoveryRequestRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecoveryRequestRow(
      id: serializer.fromJson<String>(json['id']),
      vaultId: serializer.fromJson<String>(json['vaultId']),
      requestEventId: serializer.fromJson<String?>(json['requestEventId']),
      initiatorPubkey: serializer.fromJson<String>(json['initiatorPubkey']),
      startedAt: serializer.fromJson<int>(json['startedAt']),
      expiresAt: serializer.fromJson<int?>(json['expiresAt']),
      cancelledAt: serializer.fromJson<int?>(json['cancelledAt']),
      completedAt: serializer.fromJson<int?>(json['completedAt']),
      distributionVersionAtStart: serializer.fromJson<int>(json['distributionVersionAtStart']),
      thresholdAtStart: serializer.fromJson<int>(json['thresholdAtStart']),
      status: serializer.fromJson<String>(json['status']),
      isPractice: serializer.fromJson<bool>(json['isPractice']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      eventCreationTimeMs: serializer.fromJson<int?>(json['eventCreationTimeMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'vaultId': serializer.toJson<String>(vaultId),
      'requestEventId': serializer.toJson<String?>(requestEventId),
      'initiatorPubkey': serializer.toJson<String>(initiatorPubkey),
      'startedAt': serializer.toJson<int>(startedAt),
      'expiresAt': serializer.toJson<int?>(expiresAt),
      'cancelledAt': serializer.toJson<int?>(cancelledAt),
      'completedAt': serializer.toJson<int?>(completedAt),
      'distributionVersionAtStart': serializer.toJson<int>(distributionVersionAtStart),
      'thresholdAtStart': serializer.toJson<int>(thresholdAtStart),
      'status': serializer.toJson<String>(status),
      'isPractice': serializer.toJson<bool>(isPractice),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'eventCreationTimeMs': serializer.toJson<int?>(eventCreationTimeMs),
    };
  }

  RecoveryRequestRow copyWith(
          {String? id,
          String? vaultId,
          Value<String?> requestEventId = const Value.absent(),
          String? initiatorPubkey,
          int? startedAt,
          Value<int?> expiresAt = const Value.absent(),
          Value<int?> cancelledAt = const Value.absent(),
          Value<int?> completedAt = const Value.absent(),
          int? distributionVersionAtStart,
          int? thresholdAtStart,
          String? status,
          bool? isPractice,
          Value<String?> errorMessage = const Value.absent(),
          Value<int?> eventCreationTimeMs = const Value.absent()}) =>
      RecoveryRequestRow(
        id: id ?? this.id,
        vaultId: vaultId ?? this.vaultId,
        requestEventId: requestEventId.present ? requestEventId.value : this.requestEventId,
        initiatorPubkey: initiatorPubkey ?? this.initiatorPubkey,
        startedAt: startedAt ?? this.startedAt,
        expiresAt: expiresAt.present ? expiresAt.value : this.expiresAt,
        cancelledAt: cancelledAt.present ? cancelledAt.value : this.cancelledAt,
        completedAt: completedAt.present ? completedAt.value : this.completedAt,
        distributionVersionAtStart: distributionVersionAtStart ?? this.distributionVersionAtStart,
        thresholdAtStart: thresholdAtStart ?? this.thresholdAtStart,
        status: status ?? this.status,
        isPractice: isPractice ?? this.isPractice,
        errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
        eventCreationTimeMs:
            eventCreationTimeMs.present ? eventCreationTimeMs.value : this.eventCreationTimeMs,
      );
  RecoveryRequestRow copyWithCompanion(RecoveryRequestsCompanion data) {
    return RecoveryRequestRow(
      id: data.id.present ? data.id.value : this.id,
      vaultId: data.vaultId.present ? data.vaultId.value : this.vaultId,
      requestEventId: data.requestEventId.present ? data.requestEventId.value : this.requestEventId,
      initiatorPubkey:
          data.initiatorPubkey.present ? data.initiatorPubkey.value : this.initiatorPubkey,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      cancelledAt: data.cancelledAt.present ? data.cancelledAt.value : this.cancelledAt,
      completedAt: data.completedAt.present ? data.completedAt.value : this.completedAt,
      distributionVersionAtStart: data.distributionVersionAtStart.present
          ? data.distributionVersionAtStart.value
          : this.distributionVersionAtStart,
      thresholdAtStart:
          data.thresholdAtStart.present ? data.thresholdAtStart.value : this.thresholdAtStart,
      status: data.status.present ? data.status.value : this.status,
      isPractice: data.isPractice.present ? data.isPractice.value : this.isPractice,
      errorMessage: data.errorMessage.present ? data.errorMessage.value : this.errorMessage,
      eventCreationTimeMs: data.eventCreationTimeMs.present
          ? data.eventCreationTimeMs.value
          : this.eventCreationTimeMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecoveryRequestRow(')
          ..write('id: $id, ')
          ..write('vaultId: $vaultId, ')
          ..write('requestEventId: $requestEventId, ')
          ..write('initiatorPubkey: $initiatorPubkey, ')
          ..write('startedAt: $startedAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('cancelledAt: $cancelledAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('distributionVersionAtStart: $distributionVersionAtStart, ')
          ..write('thresholdAtStart: $thresholdAtStart, ')
          ..write('status: $status, ')
          ..write('isPractice: $isPractice, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('eventCreationTimeMs: $eventCreationTimeMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      vaultId,
      requestEventId,
      initiatorPubkey,
      startedAt,
      expiresAt,
      cancelledAt,
      completedAt,
      distributionVersionAtStart,
      thresholdAtStart,
      status,
      isPractice,
      errorMessage,
      eventCreationTimeMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecoveryRequestRow &&
          other.id == this.id &&
          other.vaultId == this.vaultId &&
          other.requestEventId == this.requestEventId &&
          other.initiatorPubkey == this.initiatorPubkey &&
          other.startedAt == this.startedAt &&
          other.expiresAt == this.expiresAt &&
          other.cancelledAt == this.cancelledAt &&
          other.completedAt == this.completedAt &&
          other.distributionVersionAtStart == this.distributionVersionAtStart &&
          other.thresholdAtStart == this.thresholdAtStart &&
          other.status == this.status &&
          other.isPractice == this.isPractice &&
          other.errorMessage == this.errorMessage &&
          other.eventCreationTimeMs == this.eventCreationTimeMs);
}

class RecoveryRequestsCompanion extends UpdateCompanion<RecoveryRequestRow> {
  final Value<String> id;
  final Value<String> vaultId;
  final Value<String?> requestEventId;
  final Value<String> initiatorPubkey;
  final Value<int> startedAt;
  final Value<int?> expiresAt;
  final Value<int?> cancelledAt;
  final Value<int?> completedAt;
  final Value<int> distributionVersionAtStart;
  final Value<int> thresholdAtStart;
  final Value<String> status;
  final Value<bool> isPractice;
  final Value<String?> errorMessage;
  final Value<int?> eventCreationTimeMs;
  final Value<int> rowid;
  const RecoveryRequestsCompanion({
    this.id = const Value.absent(),
    this.vaultId = const Value.absent(),
    this.requestEventId = const Value.absent(),
    this.initiatorPubkey = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.cancelledAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.distributionVersionAtStart = const Value.absent(),
    this.thresholdAtStart = const Value.absent(),
    this.status = const Value.absent(),
    this.isPractice = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.eventCreationTimeMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecoveryRequestsCompanion.insert({
    required String id,
    required String vaultId,
    this.requestEventId = const Value.absent(),
    required String initiatorPubkey,
    required int startedAt,
    this.expiresAt = const Value.absent(),
    this.cancelledAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    required int distributionVersionAtStart,
    required int thresholdAtStart,
    required String status,
    this.isPractice = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.eventCreationTimeMs = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        vaultId = Value(vaultId),
        initiatorPubkey = Value(initiatorPubkey),
        startedAt = Value(startedAt),
        distributionVersionAtStart = Value(distributionVersionAtStart),
        thresholdAtStart = Value(thresholdAtStart),
        status = Value(status);
  static Insertable<RecoveryRequestRow> custom({
    Expression<String>? id,
    Expression<String>? vaultId,
    Expression<String>? requestEventId,
    Expression<String>? initiatorPubkey,
    Expression<int>? startedAt,
    Expression<int>? expiresAt,
    Expression<int>? cancelledAt,
    Expression<int>? completedAt,
    Expression<int>? distributionVersionAtStart,
    Expression<int>? thresholdAtStart,
    Expression<String>? status,
    Expression<bool>? isPractice,
    Expression<String>? errorMessage,
    Expression<int>? eventCreationTimeMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (vaultId != null) 'vault_id': vaultId,
      if (requestEventId != null) 'request_event_id': requestEventId,
      if (initiatorPubkey != null) 'initiator_pubkey': initiatorPubkey,
      if (startedAt != null) 'started_at': startedAt,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (cancelledAt != null) 'cancelled_at': cancelledAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (distributionVersionAtStart != null)
        'distribution_version_at_start': distributionVersionAtStart,
      if (thresholdAtStart != null) 'threshold_at_start': thresholdAtStart,
      if (status != null) 'status': status,
      if (isPractice != null) 'is_practice': isPractice,
      if (errorMessage != null) 'error_message': errorMessage,
      if (eventCreationTimeMs != null) 'event_creation_time_ms': eventCreationTimeMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecoveryRequestsCompanion copyWith(
      {Value<String>? id,
      Value<String>? vaultId,
      Value<String?>? requestEventId,
      Value<String>? initiatorPubkey,
      Value<int>? startedAt,
      Value<int?>? expiresAt,
      Value<int?>? cancelledAt,
      Value<int?>? completedAt,
      Value<int>? distributionVersionAtStart,
      Value<int>? thresholdAtStart,
      Value<String>? status,
      Value<bool>? isPractice,
      Value<String?>? errorMessage,
      Value<int?>? eventCreationTimeMs,
      Value<int>? rowid}) {
    return RecoveryRequestsCompanion(
      id: id ?? this.id,
      vaultId: vaultId ?? this.vaultId,
      requestEventId: requestEventId ?? this.requestEventId,
      initiatorPubkey: initiatorPubkey ?? this.initiatorPubkey,
      startedAt: startedAt ?? this.startedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      completedAt: completedAt ?? this.completedAt,
      distributionVersionAtStart: distributionVersionAtStart ?? this.distributionVersionAtStart,
      thresholdAtStart: thresholdAtStart ?? this.thresholdAtStart,
      status: status ?? this.status,
      isPractice: isPractice ?? this.isPractice,
      errorMessage: errorMessage ?? this.errorMessage,
      eventCreationTimeMs: eventCreationTimeMs ?? this.eventCreationTimeMs,
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
    if (requestEventId.present) {
      map['request_event_id'] = Variable<String>(requestEventId.value);
    }
    if (initiatorPubkey.present) {
      map['initiator_pubkey'] = Variable<String>(initiatorPubkey.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<int>(startedAt.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<int>(expiresAt.value);
    }
    if (cancelledAt.present) {
      map['cancelled_at'] = Variable<int>(cancelledAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<int>(completedAt.value);
    }
    if (distributionVersionAtStart.present) {
      map['distribution_version_at_start'] = Variable<int>(distributionVersionAtStart.value);
    }
    if (thresholdAtStart.present) {
      map['threshold_at_start'] = Variable<int>(thresholdAtStart.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (isPractice.present) {
      map['is_practice'] = Variable<bool>(isPractice.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (eventCreationTimeMs.present) {
      map['event_creation_time_ms'] = Variable<int>(eventCreationTimeMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecoveryRequestsCompanion(')
          ..write('id: $id, ')
          ..write('vaultId: $vaultId, ')
          ..write('requestEventId: $requestEventId, ')
          ..write('initiatorPubkey: $initiatorPubkey, ')
          ..write('startedAt: $startedAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('cancelledAt: $cancelledAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('distributionVersionAtStart: $distributionVersionAtStart, ')
          ..write('thresholdAtStart: $thresholdAtStart, ')
          ..write('status: $status, ')
          ..write('isPractice: $isPractice, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('eventCreationTimeMs: $eventCreationTimeMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecoveryRequestParticipantsTable extends RecoveryRequestParticipants
    with TableInfo<$RecoveryRequestParticipantsTable, RecoveryRequestParticipantRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecoveryRequestParticipantsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _requestIdMeta = const VerificationMeta('requestId');
  @override
  late final GeneratedColumn<String> requestId = GeneratedColumn<String>(
      'request_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES recovery_requests (id) ON DELETE CASCADE'));
  static const VerificationMeta _pubkeyMeta = const VerificationMeta('pubkey');
  @override
  late final GeneratedColumn<String> pubkey = GeneratedColumn<String>('pubkey', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [requestId, pubkey];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recovery_request_participants';
  @override
  VerificationContext validateIntegrity(Insertable<RecoveryRequestParticipantRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('request_id')) {
      context.handle(
          _requestIdMeta, requestId.isAcceptableOrUnknown(data['request_id']!, _requestIdMeta));
    } else if (isInserting) {
      context.missing(_requestIdMeta);
    }
    if (data.containsKey('pubkey')) {
      context.handle(_pubkeyMeta, pubkey.isAcceptableOrUnknown(data['pubkey']!, _pubkeyMeta));
    } else if (isInserting) {
      context.missing(_pubkeyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {requestId, pubkey};
  @override
  RecoveryRequestParticipantRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecoveryRequestParticipantRow(
      requestId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}request_id'])!,
      pubkey:
          attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}pubkey'])!,
    );
  }

  @override
  $RecoveryRequestParticipantsTable createAlias(String alias) {
    return $RecoveryRequestParticipantsTable(attachedDatabase, alias);
  }
}

class RecoveryRequestParticipantRow extends DataClass
    implements Insertable<RecoveryRequestParticipantRow> {
  final String requestId;
  final String pubkey;
  const RecoveryRequestParticipantRow({required this.requestId, required this.pubkey});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['request_id'] = Variable<String>(requestId);
    map['pubkey'] = Variable<String>(pubkey);
    return map;
  }

  RecoveryRequestParticipantsCompanion toCompanion(bool nullToAbsent) {
    return RecoveryRequestParticipantsCompanion(
      requestId: Value(requestId),
      pubkey: Value(pubkey),
    );
  }

  factory RecoveryRequestParticipantRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecoveryRequestParticipantRow(
      requestId: serializer.fromJson<String>(json['requestId']),
      pubkey: serializer.fromJson<String>(json['pubkey']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'requestId': serializer.toJson<String>(requestId),
      'pubkey': serializer.toJson<String>(pubkey),
    };
  }

  RecoveryRequestParticipantRow copyWith({String? requestId, String? pubkey}) =>
      RecoveryRequestParticipantRow(
        requestId: requestId ?? this.requestId,
        pubkey: pubkey ?? this.pubkey,
      );
  RecoveryRequestParticipantRow copyWithCompanion(RecoveryRequestParticipantsCompanion data) {
    return RecoveryRequestParticipantRow(
      requestId: data.requestId.present ? data.requestId.value : this.requestId,
      pubkey: data.pubkey.present ? data.pubkey.value : this.pubkey,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecoveryRequestParticipantRow(')
          ..write('requestId: $requestId, ')
          ..write('pubkey: $pubkey')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(requestId, pubkey);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecoveryRequestParticipantRow &&
          other.requestId == this.requestId &&
          other.pubkey == this.pubkey);
}

class RecoveryRequestParticipantsCompanion extends UpdateCompanion<RecoveryRequestParticipantRow> {
  final Value<String> requestId;
  final Value<String> pubkey;
  final Value<int> rowid;
  const RecoveryRequestParticipantsCompanion({
    this.requestId = const Value.absent(),
    this.pubkey = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecoveryRequestParticipantsCompanion.insert({
    required String requestId,
    required String pubkey,
    this.rowid = const Value.absent(),
  })  : requestId = Value(requestId),
        pubkey = Value(pubkey);
  static Insertable<RecoveryRequestParticipantRow> custom({
    Expression<String>? requestId,
    Expression<String>? pubkey,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (requestId != null) 'request_id': requestId,
      if (pubkey != null) 'pubkey': pubkey,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecoveryRequestParticipantsCompanion copyWith(
      {Value<String>? requestId, Value<String>? pubkey, Value<int>? rowid}) {
    return RecoveryRequestParticipantsCompanion(
      requestId: requestId ?? this.requestId,
      pubkey: pubkey ?? this.pubkey,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (requestId.present) {
      map['request_id'] = Variable<String>(requestId.value);
    }
    if (pubkey.present) {
      map['pubkey'] = Variable<String>(pubkey.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecoveryRequestParticipantsCompanion(')
          ..write('requestId: $requestId, ')
          ..write('pubkey: $pubkey, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecoveryResponsesTable extends RecoveryResponses
    with TableInfo<$RecoveryResponsesTable, RecoveryResponseRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecoveryResponsesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>('id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _requestIdMeta = const VerificationMeta('requestId');
  @override
  late final GeneratedColumn<String> requestId = GeneratedColumn<String>(
      'request_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES recovery_requests (id) ON DELETE CASCADE'));
  static const VerificationMeta _stewardIdMeta = const VerificationMeta('stewardId');
  @override
  late final GeneratedColumn<String> stewardId = GeneratedColumn<String>(
      'steward_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES stewards (id) ON DELETE SET NULL'));
  static const VerificationMeta _responderPubkeyMeta = const VerificationMeta('responderPubkey');
  @override
  late final GeneratedColumn<String> responderPubkey = GeneratedColumn<String>(
      'responder_pubkey', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sharePayloadMeta = const VerificationMeta('sharePayload');
  @override
  late final GeneratedColumn<String> sharePayload = GeneratedColumn<String>(
      'share_payload', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _shareDistributionVersionMeta =
      const VerificationMeta('shareDistributionVersion');
  @override
  late final GeneratedColumn<int> shareDistributionVersion = GeneratedColumn<int>(
      'share_distribution_version', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _receivedAtMeta = const VerificationMeta('receivedAt');
  @override
  late final GeneratedColumn<int> receivedAt = GeneratedColumn<int>(
      'received_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _nostrEventIdMeta = const VerificationMeta('nostrEventId');
  @override
  late final GeneratedColumn<String> nostrEventId = GeneratedColumn<String>(
      'nostr_event_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _replyingToEventIdMeta =
      const VerificationMeta('replyingToEventId');
  @override
  late final GeneratedColumn<String> replyingToEventId = GeneratedColumn<String>(
      'replying_to_event_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _approvedMeta = const VerificationMeta('approved');
  @override
  late final GeneratedColumn<bool> approved = GeneratedColumn<bool>('approved', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("approved" IN (0, 1))'));
  static const VerificationMeta _respondedAtMsMeta = const VerificationMeta('respondedAtMs');
  @override
  late final GeneratedColumn<int> respondedAtMs = GeneratedColumn<int>(
      'responded_at_ms', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _errorMessageMeta = const VerificationMeta('errorMessage');
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
      'error_message', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        requestId,
        stewardId,
        responderPubkey,
        sharePayload,
        shareDistributionVersion,
        receivedAt,
        nostrEventId,
        replyingToEventId,
        approved,
        respondedAtMs,
        errorMessage
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recovery_responses';
  @override
  VerificationContext validateIntegrity(Insertable<RecoveryResponseRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('request_id')) {
      context.handle(
          _requestIdMeta, requestId.isAcceptableOrUnknown(data['request_id']!, _requestIdMeta));
    } else if (isInserting) {
      context.missing(_requestIdMeta);
    }
    if (data.containsKey('steward_id')) {
      context.handle(
          _stewardIdMeta, stewardId.isAcceptableOrUnknown(data['steward_id']!, _stewardIdMeta));
    }
    if (data.containsKey('responder_pubkey')) {
      context.handle(_responderPubkeyMeta,
          responderPubkey.isAcceptableOrUnknown(data['responder_pubkey']!, _responderPubkeyMeta));
    } else if (isInserting) {
      context.missing(_responderPubkeyMeta);
    }
    if (data.containsKey('share_payload')) {
      context.handle(_sharePayloadMeta,
          sharePayload.isAcceptableOrUnknown(data['share_payload']!, _sharePayloadMeta));
    } else if (isInserting) {
      context.missing(_sharePayloadMeta);
    }
    if (data.containsKey('share_distribution_version')) {
      context.handle(
          _shareDistributionVersionMeta,
          shareDistributionVersion.isAcceptableOrUnknown(
              data['share_distribution_version']!, _shareDistributionVersionMeta));
    } else if (isInserting) {
      context.missing(_shareDistributionVersionMeta);
    }
    if (data.containsKey('received_at')) {
      context.handle(
          _receivedAtMeta, receivedAt.isAcceptableOrUnknown(data['received_at']!, _receivedAtMeta));
    } else if (isInserting) {
      context.missing(_receivedAtMeta);
    }
    if (data.containsKey('nostr_event_id')) {
      context.handle(_nostrEventIdMeta,
          nostrEventId.isAcceptableOrUnknown(data['nostr_event_id']!, _nostrEventIdMeta));
    }
    if (data.containsKey('replying_to_event_id')) {
      context.handle(
          _replyingToEventIdMeta,
          replyingToEventId.isAcceptableOrUnknown(
              data['replying_to_event_id']!, _replyingToEventIdMeta));
    }
    if (data.containsKey('approved')) {
      context.handle(
          _approvedMeta, approved.isAcceptableOrUnknown(data['approved']!, _approvedMeta));
    } else if (isInserting) {
      context.missing(_approvedMeta);
    }
    if (data.containsKey('responded_at_ms')) {
      context.handle(_respondedAtMsMeta,
          respondedAtMs.isAcceptableOrUnknown(data['responded_at_ms']!, _respondedAtMsMeta));
    }
    if (data.containsKey('error_message')) {
      context.handle(_errorMessageMeta,
          errorMessage.isAcceptableOrUnknown(data['error_message']!, _errorMessageMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecoveryResponseRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecoveryResponseRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      requestId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}request_id'])!,
      stewardId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}steward_id']),
      responderPubkey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}responder_pubkey'])!,
      sharePayload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}share_payload'])!,
      shareDistributionVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}share_distribution_version'])!,
      receivedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}received_at'])!,
      nostrEventId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}nostr_event_id']),
      replyingToEventId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}replying_to_event_id']),
      approved:
          attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}approved'])!,
      respondedAtMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}responded_at_ms']),
      errorMessage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}error_message']),
    );
  }

  @override
  $RecoveryResponsesTable createAlias(String alias) {
    return $RecoveryResponsesTable(attachedDatabase, alias);
  }
}

class RecoveryResponseRow extends DataClass implements Insertable<RecoveryResponseRow> {
  final String id;
  final String requestId;
  final String? stewardId;
  final String responderPubkey;

  /// Shamir fragment plaintext (SQLCipher-protected). Empty when denied.
  final String sharePayload;
  final int shareDistributionVersion;
  final int receivedAt;
  final String? nostrEventId;
  final String? replyingToEventId;
  final bool approved;
  final int? respondedAtMs;
  final String? errorMessage;
  const RecoveryResponseRow(
      {required this.id,
      required this.requestId,
      this.stewardId,
      required this.responderPubkey,
      required this.sharePayload,
      required this.shareDistributionVersion,
      required this.receivedAt,
      this.nostrEventId,
      this.replyingToEventId,
      required this.approved,
      this.respondedAtMs,
      this.errorMessage});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['request_id'] = Variable<String>(requestId);
    if (!nullToAbsent || stewardId != null) {
      map['steward_id'] = Variable<String>(stewardId);
    }
    map['responder_pubkey'] = Variable<String>(responderPubkey);
    map['share_payload'] = Variable<String>(sharePayload);
    map['share_distribution_version'] = Variable<int>(shareDistributionVersion);
    map['received_at'] = Variable<int>(receivedAt);
    if (!nullToAbsent || nostrEventId != null) {
      map['nostr_event_id'] = Variable<String>(nostrEventId);
    }
    if (!nullToAbsent || replyingToEventId != null) {
      map['replying_to_event_id'] = Variable<String>(replyingToEventId);
    }
    map['approved'] = Variable<bool>(approved);
    if (!nullToAbsent || respondedAtMs != null) {
      map['responded_at_ms'] = Variable<int>(respondedAtMs);
    }
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    return map;
  }

  RecoveryResponsesCompanion toCompanion(bool nullToAbsent) {
    return RecoveryResponsesCompanion(
      id: Value(id),
      requestId: Value(requestId),
      stewardId: stewardId == null && nullToAbsent ? const Value.absent() : Value(stewardId),
      responderPubkey: Value(responderPubkey),
      sharePayload: Value(sharePayload),
      shareDistributionVersion: Value(shareDistributionVersion),
      receivedAt: Value(receivedAt),
      nostrEventId:
          nostrEventId == null && nullToAbsent ? const Value.absent() : Value(nostrEventId),
      replyingToEventId: replyingToEventId == null && nullToAbsent
          ? const Value.absent()
          : Value(replyingToEventId),
      approved: Value(approved),
      respondedAtMs:
          respondedAtMs == null && nullToAbsent ? const Value.absent() : Value(respondedAtMs),
      errorMessage:
          errorMessage == null && nullToAbsent ? const Value.absent() : Value(errorMessage),
    );
  }

  factory RecoveryResponseRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecoveryResponseRow(
      id: serializer.fromJson<String>(json['id']),
      requestId: serializer.fromJson<String>(json['requestId']),
      stewardId: serializer.fromJson<String?>(json['stewardId']),
      responderPubkey: serializer.fromJson<String>(json['responderPubkey']),
      sharePayload: serializer.fromJson<String>(json['sharePayload']),
      shareDistributionVersion: serializer.fromJson<int>(json['shareDistributionVersion']),
      receivedAt: serializer.fromJson<int>(json['receivedAt']),
      nostrEventId: serializer.fromJson<String?>(json['nostrEventId']),
      replyingToEventId: serializer.fromJson<String?>(json['replyingToEventId']),
      approved: serializer.fromJson<bool>(json['approved']),
      respondedAtMs: serializer.fromJson<int?>(json['respondedAtMs']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'requestId': serializer.toJson<String>(requestId),
      'stewardId': serializer.toJson<String?>(stewardId),
      'responderPubkey': serializer.toJson<String>(responderPubkey),
      'sharePayload': serializer.toJson<String>(sharePayload),
      'shareDistributionVersion': serializer.toJson<int>(shareDistributionVersion),
      'receivedAt': serializer.toJson<int>(receivedAt),
      'nostrEventId': serializer.toJson<String?>(nostrEventId),
      'replyingToEventId': serializer.toJson<String?>(replyingToEventId),
      'approved': serializer.toJson<bool>(approved),
      'respondedAtMs': serializer.toJson<int?>(respondedAtMs),
      'errorMessage': serializer.toJson<String?>(errorMessage),
    };
  }

  RecoveryResponseRow copyWith(
          {String? id,
          String? requestId,
          Value<String?> stewardId = const Value.absent(),
          String? responderPubkey,
          String? sharePayload,
          int? shareDistributionVersion,
          int? receivedAt,
          Value<String?> nostrEventId = const Value.absent(),
          Value<String?> replyingToEventId = const Value.absent(),
          bool? approved,
          Value<int?> respondedAtMs = const Value.absent(),
          Value<String?> errorMessage = const Value.absent()}) =>
      RecoveryResponseRow(
        id: id ?? this.id,
        requestId: requestId ?? this.requestId,
        stewardId: stewardId.present ? stewardId.value : this.stewardId,
        responderPubkey: responderPubkey ?? this.responderPubkey,
        sharePayload: sharePayload ?? this.sharePayload,
        shareDistributionVersion: shareDistributionVersion ?? this.shareDistributionVersion,
        receivedAt: receivedAt ?? this.receivedAt,
        nostrEventId: nostrEventId.present ? nostrEventId.value : this.nostrEventId,
        replyingToEventId:
            replyingToEventId.present ? replyingToEventId.value : this.replyingToEventId,
        approved: approved ?? this.approved,
        respondedAtMs: respondedAtMs.present ? respondedAtMs.value : this.respondedAtMs,
        errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
      );
  RecoveryResponseRow copyWithCompanion(RecoveryResponsesCompanion data) {
    return RecoveryResponseRow(
      id: data.id.present ? data.id.value : this.id,
      requestId: data.requestId.present ? data.requestId.value : this.requestId,
      stewardId: data.stewardId.present ? data.stewardId.value : this.stewardId,
      responderPubkey:
          data.responderPubkey.present ? data.responderPubkey.value : this.responderPubkey,
      sharePayload: data.sharePayload.present ? data.sharePayload.value : this.sharePayload,
      shareDistributionVersion: data.shareDistributionVersion.present
          ? data.shareDistributionVersion.value
          : this.shareDistributionVersion,
      receivedAt: data.receivedAt.present ? data.receivedAt.value : this.receivedAt,
      nostrEventId: data.nostrEventId.present ? data.nostrEventId.value : this.nostrEventId,
      replyingToEventId:
          data.replyingToEventId.present ? data.replyingToEventId.value : this.replyingToEventId,
      approved: data.approved.present ? data.approved.value : this.approved,
      respondedAtMs: data.respondedAtMs.present ? data.respondedAtMs.value : this.respondedAtMs,
      errorMessage: data.errorMessage.present ? data.errorMessage.value : this.errorMessage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecoveryResponseRow(')
          ..write('id: $id, ')
          ..write('requestId: $requestId, ')
          ..write('stewardId: $stewardId, ')
          ..write('responderPubkey: $responderPubkey, ')
          ..write('sharePayload: $sharePayload, ')
          ..write('shareDistributionVersion: $shareDistributionVersion, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('nostrEventId: $nostrEventId, ')
          ..write('replyingToEventId: $replyingToEventId, ')
          ..write('approved: $approved, ')
          ..write('respondedAtMs: $respondedAtMs, ')
          ..write('errorMessage: $errorMessage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      requestId,
      stewardId,
      responderPubkey,
      sharePayload,
      shareDistributionVersion,
      receivedAt,
      nostrEventId,
      replyingToEventId,
      approved,
      respondedAtMs,
      errorMessage);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecoveryResponseRow &&
          other.id == this.id &&
          other.requestId == this.requestId &&
          other.stewardId == this.stewardId &&
          other.responderPubkey == this.responderPubkey &&
          other.sharePayload == this.sharePayload &&
          other.shareDistributionVersion == this.shareDistributionVersion &&
          other.receivedAt == this.receivedAt &&
          other.nostrEventId == this.nostrEventId &&
          other.replyingToEventId == this.replyingToEventId &&
          other.approved == this.approved &&
          other.respondedAtMs == this.respondedAtMs &&
          other.errorMessage == this.errorMessage);
}

class RecoveryResponsesCompanion extends UpdateCompanion<RecoveryResponseRow> {
  final Value<String> id;
  final Value<String> requestId;
  final Value<String?> stewardId;
  final Value<String> responderPubkey;
  final Value<String> sharePayload;
  final Value<int> shareDistributionVersion;
  final Value<int> receivedAt;
  final Value<String?> nostrEventId;
  final Value<String?> replyingToEventId;
  final Value<bool> approved;
  final Value<int?> respondedAtMs;
  final Value<String?> errorMessage;
  final Value<int> rowid;
  const RecoveryResponsesCompanion({
    this.id = const Value.absent(),
    this.requestId = const Value.absent(),
    this.stewardId = const Value.absent(),
    this.responderPubkey = const Value.absent(),
    this.sharePayload = const Value.absent(),
    this.shareDistributionVersion = const Value.absent(),
    this.receivedAt = const Value.absent(),
    this.nostrEventId = const Value.absent(),
    this.replyingToEventId = const Value.absent(),
    this.approved = const Value.absent(),
    this.respondedAtMs = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecoveryResponsesCompanion.insert({
    required String id,
    required String requestId,
    this.stewardId = const Value.absent(),
    required String responderPubkey,
    required String sharePayload,
    required int shareDistributionVersion,
    required int receivedAt,
    this.nostrEventId = const Value.absent(),
    this.replyingToEventId = const Value.absent(),
    required bool approved,
    this.respondedAtMs = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        requestId = Value(requestId),
        responderPubkey = Value(responderPubkey),
        sharePayload = Value(sharePayload),
        shareDistributionVersion = Value(shareDistributionVersion),
        receivedAt = Value(receivedAt),
        approved = Value(approved);
  static Insertable<RecoveryResponseRow> custom({
    Expression<String>? id,
    Expression<String>? requestId,
    Expression<String>? stewardId,
    Expression<String>? responderPubkey,
    Expression<String>? sharePayload,
    Expression<int>? shareDistributionVersion,
    Expression<int>? receivedAt,
    Expression<String>? nostrEventId,
    Expression<String>? replyingToEventId,
    Expression<bool>? approved,
    Expression<int>? respondedAtMs,
    Expression<String>? errorMessage,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (requestId != null) 'request_id': requestId,
      if (stewardId != null) 'steward_id': stewardId,
      if (responderPubkey != null) 'responder_pubkey': responderPubkey,
      if (sharePayload != null) 'share_payload': sharePayload,
      if (shareDistributionVersion != null) 'share_distribution_version': shareDistributionVersion,
      if (receivedAt != null) 'received_at': receivedAt,
      if (nostrEventId != null) 'nostr_event_id': nostrEventId,
      if (replyingToEventId != null) 'replying_to_event_id': replyingToEventId,
      if (approved != null) 'approved': approved,
      if (respondedAtMs != null) 'responded_at_ms': respondedAtMs,
      if (errorMessage != null) 'error_message': errorMessage,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecoveryResponsesCompanion copyWith(
      {Value<String>? id,
      Value<String>? requestId,
      Value<String?>? stewardId,
      Value<String>? responderPubkey,
      Value<String>? sharePayload,
      Value<int>? shareDistributionVersion,
      Value<int>? receivedAt,
      Value<String?>? nostrEventId,
      Value<String?>? replyingToEventId,
      Value<bool>? approved,
      Value<int?>? respondedAtMs,
      Value<String?>? errorMessage,
      Value<int>? rowid}) {
    return RecoveryResponsesCompanion(
      id: id ?? this.id,
      requestId: requestId ?? this.requestId,
      stewardId: stewardId ?? this.stewardId,
      responderPubkey: responderPubkey ?? this.responderPubkey,
      sharePayload: sharePayload ?? this.sharePayload,
      shareDistributionVersion: shareDistributionVersion ?? this.shareDistributionVersion,
      receivedAt: receivedAt ?? this.receivedAt,
      nostrEventId: nostrEventId ?? this.nostrEventId,
      replyingToEventId: replyingToEventId ?? this.replyingToEventId,
      approved: approved ?? this.approved,
      respondedAtMs: respondedAtMs ?? this.respondedAtMs,
      errorMessage: errorMessage ?? this.errorMessage,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (requestId.present) {
      map['request_id'] = Variable<String>(requestId.value);
    }
    if (stewardId.present) {
      map['steward_id'] = Variable<String>(stewardId.value);
    }
    if (responderPubkey.present) {
      map['responder_pubkey'] = Variable<String>(responderPubkey.value);
    }
    if (sharePayload.present) {
      map['share_payload'] = Variable<String>(sharePayload.value);
    }
    if (shareDistributionVersion.present) {
      map['share_distribution_version'] = Variable<int>(shareDistributionVersion.value);
    }
    if (receivedAt.present) {
      map['received_at'] = Variable<int>(receivedAt.value);
    }
    if (nostrEventId.present) {
      map['nostr_event_id'] = Variable<String>(nostrEventId.value);
    }
    if (replyingToEventId.present) {
      map['replying_to_event_id'] = Variable<String>(replyingToEventId.value);
    }
    if (approved.present) {
      map['approved'] = Variable<bool>(approved.value);
    }
    if (respondedAtMs.present) {
      map['responded_at_ms'] = Variable<int>(respondedAtMs.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecoveryResponsesCompanion(')
          ..write('id: $id, ')
          ..write('requestId: $requestId, ')
          ..write('stewardId: $stewardId, ')
          ..write('responderPubkey: $responderPubkey, ')
          ..write('sharePayload: $sharePayload, ')
          ..write('shareDistributionVersion: $shareDistributionVersion, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('nostrEventId: $nostrEventId, ')
          ..write('replyingToEventId: $replyingToEventId, ')
          ..write('approved: $approved, ')
          ..write('respondedAtMs: $respondedAtMs, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboxTable extends Outbox with TableInfo<$OutboxTable, OutboxRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>('id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _vaultIdMeta = const VerificationMeta('vaultId');
  @override
  late final GeneratedColumn<String> vaultId = GeneratedColumn<String>(
      'vault_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES vaults (id) ON DELETE CASCADE'));
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<int> kind = GeneratedColumn<int>('kind', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _eventIdMeta = const VerificationMeta('eventId');
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
      'event_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>('created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _nextAttemptAtMeta = const VerificationMeta('nextAttemptAt');
  @override
  late final GeneratedColumn<int> nextAttemptAt = GeneratedColumn<int>(
      'next_attempt_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _eventJsonMeta = const VerificationMeta('eventJson');
  @override
  late final GeneratedColumn<String> eventJson = GeneratedColumn<String>(
      'event_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _correlationIdMeta = const VerificationMeta('correlationId');
  @override
  late final GeneratedColumn<String> correlationId = GeneratedColumn<String>(
      'correlation_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, vaultId, kind, eventId, createdAt, nextAttemptAt, eventJson, correlationId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox';
  @override
  VerificationContext validateIntegrity(Insertable<OutboxRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('vault_id')) {
      context.handle(_vaultIdMeta, vaultId.isAcceptableOrUnknown(data['vault_id']!, _vaultIdMeta));
    }
    if (data.containsKey('kind')) {
      context.handle(_kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('event_id')) {
      context.handle(_eventIdMeta, eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta));
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
          _createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(_nextAttemptAtMeta,
          nextAttemptAt.isAcceptableOrUnknown(data['next_attempt_at']!, _nextAttemptAtMeta));
    }
    if (data.containsKey('event_json')) {
      context.handle(
          _eventJsonMeta, eventJson.isAcceptableOrUnknown(data['event_json']!, _eventJsonMeta));
    } else if (isInserting) {
      context.missing(_eventJsonMeta);
    }
    if (data.containsKey('correlation_id')) {
      context.handle(_correlationIdMeta,
          correlationId.isAcceptableOrUnknown(data['correlation_id']!, _correlationIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OutboxRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      vaultId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}vault_id']),
      kind: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}kind'])!,
      eventId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}event_id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      nextAttemptAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}next_attempt_at']),
      eventJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}event_json'])!,
      correlationId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}correlation_id']),
    );
  }

  @override
  $OutboxTable createAlias(String alias) {
    return $OutboxTable(attachedDatabase, alias);
  }
}

class OutboxRow extends DataClass implements Insertable<OutboxRow> {
  final String id;

  /// Nullable for non-vault-scoped publishes.
  final String? vaultId;
  final int kind;
  final String eventId;
  final int createdAt;
  final int? nextAttemptAt;
  final String eventJson;
  final String? correlationId;
  const OutboxRow(
      {required this.id,
      this.vaultId,
      required this.kind,
      required this.eventId,
      required this.createdAt,
      this.nextAttemptAt,
      required this.eventJson,
      this.correlationId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || vaultId != null) {
      map['vault_id'] = Variable<String>(vaultId);
    }
    map['kind'] = Variable<int>(kind);
    map['event_id'] = Variable<String>(eventId);
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || nextAttemptAt != null) {
      map['next_attempt_at'] = Variable<int>(nextAttemptAt);
    }
    map['event_json'] = Variable<String>(eventJson);
    if (!nullToAbsent || correlationId != null) {
      map['correlation_id'] = Variable<String>(correlationId);
    }
    return map;
  }

  OutboxCompanion toCompanion(bool nullToAbsent) {
    return OutboxCompanion(
      id: Value(id),
      vaultId: vaultId == null && nullToAbsent ? const Value.absent() : Value(vaultId),
      kind: Value(kind),
      eventId: Value(eventId),
      createdAt: Value(createdAt),
      nextAttemptAt:
          nextAttemptAt == null && nullToAbsent ? const Value.absent() : Value(nextAttemptAt),
      eventJson: Value(eventJson),
      correlationId:
          correlationId == null && nullToAbsent ? const Value.absent() : Value(correlationId),
    );
  }

  factory OutboxRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxRow(
      id: serializer.fromJson<String>(json['id']),
      vaultId: serializer.fromJson<String?>(json['vaultId']),
      kind: serializer.fromJson<int>(json['kind']),
      eventId: serializer.fromJson<String>(json['eventId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      nextAttemptAt: serializer.fromJson<int?>(json['nextAttemptAt']),
      eventJson: serializer.fromJson<String>(json['eventJson']),
      correlationId: serializer.fromJson<String?>(json['correlationId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'vaultId': serializer.toJson<String?>(vaultId),
      'kind': serializer.toJson<int>(kind),
      'eventId': serializer.toJson<String>(eventId),
      'createdAt': serializer.toJson<int>(createdAt),
      'nextAttemptAt': serializer.toJson<int?>(nextAttemptAt),
      'eventJson': serializer.toJson<String>(eventJson),
      'correlationId': serializer.toJson<String?>(correlationId),
    };
  }

  OutboxRow copyWith(
          {String? id,
          Value<String?> vaultId = const Value.absent(),
          int? kind,
          String? eventId,
          int? createdAt,
          Value<int?> nextAttemptAt = const Value.absent(),
          String? eventJson,
          Value<String?> correlationId = const Value.absent()}) =>
      OutboxRow(
        id: id ?? this.id,
        vaultId: vaultId.present ? vaultId.value : this.vaultId,
        kind: kind ?? this.kind,
        eventId: eventId ?? this.eventId,
        createdAt: createdAt ?? this.createdAt,
        nextAttemptAt: nextAttemptAt.present ? nextAttemptAt.value : this.nextAttemptAt,
        eventJson: eventJson ?? this.eventJson,
        correlationId: correlationId.present ? correlationId.value : this.correlationId,
      );
  OutboxRow copyWithCompanion(OutboxCompanion data) {
    return OutboxRow(
      id: data.id.present ? data.id.value : this.id,
      vaultId: data.vaultId.present ? data.vaultId.value : this.vaultId,
      kind: data.kind.present ? data.kind.value : this.kind,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      nextAttemptAt: data.nextAttemptAt.present ? data.nextAttemptAt.value : this.nextAttemptAt,
      eventJson: data.eventJson.present ? data.eventJson.value : this.eventJson,
      correlationId: data.correlationId.present ? data.correlationId.value : this.correlationId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxRow(')
          ..write('id: $id, ')
          ..write('vaultId: $vaultId, ')
          ..write('kind: $kind, ')
          ..write('eventId: $eventId, ')
          ..write('createdAt: $createdAt, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('eventJson: $eventJson, ')
          ..write('correlationId: $correlationId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, vaultId, kind, eventId, createdAt, nextAttemptAt, eventJson, correlationId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxRow &&
          other.id == this.id &&
          other.vaultId == this.vaultId &&
          other.kind == this.kind &&
          other.eventId == this.eventId &&
          other.createdAt == this.createdAt &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.eventJson == this.eventJson &&
          other.correlationId == this.correlationId);
}

class OutboxCompanion extends UpdateCompanion<OutboxRow> {
  final Value<String> id;
  final Value<String?> vaultId;
  final Value<int> kind;
  final Value<String> eventId;
  final Value<int> createdAt;
  final Value<int?> nextAttemptAt;
  final Value<String> eventJson;
  final Value<String?> correlationId;
  final Value<int> rowid;
  const OutboxCompanion({
    this.id = const Value.absent(),
    this.vaultId = const Value.absent(),
    this.kind = const Value.absent(),
    this.eventId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.eventJson = const Value.absent(),
    this.correlationId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OutboxCompanion.insert({
    required String id,
    this.vaultId = const Value.absent(),
    required int kind,
    required String eventId,
    required int createdAt,
    this.nextAttemptAt = const Value.absent(),
    required String eventJson,
    this.correlationId = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        kind = Value(kind),
        eventId = Value(eventId),
        createdAt = Value(createdAt),
        eventJson = Value(eventJson);
  static Insertable<OutboxRow> custom({
    Expression<String>? id,
    Expression<String>? vaultId,
    Expression<int>? kind,
    Expression<String>? eventId,
    Expression<int>? createdAt,
    Expression<int>? nextAttemptAt,
    Expression<String>? eventJson,
    Expression<String>? correlationId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (vaultId != null) 'vault_id': vaultId,
      if (kind != null) 'kind': kind,
      if (eventId != null) 'event_id': eventId,
      if (createdAt != null) 'created_at': createdAt,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (eventJson != null) 'event_json': eventJson,
      if (correlationId != null) 'correlation_id': correlationId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OutboxCompanion copyWith(
      {Value<String>? id,
      Value<String?>? vaultId,
      Value<int>? kind,
      Value<String>? eventId,
      Value<int>? createdAt,
      Value<int?>? nextAttemptAt,
      Value<String>? eventJson,
      Value<String?>? correlationId,
      Value<int>? rowid}) {
    return OutboxCompanion(
      id: id ?? this.id,
      vaultId: vaultId ?? this.vaultId,
      kind: kind ?? this.kind,
      eventId: eventId ?? this.eventId,
      createdAt: createdAt ?? this.createdAt,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      eventJson: eventJson ?? this.eventJson,
      correlationId: correlationId ?? this.correlationId,
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
    if (kind.present) {
      map['kind'] = Variable<int>(kind.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<int>(nextAttemptAt.value);
    }
    if (eventJson.present) {
      map['event_json'] = Variable<String>(eventJson.value);
    }
    if (correlationId.present) {
      map['correlation_id'] = Variable<String>(correlationId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxCompanion(')
          ..write('id: $id, ')
          ..write('vaultId: $vaultId, ')
          ..write('kind: $kind, ')
          ..write('eventId: $eventId, ')
          ..write('createdAt: $createdAt, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('eventJson: $eventJson, ')
          ..write('correlationId: $correlationId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboxRelaysTable extends OutboxRelays with TableInfo<$OutboxRelaysTable, OutboxRelayRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxRelaysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _outboxIdMeta = const VerificationMeta('outboxId');
  @override
  late final GeneratedColumn<String> outboxId = GeneratedColumn<String>(
      'outbox_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES outbox (id) ON DELETE CASCADE'));
  static const VerificationMeta _relayUrlMeta = const VerificationMeta('relayUrl');
  @override
  late final GeneratedColumn<String> relayUrl = GeneratedColumn<String>(
      'relay_url', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>('status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _attemptsMeta = const VerificationMeta('attempts');
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>('attempts', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false, defaultValue: const Constant(0));
  static const VerificationMeta _nextAttemptAtMeta = const VerificationMeta('nextAttemptAt');
  @override
  late final GeneratedColumn<int> nextAttemptAt = GeneratedColumn<int>(
      'next_attempt_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _lastErrorMeta = const VerificationMeta('lastError');
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
      'last_error', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [outboxId, relayUrl, status, attempts, nextAttemptAt, lastError];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox_relays';
  @override
  VerificationContext validateIntegrity(Insertable<OutboxRelayRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('outbox_id')) {
      context.handle(
          _outboxIdMeta, outboxId.isAcceptableOrUnknown(data['outbox_id']!, _outboxIdMeta));
    } else if (isInserting) {
      context.missing(_outboxIdMeta);
    }
    if (data.containsKey('relay_url')) {
      context.handle(
          _relayUrlMeta, relayUrl.isAcceptableOrUnknown(data['relay_url']!, _relayUrlMeta));
    } else if (isInserting) {
      context.missing(_relayUrlMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta, status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(
          _attemptsMeta, attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta));
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(_nextAttemptAtMeta,
          nextAttemptAt.isAcceptableOrUnknown(data['next_attempt_at']!, _nextAttemptAtMeta));
    }
    if (data.containsKey('last_error')) {
      context.handle(
          _lastErrorMeta, lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {outboxId, relayUrl};
  @override
  OutboxRelayRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxRelayRow(
      outboxId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}outbox_id'])!,
      relayUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}relay_url'])!,
      status:
          attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      attempts:
          attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}attempts'])!,
      nextAttemptAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}next_attempt_at']),
      lastError: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_error']),
    );
  }

  @override
  $OutboxRelaysTable createAlias(String alias) {
    return $OutboxRelaysTable(attachedDatabase, alias);
  }
}

class OutboxRelayRow extends DataClass implements Insertable<OutboxRelayRow> {
  final String outboxId;
  final String relayUrl;

  /// `pending` | `success` | `failed`
  final String status;
  final int attempts;
  final int? nextAttemptAt;
  final String? lastError;
  const OutboxRelayRow(
      {required this.outboxId,
      required this.relayUrl,
      required this.status,
      required this.attempts,
      this.nextAttemptAt,
      this.lastError});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['outbox_id'] = Variable<String>(outboxId);
    map['relay_url'] = Variable<String>(relayUrl);
    map['status'] = Variable<String>(status);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || nextAttemptAt != null) {
      map['next_attempt_at'] = Variable<int>(nextAttemptAt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  OutboxRelaysCompanion toCompanion(bool nullToAbsent) {
    return OutboxRelaysCompanion(
      outboxId: Value(outboxId),
      relayUrl: Value(relayUrl),
      status: Value(status),
      attempts: Value(attempts),
      nextAttemptAt:
          nextAttemptAt == null && nullToAbsent ? const Value.absent() : Value(nextAttemptAt),
      lastError: lastError == null && nullToAbsent ? const Value.absent() : Value(lastError),
    );
  }

  factory OutboxRelayRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxRelayRow(
      outboxId: serializer.fromJson<String>(json['outboxId']),
      relayUrl: serializer.fromJson<String>(json['relayUrl']),
      status: serializer.fromJson<String>(json['status']),
      attempts: serializer.fromJson<int>(json['attempts']),
      nextAttemptAt: serializer.fromJson<int?>(json['nextAttemptAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'outboxId': serializer.toJson<String>(outboxId),
      'relayUrl': serializer.toJson<String>(relayUrl),
      'status': serializer.toJson<String>(status),
      'attempts': serializer.toJson<int>(attempts),
      'nextAttemptAt': serializer.toJson<int?>(nextAttemptAt),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  OutboxRelayRow copyWith(
          {String? outboxId,
          String? relayUrl,
          String? status,
          int? attempts,
          Value<int?> nextAttemptAt = const Value.absent(),
          Value<String?> lastError = const Value.absent()}) =>
      OutboxRelayRow(
        outboxId: outboxId ?? this.outboxId,
        relayUrl: relayUrl ?? this.relayUrl,
        status: status ?? this.status,
        attempts: attempts ?? this.attempts,
        nextAttemptAt: nextAttemptAt.present ? nextAttemptAt.value : this.nextAttemptAt,
        lastError: lastError.present ? lastError.value : this.lastError,
      );
  OutboxRelayRow copyWithCompanion(OutboxRelaysCompanion data) {
    return OutboxRelayRow(
      outboxId: data.outboxId.present ? data.outboxId.value : this.outboxId,
      relayUrl: data.relayUrl.present ? data.relayUrl.value : this.relayUrl,
      status: data.status.present ? data.status.value : this.status,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      nextAttemptAt: data.nextAttemptAt.present ? data.nextAttemptAt.value : this.nextAttemptAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxRelayRow(')
          ..write('outboxId: $outboxId, ')
          ..write('relayUrl: $relayUrl, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(outboxId, relayUrl, status, attempts, nextAttemptAt, lastError);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxRelayRow &&
          other.outboxId == this.outboxId &&
          other.relayUrl == this.relayUrl &&
          other.status == this.status &&
          other.attempts == this.attempts &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.lastError == this.lastError);
}

class OutboxRelaysCompanion extends UpdateCompanion<OutboxRelayRow> {
  final Value<String> outboxId;
  final Value<String> relayUrl;
  final Value<String> status;
  final Value<int> attempts;
  final Value<int?> nextAttemptAt;
  final Value<String?> lastError;
  final Value<int> rowid;
  const OutboxRelaysCompanion({
    this.outboxId = const Value.absent(),
    this.relayUrl = const Value.absent(),
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OutboxRelaysCompanion.insert({
    required String outboxId,
    required String relayUrl,
    required String status,
    this.attempts = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : outboxId = Value(outboxId),
        relayUrl = Value(relayUrl),
        status = Value(status);
  static Insertable<OutboxRelayRow> custom({
    Expression<String>? outboxId,
    Expression<String>? relayUrl,
    Expression<String>? status,
    Expression<int>? attempts,
    Expression<int>? nextAttemptAt,
    Expression<String>? lastError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (outboxId != null) 'outbox_id': outboxId,
      if (relayUrl != null) 'relay_url': relayUrl,
      if (status != null) 'status': status,
      if (attempts != null) 'attempts': attempts,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (lastError != null) 'last_error': lastError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OutboxRelaysCompanion copyWith(
      {Value<String>? outboxId,
      Value<String>? relayUrl,
      Value<String>? status,
      Value<int>? attempts,
      Value<int?>? nextAttemptAt,
      Value<String?>? lastError,
      Value<int>? rowid}) {
    return OutboxRelaysCompanion(
      outboxId: outboxId ?? this.outboxId,
      relayUrl: relayUrl ?? this.relayUrl,
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      lastError: lastError ?? this.lastError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (outboxId.present) {
      map['outbox_id'] = Variable<String>(outboxId.value);
    }
    if (relayUrl.present) {
      map['relay_url'] = Variable<String>(relayUrl.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<int>(nextAttemptAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxRelaysCompanion(')
          ..write('outboxId: $outboxId, ')
          ..write('relayUrl: $relayUrl, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastError: $lastError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $KvTable extends Kv with TableInfo<$KvTable, KvRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KvTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>('key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>('value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'kv';
  @override
  VerificationContext validateIntegrity(Insertable<KvRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(_keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(_valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  KvRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KvRow(
      key: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value:
          attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $KvTable createAlias(String alias) {
    return $KvTable(attachedDatabase, alias);
  }
}

class KvRow extends DataClass implements Insertable<KvRow> {
  final String key;
  final String value;
  const KvRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  KvCompanion toCompanion(bool nullToAbsent) {
    return KvCompanion(
      key: Value(key),
      value: Value(value),
    );
  }

  factory KvRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KvRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  KvRow copyWith({String? key, String? value}) => KvRow(
        key: key ?? this.key,
        value: value ?? this.value,
      );
  KvRow copyWithCompanion(KvCompanion data) {
    return KvRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KvRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KvRow && other.key == this.key && other.value == this.value);
}

class KvCompanion extends UpdateCompanion<KvRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const KvCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KvCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value);
  static Insertable<KvRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KvCompanion copyWith({Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return KvCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KvCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ViewedNotificationsTable extends ViewedNotifications
    with TableInfo<$ViewedNotificationsTable, ViewedNotificationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ViewedNotificationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _notificationIdMeta = const VerificationMeta('notificationId');
  @override
  late final GeneratedColumn<String> notificationId = GeneratedColumn<String>(
      'notification_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _viewedAtMeta = const VerificationMeta('viewedAt');
  @override
  late final GeneratedColumn<int> viewedAt = GeneratedColumn<int>('viewed_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [notificationId, viewedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'viewed_notifications';
  @override
  VerificationContext validateIntegrity(Insertable<ViewedNotificationRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('notification_id')) {
      context.handle(_notificationIdMeta,
          notificationId.isAcceptableOrUnknown(data['notification_id']!, _notificationIdMeta));
    } else if (isInserting) {
      context.missing(_notificationIdMeta);
    }
    if (data.containsKey('viewed_at')) {
      context.handle(
          _viewedAtMeta, viewedAt.isAcceptableOrUnknown(data['viewed_at']!, _viewedAtMeta));
    } else if (isInserting) {
      context.missing(_viewedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {notificationId};
  @override
  ViewedNotificationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ViewedNotificationRow(
      notificationId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notification_id'])!,
      viewedAt:
          attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}viewed_at'])!,
    );
  }

  @override
  $ViewedNotificationsTable createAlias(String alias) {
    return $ViewedNotificationsTable(attachedDatabase, alias);
  }
}

class ViewedNotificationRow extends DataClass implements Insertable<ViewedNotificationRow> {
  final String notificationId;
  final int viewedAt;
  const ViewedNotificationRow({required this.notificationId, required this.viewedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['notification_id'] = Variable<String>(notificationId);
    map['viewed_at'] = Variable<int>(viewedAt);
    return map;
  }

  ViewedNotificationsCompanion toCompanion(bool nullToAbsent) {
    return ViewedNotificationsCompanion(
      notificationId: Value(notificationId),
      viewedAt: Value(viewedAt),
    );
  }

  factory ViewedNotificationRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ViewedNotificationRow(
      notificationId: serializer.fromJson<String>(json['notificationId']),
      viewedAt: serializer.fromJson<int>(json['viewedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'notificationId': serializer.toJson<String>(notificationId),
      'viewedAt': serializer.toJson<int>(viewedAt),
    };
  }

  ViewedNotificationRow copyWith({String? notificationId, int? viewedAt}) => ViewedNotificationRow(
        notificationId: notificationId ?? this.notificationId,
        viewedAt: viewedAt ?? this.viewedAt,
      );
  ViewedNotificationRow copyWithCompanion(ViewedNotificationsCompanion data) {
    return ViewedNotificationRow(
      notificationId: data.notificationId.present ? data.notificationId.value : this.notificationId,
      viewedAt: data.viewedAt.present ? data.viewedAt.value : this.viewedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ViewedNotificationRow(')
          ..write('notificationId: $notificationId, ')
          ..write('viewedAt: $viewedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(notificationId, viewedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ViewedNotificationRow &&
          other.notificationId == this.notificationId &&
          other.viewedAt == this.viewedAt);
}

class ViewedNotificationsCompanion extends UpdateCompanion<ViewedNotificationRow> {
  final Value<String> notificationId;
  final Value<int> viewedAt;
  final Value<int> rowid;
  const ViewedNotificationsCompanion({
    this.notificationId = const Value.absent(),
    this.viewedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ViewedNotificationsCompanion.insert({
    required String notificationId,
    required int viewedAt,
    this.rowid = const Value.absent(),
  })  : notificationId = Value(notificationId),
        viewedAt = Value(viewedAt);
  static Insertable<ViewedNotificationRow> custom({
    Expression<String>? notificationId,
    Expression<int>? viewedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (notificationId != null) 'notification_id': notificationId,
      if (viewedAt != null) 'viewed_at': viewedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ViewedNotificationsCompanion copyWith(
      {Value<String>? notificationId, Value<int>? viewedAt, Value<int>? rowid}) {
    return ViewedNotificationsCompanion(
      notificationId: notificationId ?? this.notificationId,
      viewedAt: viewedAt ?? this.viewedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (notificationId.present) {
      map['notification_id'] = Variable<String>(notificationId.value);
    }
    if (viewedAt.present) {
      map['viewed_at'] = Variable<int>(viewedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ViewedNotificationsCompanion(')
          ..write('notificationId: $notificationId, ')
          ..write('viewedAt: $viewedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncedConsentsTable extends SyncedConsents
    with TableInfo<$SyncedConsentsTable, SyncedConsentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncedConsentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _consentIdMeta = const VerificationMeta('consentId');
  @override
  late final GeneratedColumn<String> consentId = GeneratedColumn<String>(
      'consent_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadMeta = const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
      'payload', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _syncedAtMeta = const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<int> syncedAt = GeneratedColumn<int>('synced_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [consentId, payload, syncedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'synced_consents';
  @override
  VerificationContext validateIntegrity(Insertable<SyncedConsentRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('consent_id')) {
      context.handle(
          _consentIdMeta, consentId.isAcceptableOrUnknown(data['consent_id']!, _consentIdMeta));
    } else if (isInserting) {
      context.missing(_consentIdMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta, payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(
          _syncedAtMeta, syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    } else if (isInserting) {
      context.missing(_syncedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {consentId};
  @override
  SyncedConsentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncedConsentRow(
      consentId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}consent_id'])!,
      payload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload'])!,
      syncedAt:
          attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}synced_at'])!,
    );
  }

  @override
  $SyncedConsentsTable createAlias(String alias) {
    return $SyncedConsentsTable(attachedDatabase, alias);
  }
}

class SyncedConsentRow extends DataClass implements Insertable<SyncedConsentRow> {
  final String consentId;
  final String payload;
  final int syncedAt;
  const SyncedConsentRow({required this.consentId, required this.payload, required this.syncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['consent_id'] = Variable<String>(consentId);
    map['payload'] = Variable<String>(payload);
    map['synced_at'] = Variable<int>(syncedAt);
    return map;
  }

  SyncedConsentsCompanion toCompanion(bool nullToAbsent) {
    return SyncedConsentsCompanion(
      consentId: Value(consentId),
      payload: Value(payload),
      syncedAt: Value(syncedAt),
    );
  }

  factory SyncedConsentRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncedConsentRow(
      consentId: serializer.fromJson<String>(json['consentId']),
      payload: serializer.fromJson<String>(json['payload']),
      syncedAt: serializer.fromJson<int>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'consentId': serializer.toJson<String>(consentId),
      'payload': serializer.toJson<String>(payload),
      'syncedAt': serializer.toJson<int>(syncedAt),
    };
  }

  SyncedConsentRow copyWith({String? consentId, String? payload, int? syncedAt}) =>
      SyncedConsentRow(
        consentId: consentId ?? this.consentId,
        payload: payload ?? this.payload,
        syncedAt: syncedAt ?? this.syncedAt,
      );
  SyncedConsentRow copyWithCompanion(SyncedConsentsCompanion data) {
    return SyncedConsentRow(
      consentId: data.consentId.present ? data.consentId.value : this.consentId,
      payload: data.payload.present ? data.payload.value : this.payload,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncedConsentRow(')
          ..write('consentId: $consentId, ')
          ..write('payload: $payload, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(consentId, payload, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncedConsentRow &&
          other.consentId == this.consentId &&
          other.payload == this.payload &&
          other.syncedAt == this.syncedAt);
}

class SyncedConsentsCompanion extends UpdateCompanion<SyncedConsentRow> {
  final Value<String> consentId;
  final Value<String> payload;
  final Value<int> syncedAt;
  final Value<int> rowid;
  const SyncedConsentsCompanion({
    this.consentId = const Value.absent(),
    this.payload = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncedConsentsCompanion.insert({
    required String consentId,
    required String payload,
    required int syncedAt,
    this.rowid = const Value.absent(),
  })  : consentId = Value(consentId),
        payload = Value(payload),
        syncedAt = Value(syncedAt);
  static Insertable<SyncedConsentRow> custom({
    Expression<String>? consentId,
    Expression<String>? payload,
    Expression<int>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (consentId != null) 'consent_id': consentId,
      if (payload != null) 'payload': payload,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncedConsentsCompanion copyWith(
      {Value<String>? consentId, Value<String>? payload, Value<int>? syncedAt, Value<int>? rowid}) {
    return SyncedConsentsCompanion(
      consentId: consentId ?? this.consentId,
      payload: payload ?? this.payload,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (consentId.present) {
      map['consent_id'] = Variable<String>(consentId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<int>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncedConsentsCompanion(')
          ..write('consentId: $consentId, ')
          ..write('payload: $payload, ')
          ..write('syncedAt: $syncedAt, ')
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
  late final $InvitationsTable invitations = $InvitationsTable(this);
  late final $DistributionsTable distributions = $DistributionsTable(this);
  late final $DistributionSharesTable distributionShares = $DistributionSharesTable(this);
  late final $HeldSharesTable heldShares = $HeldSharesTable(this);
  late final $RecoveryRequestsTable recoveryRequests = $RecoveryRequestsTable(this);
  late final $RecoveryRequestParticipantsTable recoveryRequestParticipants =
      $RecoveryRequestParticipantsTable(this);
  late final $RecoveryResponsesTable recoveryResponses = $RecoveryResponsesTable(this);
  late final $OutboxTable outbox = $OutboxTable(this);
  late final $OutboxRelaysTable outboxRelays = $OutboxRelaysTable(this);
  late final $KvTable kv = $KvTable(this);
  late final $ViewedNotificationsTable viewedNotifications = $ViewedNotificationsTable(this);
  late final $SyncedConsentsTable syncedConsents = $SyncedConsentsTable(this);
  late final VaultDao vaultDao = VaultDao(this as AppDatabase);
  late final VaultRelayDao vaultRelayDao = VaultRelayDao(this as AppDatabase);
  late final OwnedVaultDao ownedVaultDao = OwnedVaultDao(this as AppDatabase);
  late final StewardDao stewardDao = StewardDao(this as AppDatabase);
  late final InvitationDao invitationDao = InvitationDao(this as AppDatabase);
  late final DistributionDao distributionDao = DistributionDao(this as AppDatabase);
  late final HeldShareDao heldShareDao = HeldShareDao(this as AppDatabase);
  late final RecoveryDao recoveryDao = RecoveryDao(this as AppDatabase);
  late final OutboxDao outboxDao = OutboxDao(this as AppDatabase);
  late final AppStateDao appStateDao = AppStateDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        vaults,
        vaultRelays,
        ownedVaults,
        stewards,
        invitations,
        distributions,
        distributionShares,
        heldShares,
        recoveryRequests,
        recoveryRequestParticipants,
        recoveryResponses,
        outbox,
        outboxRelays,
        kv,
        viewedNotifications,
        syncedConsents
      ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('vaults', limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('vault_relays', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('vaults', limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('owned_vaults', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('vaults', limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('stewards', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('vaults', limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('invitations', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('stewards', limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('invitations', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('vaults', limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('distributions', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('distributions', limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('distribution_shares', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('vaults', limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('held_shares', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('vaults', limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('recovery_requests', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('recovery_requests',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('recovery_request_participants', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('recovery_requests',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('recovery_responses', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('stewards', limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('recovery_responses', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('vaults', limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('outbox', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('outbox', limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('outbox_relays', kind: UpdateKind.delete),
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

final class $$VaultsTableReferences extends BaseReferences<_$AppDatabase, $VaultsTable, VaultRow> {
  $$VaultsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$VaultRelaysTable, List<VaultRelayRow>> _vaultRelaysRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.vaultRelays,
          aliasName: $_aliasNameGenerator(db.vaults.id, db.vaultRelays.vaultId));

  $$VaultRelaysTableProcessedTableManager get vaultRelaysRefs {
    final manager = $$VaultRelaysTableTableManager($_db, $_db.vaultRelays)
        .filter((f) => f.vaultId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_vaultRelaysRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$OwnedVaultsTable, List<OwnedVaultRow>> _ownedVaultsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.ownedVaults,
          aliasName: $_aliasNameGenerator(db.vaults.id, db.ownedVaults.vaultId));

  $$OwnedVaultsTableProcessedTableManager get ownedVaultsRefs {
    final manager = $$OwnedVaultsTableTableManager($_db, $_db.ownedVaults)
        .filter((f) => f.vaultId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_ownedVaultsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$StewardsTable, List<StewardRow>> _stewardsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.stewards,
          aliasName: $_aliasNameGenerator(db.vaults.id, db.stewards.vaultId));

  $$StewardsTableProcessedTableManager get stewardsRefs {
    final manager = $$StewardsTableTableManager($_db, $_db.stewards)
        .filter((f) => f.vaultId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_stewardsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$InvitationsTable, List<InvitationRow>> _invitationsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.invitations,
          aliasName: $_aliasNameGenerator(db.vaults.id, db.invitations.vaultId));

  $$InvitationsTableProcessedTableManager get invitationsRefs {
    final manager = $$InvitationsTableTableManager($_db, $_db.invitations)
        .filter((f) => f.vaultId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_invitationsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$DistributionsTable, List<DistributionRow>> _distributionsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.distributions,
          aliasName: $_aliasNameGenerator(db.vaults.id, db.distributions.vaultId));

  $$DistributionsTableProcessedTableManager get distributionsRefs {
    final manager = $$DistributionsTableTableManager($_db, $_db.distributions)
        .filter((f) => f.vaultId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_distributionsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$HeldSharesTable, List<HeldShareRow>> _heldSharesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.heldShares,
          aliasName: $_aliasNameGenerator(db.vaults.id, db.heldShares.vaultId));

  $$HeldSharesTableProcessedTableManager get heldSharesRefs {
    final manager = $$HeldSharesTableTableManager($_db, $_db.heldShares)
        .filter((f) => f.vaultId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_heldSharesRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$RecoveryRequestsTable, List<RecoveryRequestRow>>
      _recoveryRequestsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.recoveryRequests,
              aliasName: $_aliasNameGenerator(db.vaults.id, db.recoveryRequests.vaultId));

  $$RecoveryRequestsTableProcessedTableManager get recoveryRequestsRefs {
    final manager = $$RecoveryRequestsTableTableManager($_db, $_db.recoveryRequests)
        .filter((f) => f.vaultId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_recoveryRequestsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$OutboxTable, List<OutboxRow>> _outboxRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.outbox,
          aliasName: $_aliasNameGenerator(db.vaults.id, db.outbox.vaultId));

  $$OutboxTableProcessedTableManager get outboxRefs {
    final manager = $$OutboxTableTableManager($_db, $_db.outbox)
        .filter((f) => f.vaultId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_outboxRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$VaultsTableFilterComposer extends Composer<_$AppDatabase, $VaultsTable> {
  $$VaultsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ownerPubkey =>
      $composableBuilder(column: $table.ownerPubkey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ownerName =>
      $composableBuilder(column: $table.ownerName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get threshold =>
      $composableBuilder(column: $table.threshold, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get primeMod =>
      $composableBuilder(column: $table.primeMod, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalShares =>
      $composableBuilder(column: $table.totalShares, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get currentDistributionVersion => $composableBuilder(
      column: $table.currentDistributionVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get instructions =>
      $composableBuilder(column: $table.instructions, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get pushEnabled =>
      $composableBuilder(column: $table.pushEnabled, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get archivedAt =>
      $composableBuilder(column: $table.archivedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get archivedReason =>
      $composableBuilder(column: $table.archivedReason, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastSyncedAt =>
      $composableBuilder(column: $table.lastSyncedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  Expression<bool> vaultRelaysRefs(
      Expression<bool> Function($$VaultRelaysTableFilterComposer f) f) {
    final $$VaultRelaysTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.vaultRelays,
        getReferencedColumn: (t) => t.vaultId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$VaultRelaysTableFilterComposer(
              $db: $db,
              $table: $db.vaultRelays,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
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
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$OwnedVaultsTableFilterComposer(
              $db: $db,
              $table: $db.ownedVaults,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> stewardsRefs(Expression<bool> Function($$StewardsTableFilterComposer f) f) {
    final $$StewardsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.stewards,
        getReferencedColumn: (t) => t.vaultId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$StewardsTableFilterComposer(
              $db: $db,
              $table: $db.stewards,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> invitationsRefs(
      Expression<bool> Function($$InvitationsTableFilterComposer f) f) {
    final $$InvitationsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.invitations,
        getReferencedColumn: (t) => t.vaultId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$InvitationsTableFilterComposer(
              $db: $db,
              $table: $db.invitations,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
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
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$DistributionsTableFilterComposer(
              $db: $db,
              $table: $db.distributions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> heldSharesRefs(Expression<bool> Function($$HeldSharesTableFilterComposer f) f) {
    final $$HeldSharesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.heldShares,
        getReferencedColumn: (t) => t.vaultId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$HeldSharesTableFilterComposer(
              $db: $db,
              $table: $db.heldShares,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> recoveryRequestsRefs(
      Expression<bool> Function($$RecoveryRequestsTableFilterComposer f) f) {
    final $$RecoveryRequestsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.recoveryRequests,
        getReferencedColumn: (t) => t.vaultId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$RecoveryRequestsTableFilterComposer(
              $db: $db,
              $table: $db.recoveryRequests,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> outboxRefs(Expression<bool> Function($$OutboxTableFilterComposer f) f) {
    final $$OutboxTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.outbox,
        getReferencedColumn: (t) => t.vaultId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$OutboxTableFilterComposer(
              $db: $db,
              $table: $db.outbox,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$VaultsTableOrderingComposer extends Composer<_$AppDatabase, $VaultsTable> {
  $$VaultsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ownerPubkey =>
      $composableBuilder(column: $table.ownerPubkey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ownerName =>
      $composableBuilder(column: $table.ownerName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get threshold =>
      $composableBuilder(column: $table.threshold, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get primeMod =>
      $composableBuilder(column: $table.primeMod, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalShares =>
      $composableBuilder(column: $table.totalShares, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get currentDistributionVersion => $composableBuilder(
      column: $table.currentDistributionVersion, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get instructions =>
      $composableBuilder(column: $table.instructions, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get pushEnabled =>
      $composableBuilder(column: $table.pushEnabled, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get archivedAt =>
      $composableBuilder(column: $table.archivedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get archivedReason => $composableBuilder(
      column: $table.archivedReason, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastSyncedAt =>
      $composableBuilder(column: $table.lastSyncedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$VaultsTableAnnotationComposer extends Composer<_$AppDatabase, $VaultsTable> {
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

  GeneratedColumn<String> get ownerPubkey =>
      $composableBuilder(column: $table.ownerPubkey, builder: (column) => column);

  GeneratedColumn<String> get ownerName =>
      $composableBuilder(column: $table.ownerName, builder: (column) => column);

  GeneratedColumn<int> get threshold =>
      $composableBuilder(column: $table.threshold, builder: (column) => column);

  GeneratedColumn<String> get primeMod =>
      $composableBuilder(column: $table.primeMod, builder: (column) => column);

  GeneratedColumn<int> get totalShares =>
      $composableBuilder(column: $table.totalShares, builder: (column) => column);

  GeneratedColumn<int> get currentDistributionVersion =>
      $composableBuilder(column: $table.currentDistributionVersion, builder: (column) => column);

  GeneratedColumn<String> get instructions =>
      $composableBuilder(column: $table.instructions, builder: (column) => column);

  GeneratedColumn<bool> get pushEnabled =>
      $composableBuilder(column: $table.pushEnabled, builder: (column) => column);

  GeneratedColumn<int> get archivedAt =>
      $composableBuilder(column: $table.archivedAt, builder: (column) => column);

  GeneratedColumn<String> get archivedReason =>
      $composableBuilder(column: $table.archivedReason, builder: (column) => column);

  GeneratedColumn<int> get lastSyncedAt =>
      $composableBuilder(column: $table.lastSyncedAt, builder: (column) => column);

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
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$VaultRelaysTableAnnotationComposer(
              $db: $db,
              $table: $db.vaultRelays,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
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
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$OwnedVaultsTableAnnotationComposer(
              $db: $db,
              $table: $db.ownedVaults,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
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
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$StewardsTableAnnotationComposer(
              $db: $db,
              $table: $db.stewards,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> invitationsRefs<T extends Object>(
      Expression<T> Function($$InvitationsTableAnnotationComposer a) f) {
    final $$InvitationsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.invitations,
        getReferencedColumn: (t) => t.vaultId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$InvitationsTableAnnotationComposer(
              $db: $db,
              $table: $db.invitations,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
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
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$DistributionsTableAnnotationComposer(
              $db: $db,
              $table: $db.distributions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> heldSharesRefs<T extends Object>(
      Expression<T> Function($$HeldSharesTableAnnotationComposer a) f) {
    final $$HeldSharesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.heldShares,
        getReferencedColumn: (t) => t.vaultId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$HeldSharesTableAnnotationComposer(
              $db: $db,
              $table: $db.heldShares,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> recoveryRequestsRefs<T extends Object>(
      Expression<T> Function($$RecoveryRequestsTableAnnotationComposer a) f) {
    final $$RecoveryRequestsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.recoveryRequests,
        getReferencedColumn: (t) => t.vaultId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$RecoveryRequestsTableAnnotationComposer(
              $db: $db,
              $table: $db.recoveryRequests,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> outboxRefs<T extends Object>(
      Expression<T> Function($$OutboxTableAnnotationComposer a) f) {
    final $$OutboxTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.outbox,
        getReferencedColumn: (t) => t.vaultId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$OutboxTableAnnotationComposer(
              $db: $db,
              $table: $db.outbox,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
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
        bool invitationsRefs,
        bool distributionsRefs,
        bool heldSharesRefs,
        bool recoveryRequestsRefs,
        bool outboxRefs})> {
  $$VaultsTableTableManager(_$AppDatabase db, $VaultsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$VaultsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$VaultsTableOrderingComposer($db: db, $table: table),
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
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable(table), $$VaultsTableReferences(db, table, e))).toList(),
          prefetchHooksCallback: (
              {vaultRelaysRefs = false,
              ownedVaultsRefs = false,
              stewardsRefs = false,
              invitationsRefs = false,
              distributionsRefs = false,
              heldSharesRefs = false,
              recoveryRequestsRefs = false,
              outboxRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (vaultRelaysRefs) db.vaultRelays,
                if (ownedVaultsRefs) db.ownedVaults,
                if (stewardsRefs) db.stewards,
                if (invitationsRefs) db.invitations,
                if (distributionsRefs) db.distributions,
                if (heldSharesRefs) db.heldShares,
                if (recoveryRequestsRefs) db.recoveryRequests,
                if (outboxRefs) db.outbox
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (vaultRelaysRefs)
                    await $_getPrefetchedData<VaultRow, $VaultsTable, VaultRelayRow>(
                        currentTable: table,
                        referencedTable: $$VaultsTableReferences._vaultRelaysRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$VaultsTableReferences(db, table, p0).vaultRelaysRefs,
                        referencedItemsForCurrentItem: (item, referencedItems) =>
                            referencedItems.where((e) => e.vaultId == item.id),
                        typedResults: items),
                  if (ownedVaultsRefs)
                    await $_getPrefetchedData<VaultRow, $VaultsTable, OwnedVaultRow>(
                        currentTable: table,
                        referencedTable: $$VaultsTableReferences._ownedVaultsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$VaultsTableReferences(db, table, p0).ownedVaultsRefs,
                        referencedItemsForCurrentItem: (item, referencedItems) =>
                            referencedItems.where((e) => e.vaultId == item.id),
                        typedResults: items),
                  if (stewardsRefs)
                    await $_getPrefetchedData<VaultRow, $VaultsTable, StewardRow>(
                        currentTable: table,
                        referencedTable: $$VaultsTableReferences._stewardsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$VaultsTableReferences(db, table, p0).stewardsRefs,
                        referencedItemsForCurrentItem: (item, referencedItems) =>
                            referencedItems.where((e) => e.vaultId == item.id),
                        typedResults: items),
                  if (invitationsRefs)
                    await $_getPrefetchedData<VaultRow, $VaultsTable, InvitationRow>(
                        currentTable: table,
                        referencedTable: $$VaultsTableReferences._invitationsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$VaultsTableReferences(db, table, p0).invitationsRefs,
                        referencedItemsForCurrentItem: (item, referencedItems) =>
                            referencedItems.where((e) => e.vaultId == item.id),
                        typedResults: items),
                  if (distributionsRefs)
                    await $_getPrefetchedData<VaultRow, $VaultsTable, DistributionRow>(
                        currentTable: table,
                        referencedTable: $$VaultsTableReferences._distributionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$VaultsTableReferences(db, table, p0).distributionsRefs,
                        referencedItemsForCurrentItem: (item, referencedItems) =>
                            referencedItems.where((e) => e.vaultId == item.id),
                        typedResults: items),
                  if (heldSharesRefs)
                    await $_getPrefetchedData<VaultRow, $VaultsTable, HeldShareRow>(
                        currentTable: table,
                        referencedTable: $$VaultsTableReferences._heldSharesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$VaultsTableReferences(db, table, p0).heldSharesRefs,
                        referencedItemsForCurrentItem: (item, referencedItems) =>
                            referencedItems.where((e) => e.vaultId == item.id),
                        typedResults: items),
                  if (recoveryRequestsRefs)
                    await $_getPrefetchedData<VaultRow, $VaultsTable, RecoveryRequestRow>(
                        currentTable: table,
                        referencedTable: $$VaultsTableReferences._recoveryRequestsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$VaultsTableReferences(db, table, p0).recoveryRequestsRefs,
                        referencedItemsForCurrentItem: (item, referencedItems) =>
                            referencedItems.where((e) => e.vaultId == item.id),
                        typedResults: items),
                  if (outboxRefs)
                    await $_getPrefetchedData<VaultRow, $VaultsTable, OutboxRow>(
                        currentTable: table,
                        referencedTable: $$VaultsTableReferences._outboxRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$VaultsTableReferences(db, table, p0).outboxRefs,
                        referencedItemsForCurrentItem: (item, referencedItems) =>
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
        bool invitationsRefs,
        bool distributionsRefs,
        bool heldSharesRefs,
        bool recoveryRequestsRefs,
        bool outboxRefs})>;
typedef $$VaultRelaysTableCreateCompanionBuilder = VaultRelaysCompanion Function({
  required String id,
  required String vaultId,
  required String url,
  required String role,
  required int addedAt,
  Value<int> rowid,
});
typedef $$VaultRelaysTableUpdateCompanionBuilder = VaultRelaysCompanion Function({
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

  static $VaultsTable _vaultIdTable(_$AppDatabase db) =>
      db.vaults.createAlias($_aliasNameGenerator(db.vaultRelays.vaultId, db.vaults.id));

  $$VaultsTableProcessedTableManager get vaultId {
    final $_column = $_itemColumn<String>('vault_id')!;

    final manager =
        $$VaultsTableTableManager($_db, $_db.vaults).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_vaultIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$VaultRelaysTableFilterComposer extends Composer<_$AppDatabase, $VaultRelaysTable> {
  $$VaultRelaysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => ColumnFilters(column));

  $$VaultsTableFilterComposer get vaultId {
    final $$VaultsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.vaultId,
        referencedTable: $db.vaults,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$VaultsTableFilterComposer(
              $db: $db,
              $table: $db.vaults,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$VaultRelaysTableOrderingComposer extends Composer<_$AppDatabase, $VaultRelaysTable> {
  $$VaultRelaysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => ColumnOrderings(column));

  $$VaultsTableOrderingComposer get vaultId {
    final $$VaultsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.vaultId,
        referencedTable: $db.vaults,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$VaultsTableOrderingComposer(
              $db: $db,
              $table: $db.vaults,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$VaultRelaysTableAnnotationComposer extends Composer<_$AppDatabase, $VaultRelaysTable> {
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
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$VaultsTableAnnotationComposer(
              $db: $db,
              $table: $db.vaults,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
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
          createFilteringComposer: () => $$VaultRelaysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$VaultRelaysTableOrderingComposer($db: db, $table: table),
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
              .map((e) => (e.readTable(table), $$VaultRelaysTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({vaultId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<dynamic, dynamic, dynamic, dynamic, dynamic, dynamic,
                      dynamic, dynamic, dynamic, dynamic, dynamic>>(state) {
                if (vaultId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.vaultId,
                    referencedTable: $$VaultRelaysTableReferences._vaultIdTable(db),
                    referencedColumn: $$VaultRelaysTableReferences._vaultIdTable(db).id,
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
typedef $$OwnedVaultsTableCreateCompanionBuilder = OwnedVaultsCompanion Function({
  required String vaultId,
  required String content,
  required Uint8List contentHmac,
  required int createdBySelfAt,
  Value<int> rowid,
});
typedef $$OwnedVaultsTableUpdateCompanionBuilder = OwnedVaultsCompanion Function({
  Value<String> vaultId,
  Value<String> content,
  Value<Uint8List> contentHmac,
  Value<int> createdBySelfAt,
  Value<int> rowid,
});

final class $$OwnedVaultsTableReferences
    extends BaseReferences<_$AppDatabase, $OwnedVaultsTable, OwnedVaultRow> {
  $$OwnedVaultsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $VaultsTable _vaultIdTable(_$AppDatabase db) =>
      db.vaults.createAlias($_aliasNameGenerator(db.ownedVaults.vaultId, db.vaults.id));

  $$VaultsTableProcessedTableManager get vaultId {
    final $_column = $_itemColumn<String>('vault_id')!;

    final manager =
        $$VaultsTableTableManager($_db, $_db.vaults).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_vaultIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$OwnedVaultsTableFilterComposer extends Composer<_$AppDatabase, $OwnedVaultsTable> {
  $$OwnedVaultsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<Uint8List> get contentHmac =>
      $composableBuilder(column: $table.contentHmac, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdBySelfAt => $composableBuilder(
      column: $table.createdBySelfAt, builder: (column) => ColumnFilters(column));

  $$VaultsTableFilterComposer get vaultId {
    final $$VaultsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.vaultId,
        referencedTable: $db.vaults,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$VaultsTableFilterComposer(
              $db: $db,
              $table: $db.vaults,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$OwnedVaultsTableOrderingComposer extends Composer<_$AppDatabase, $OwnedVaultsTable> {
  $$OwnedVaultsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<Uint8List> get contentHmac =>
      $composableBuilder(column: $table.contentHmac, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdBySelfAt => $composableBuilder(
      column: $table.createdBySelfAt, builder: (column) => ColumnOrderings(column));

  $$VaultsTableOrderingComposer get vaultId {
    final $$VaultsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.vaultId,
        referencedTable: $db.vaults,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$VaultsTableOrderingComposer(
              $db: $db,
              $table: $db.vaults,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$OwnedVaultsTableAnnotationComposer extends Composer<_$AppDatabase, $OwnedVaultsTable> {
  $$OwnedVaultsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<Uint8List> get contentHmac =>
      $composableBuilder(column: $table.contentHmac, builder: (column) => column);

  GeneratedColumn<int> get createdBySelfAt =>
      $composableBuilder(column: $table.createdBySelfAt, builder: (column) => column);

  $$VaultsTableAnnotationComposer get vaultId {
    final $$VaultsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.vaultId,
        referencedTable: $db.vaults,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$VaultsTableAnnotationComposer(
              $db: $db,
              $table: $db.vaults,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
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
          createFilteringComposer: () => $$OwnedVaultsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$OwnedVaultsTableOrderingComposer($db: db, $table: table),
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
              .map((e) => (e.readTable(table), $$OwnedVaultsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({vaultId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<dynamic, dynamic, dynamic, dynamic, dynamic, dynamic,
                      dynamic, dynamic, dynamic, dynamic, dynamic>>(state) {
                if (vaultId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.vaultId,
                    referencedTable: $$OwnedVaultsTableReferences._vaultIdTable(db),
                    referencedColumn: $$OwnedVaultsTableReferences._vaultIdTable(db).id,
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

  static $VaultsTable _vaultIdTable(_$AppDatabase db) =>
      db.vaults.createAlias($_aliasNameGenerator(db.stewards.vaultId, db.vaults.id));

  $$VaultsTableProcessedTableManager get vaultId {
    final $_column = $_itemColumn<String>('vault_id')!;

    final manager =
        $$VaultsTableTableManager($_db, $_db.vaults).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_vaultIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$InvitationsTable, List<InvitationRow>> _invitationsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.invitations,
          aliasName: $_aliasNameGenerator(db.stewards.id, db.invitations.stewardId));

  $$InvitationsTableProcessedTableManager get invitationsRefs {
    final manager = $$InvitationsTableTableManager($_db, $_db.invitations)
        .filter((f) => f.stewardId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_invitationsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$DistributionSharesTable, List<DistributionShareRow>>
      _distributionSharesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.distributionShares,
              aliasName: $_aliasNameGenerator(db.stewards.id, db.distributionShares.stewardId));

  $$DistributionSharesTableProcessedTableManager get distributionSharesRefs {
    final manager = $$DistributionSharesTableTableManager($_db, $_db.distributionShares)
        .filter((f) => f.stewardId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_distributionSharesRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$RecoveryResponsesTable, List<RecoveryResponseRow>>
      _recoveryResponsesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.recoveryResponses,
              aliasName: $_aliasNameGenerator(db.stewards.id, db.recoveryResponses.stewardId));

  $$RecoveryResponsesTableProcessedTableManager get recoveryResponsesRefs {
    final manager = $$RecoveryResponsesTableTableManager($_db, $_db.recoveryResponses)
        .filter((f) => f.stewardId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_recoveryResponsesRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$StewardsTableFilterComposer extends Composer<_$AppDatabase, $StewardsTable> {
  $$StewardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get shareIndex =>
      $composableBuilder(column: $table.shareIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pubkey =>
      $composableBuilder(column: $table.pubkey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get contactInfo =>
      $composableBuilder(column: $table.contactInfo, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isOwner =>
      $composableBuilder(column: $table.isOwner, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get joinedAt =>
      $composableBuilder(column: $table.joinedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get leftAt =>
      $composableBuilder(column: $table.leftAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get removalReason =>
      $composableBuilder(column: $table.removalReason, builder: (column) => ColumnFilters(column));

  $$VaultsTableFilterComposer get vaultId {
    final $$VaultsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.vaultId,
        referencedTable: $db.vaults,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$VaultsTableFilterComposer(
              $db: $db,
              $table: $db.vaults,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> invitationsRefs(
      Expression<bool> Function($$InvitationsTableFilterComposer f) f) {
    final $$InvitationsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.invitations,
        getReferencedColumn: (t) => t.stewardId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$InvitationsTableFilterComposer(
              $db: $db,
              $table: $db.invitations,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> distributionSharesRefs(
      Expression<bool> Function($$DistributionSharesTableFilterComposer f) f) {
    final $$DistributionSharesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.distributionShares,
        getReferencedColumn: (t) => t.stewardId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$DistributionSharesTableFilterComposer(
              $db: $db,
              $table: $db.distributionShares,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> recoveryResponsesRefs(
      Expression<bool> Function($$RecoveryResponsesTableFilterComposer f) f) {
    final $$RecoveryResponsesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.recoveryResponses,
        getReferencedColumn: (t) => t.stewardId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$RecoveryResponsesTableFilterComposer(
              $db: $db,
              $table: $db.recoveryResponses,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$StewardsTableOrderingComposer extends Composer<_$AppDatabase, $StewardsTable> {
  $$StewardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get shareIndex =>
      $composableBuilder(column: $table.shareIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pubkey =>
      $composableBuilder(column: $table.pubkey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get contactInfo =>
      $composableBuilder(column: $table.contactInfo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isOwner =>
      $composableBuilder(column: $table.isOwner, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get joinedAt =>
      $composableBuilder(column: $table.joinedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get leftAt =>
      $composableBuilder(column: $table.leftAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get removalReason => $composableBuilder(
      column: $table.removalReason, builder: (column) => ColumnOrderings(column));

  $$VaultsTableOrderingComposer get vaultId {
    final $$VaultsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.vaultId,
        referencedTable: $db.vaults,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$VaultsTableOrderingComposer(
              $db: $db,
              $table: $db.vaults,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$StewardsTableAnnotationComposer extends Composer<_$AppDatabase, $StewardsTable> {
  $$StewardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get shareIndex =>
      $composableBuilder(column: $table.shareIndex, builder: (column) => column);

  GeneratedColumn<String> get pubkey =>
      $composableBuilder(column: $table.pubkey, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get contactInfo =>
      $composableBuilder(column: $table.contactInfo, builder: (column) => column);

  GeneratedColumn<bool> get isOwner =>
      $composableBuilder(column: $table.isOwner, builder: (column) => column);

  GeneratedColumn<int> get joinedAt =>
      $composableBuilder(column: $table.joinedAt, builder: (column) => column);

  GeneratedColumn<int> get leftAt =>
      $composableBuilder(column: $table.leftAt, builder: (column) => column);

  GeneratedColumn<String> get removalReason =>
      $composableBuilder(column: $table.removalReason, builder: (column) => column);

  $$VaultsTableAnnotationComposer get vaultId {
    final $$VaultsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.vaultId,
        referencedTable: $db.vaults,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$VaultsTableAnnotationComposer(
              $db: $db,
              $table: $db.vaults,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> invitationsRefs<T extends Object>(
      Expression<T> Function($$InvitationsTableAnnotationComposer a) f) {
    final $$InvitationsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.invitations,
        getReferencedColumn: (t) => t.stewardId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$InvitationsTableAnnotationComposer(
              $db: $db,
              $table: $db.invitations,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> distributionSharesRefs<T extends Object>(
      Expression<T> Function($$DistributionSharesTableAnnotationComposer a) f) {
    final $$DistributionSharesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.distributionShares,
        getReferencedColumn: (t) => t.stewardId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$DistributionSharesTableAnnotationComposer(
              $db: $db,
              $table: $db.distributionShares,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> recoveryResponsesRefs<T extends Object>(
      Expression<T> Function($$RecoveryResponsesTableAnnotationComposer a) f) {
    final $$RecoveryResponsesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.recoveryResponses,
        getReferencedColumn: (t) => t.stewardId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$RecoveryResponsesTableAnnotationComposer(
              $db: $db,
              $table: $db.recoveryResponses,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
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
    PrefetchHooks Function(
        {bool vaultId,
        bool invitationsRefs,
        bool distributionSharesRefs,
        bool recoveryResponsesRefs})> {
  $$StewardsTableTableManager(_$AppDatabase db, $StewardsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$StewardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$StewardsTableOrderingComposer($db: db, $table: table),
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
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable(table), $$StewardsTableReferences(db, table, e))).toList(),
          prefetchHooksCallback: (
              {vaultId = false,
              invitationsRefs = false,
              distributionSharesRefs = false,
              recoveryResponsesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (invitationsRefs) db.invitations,
                if (distributionSharesRefs) db.distributionShares,
                if (recoveryResponsesRefs) db.recoveryResponses
              ],
              addJoins: <
                  T extends TableManagerState<dynamic, dynamic, dynamic, dynamic, dynamic, dynamic,
                      dynamic, dynamic, dynamic, dynamic, dynamic>>(state) {
                if (vaultId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.vaultId,
                    referencedTable: $$StewardsTableReferences._vaultIdTable(db),
                    referencedColumn: $$StewardsTableReferences._vaultIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (invitationsRefs)
                    await $_getPrefetchedData<StewardRow, $StewardsTable, InvitationRow>(
                        currentTable: table,
                        referencedTable: $$StewardsTableReferences._invitationsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$StewardsTableReferences(db, table, p0).invitationsRefs,
                        referencedItemsForCurrentItem: (item, referencedItems) =>
                            referencedItems.where((e) => e.stewardId == item.id),
                        typedResults: items),
                  if (distributionSharesRefs)
                    await $_getPrefetchedData<StewardRow, $StewardsTable, DistributionShareRow>(
                        currentTable: table,
                        referencedTable: $$StewardsTableReferences._distributionSharesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$StewardsTableReferences(db, table, p0).distributionSharesRefs,
                        referencedItemsForCurrentItem: (item, referencedItems) =>
                            referencedItems.where((e) => e.stewardId == item.id),
                        typedResults: items),
                  if (recoveryResponsesRefs)
                    await $_getPrefetchedData<StewardRow, $StewardsTable, RecoveryResponseRow>(
                        currentTable: table,
                        referencedTable: $$StewardsTableReferences._recoveryResponsesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$StewardsTableReferences(db, table, p0).recoveryResponsesRefs,
                        referencedItemsForCurrentItem: (item, referencedItems) =>
                            referencedItems.where((e) => e.stewardId == item.id),
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
    PrefetchHooks Function(
        {bool vaultId,
        bool invitationsRefs,
        bool distributionSharesRefs,
        bool recoveryResponsesRefs})>;
typedef $$InvitationsTableCreateCompanionBuilder = InvitationsCompanion Function({
  required String code,
  required String vaultId,
  Value<String?> stewardId,
  required String payload,
  required int createdAt,
  Value<int?> expiresAt,
  Value<int?> acceptedAt,
  Value<String?> acceptedByPubkey,
  Value<int?> revokedAt,
  Value<int> rowid,
});
typedef $$InvitationsTableUpdateCompanionBuilder = InvitationsCompanion Function({
  Value<String> code,
  Value<String> vaultId,
  Value<String?> stewardId,
  Value<String> payload,
  Value<int> createdAt,
  Value<int?> expiresAt,
  Value<int?> acceptedAt,
  Value<String?> acceptedByPubkey,
  Value<int?> revokedAt,
  Value<int> rowid,
});

final class $$InvitationsTableReferences
    extends BaseReferences<_$AppDatabase, $InvitationsTable, InvitationRow> {
  $$InvitationsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $VaultsTable _vaultIdTable(_$AppDatabase db) =>
      db.vaults.createAlias($_aliasNameGenerator(db.invitations.vaultId, db.vaults.id));

  $$VaultsTableProcessedTableManager get vaultId {
    final $_column = $_itemColumn<String>('vault_id')!;

    final manager =
        $$VaultsTableTableManager($_db, $_db.vaults).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_vaultIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static $StewardsTable _stewardIdTable(_$AppDatabase db) =>
      db.stewards.createAlias($_aliasNameGenerator(db.invitations.stewardId, db.stewards.id));

  $$StewardsTableProcessedTableManager? get stewardId {
    final $_column = $_itemColumn<String>('steward_id');
    if ($_column == null) return null;
    final manager =
        $$StewardsTableTableManager($_db, $_db.stewards).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_stewardIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$InvitationsTableFilterComposer extends Composer<_$AppDatabase, $InvitationsTable> {
  $$InvitationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get acceptedAt =>
      $composableBuilder(column: $table.acceptedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get acceptedByPubkey => $composableBuilder(
      column: $table.acceptedByPubkey, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get revokedAt =>
      $composableBuilder(column: $table.revokedAt, builder: (column) => ColumnFilters(column));

  $$VaultsTableFilterComposer get vaultId {
    final $$VaultsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.vaultId,
        referencedTable: $db.vaults,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$VaultsTableFilterComposer(
              $db: $db,
              $table: $db.vaults,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
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
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$StewardsTableFilterComposer(
              $db: $db,
              $table: $db.stewards,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$InvitationsTableOrderingComposer extends Composer<_$AppDatabase, $InvitationsTable> {
  $$InvitationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get acceptedAt =>
      $composableBuilder(column: $table.acceptedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get acceptedByPubkey => $composableBuilder(
      column: $table.acceptedByPubkey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get revokedAt =>
      $composableBuilder(column: $table.revokedAt, builder: (column) => ColumnOrderings(column));

  $$VaultsTableOrderingComposer get vaultId {
    final $$VaultsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.vaultId,
        referencedTable: $db.vaults,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$VaultsTableOrderingComposer(
              $db: $db,
              $table: $db.vaults,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
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
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$StewardsTableOrderingComposer(
              $db: $db,
              $table: $db.stewards,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$InvitationsTableAnnotationComposer extends Composer<_$AppDatabase, $InvitationsTable> {
  $$InvitationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<int> get acceptedAt =>
      $composableBuilder(column: $table.acceptedAt, builder: (column) => column);

  GeneratedColumn<String> get acceptedByPubkey =>
      $composableBuilder(column: $table.acceptedByPubkey, builder: (column) => column);

  GeneratedColumn<int> get revokedAt =>
      $composableBuilder(column: $table.revokedAt, builder: (column) => column);

  $$VaultsTableAnnotationComposer get vaultId {
    final $$VaultsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.vaultId,
        referencedTable: $db.vaults,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$VaultsTableAnnotationComposer(
              $db: $db,
              $table: $db.vaults,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
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
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$StewardsTableAnnotationComposer(
              $db: $db,
              $table: $db.stewards,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$InvitationsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $InvitationsTable,
    InvitationRow,
    $$InvitationsTableFilterComposer,
    $$InvitationsTableOrderingComposer,
    $$InvitationsTableAnnotationComposer,
    $$InvitationsTableCreateCompanionBuilder,
    $$InvitationsTableUpdateCompanionBuilder,
    (InvitationRow, $$InvitationsTableReferences),
    InvitationRow,
    PrefetchHooks Function({bool vaultId, bool stewardId})> {
  $$InvitationsTableTableManager(_$AppDatabase db, $InvitationsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$InvitationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$InvitationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InvitationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> code = const Value.absent(),
            Value<String> vaultId = const Value.absent(),
            Value<String?> stewardId = const Value.absent(),
            Value<String> payload = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int?> expiresAt = const Value.absent(),
            Value<int?> acceptedAt = const Value.absent(),
            Value<String?> acceptedByPubkey = const Value.absent(),
            Value<int?> revokedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              InvitationsCompanion(
            code: code,
            vaultId: vaultId,
            stewardId: stewardId,
            payload: payload,
            createdAt: createdAt,
            expiresAt: expiresAt,
            acceptedAt: acceptedAt,
            acceptedByPubkey: acceptedByPubkey,
            revokedAt: revokedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String code,
            required String vaultId,
            Value<String?> stewardId = const Value.absent(),
            required String payload,
            required int createdAt,
            Value<int?> expiresAt = const Value.absent(),
            Value<int?> acceptedAt = const Value.absent(),
            Value<String?> acceptedByPubkey = const Value.absent(),
            Value<int?> revokedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              InvitationsCompanion.insert(
            code: code,
            vaultId: vaultId,
            stewardId: stewardId,
            payload: payload,
            createdAt: createdAt,
            expiresAt: expiresAt,
            acceptedAt: acceptedAt,
            acceptedByPubkey: acceptedByPubkey,
            revokedAt: revokedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), $$InvitationsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({vaultId = false, stewardId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<dynamic, dynamic, dynamic, dynamic, dynamic, dynamic,
                      dynamic, dynamic, dynamic, dynamic, dynamic>>(state) {
                if (vaultId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.vaultId,
                    referencedTable: $$InvitationsTableReferences._vaultIdTable(db),
                    referencedColumn: $$InvitationsTableReferences._vaultIdTable(db).id,
                  ) as T;
                }
                if (stewardId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.stewardId,
                    referencedTable: $$InvitationsTableReferences._stewardIdTable(db),
                    referencedColumn: $$InvitationsTableReferences._stewardIdTable(db).id,
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

typedef $$InvitationsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $InvitationsTable,
    InvitationRow,
    $$InvitationsTableFilterComposer,
    $$InvitationsTableOrderingComposer,
    $$InvitationsTableAnnotationComposer,
    $$InvitationsTableCreateCompanionBuilder,
    $$InvitationsTableUpdateCompanionBuilder,
    (InvitationRow, $$InvitationsTableReferences),
    InvitationRow,
    PrefetchHooks Function({bool vaultId, bool stewardId})>;
typedef $$DistributionsTableCreateCompanionBuilder = DistributionsCompanion Function({
  required String id,
  required String vaultId,
  required int version,
  required int createdAt,
  Value<int?> completedAt,
  required Uint8List contentHmac,
  Value<int> rowid,
});
typedef $$DistributionsTableUpdateCompanionBuilder = DistributionsCompanion Function({
  Value<String> id,
  Value<String> vaultId,
  Value<int> version,
  Value<int> createdAt,
  Value<int?> completedAt,
  Value<Uint8List> contentHmac,
  Value<int> rowid,
});

final class $$DistributionsTableReferences
    extends BaseReferences<_$AppDatabase, $DistributionsTable, DistributionRow> {
  $$DistributionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $VaultsTable _vaultIdTable(_$AppDatabase db) =>
      db.vaults.createAlias($_aliasNameGenerator(db.distributions.vaultId, db.vaults.id));

  $$VaultsTableProcessedTableManager get vaultId {
    final $_column = $_itemColumn<String>('vault_id')!;

    final manager =
        $$VaultsTableTableManager($_db, $_db.vaults).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_vaultIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$DistributionSharesTable, List<DistributionShareRow>>
      _distributionSharesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.distributionShares,
              aliasName:
                  $_aliasNameGenerator(db.distributions.id, db.distributionShares.distributionId));

  $$DistributionSharesTableProcessedTableManager get distributionSharesRefs {
    final manager = $$DistributionSharesTableTableManager($_db, $_db.distributionShares)
        .filter((f) => f.distributionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_distributionSharesRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$DistributionsTableFilterComposer extends Composer<_$AppDatabase, $DistributionsTable> {
  $$DistributionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get completedAt =>
      $composableBuilder(column: $table.completedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<Uint8List> get contentHmac =>
      $composableBuilder(column: $table.contentHmac, builder: (column) => ColumnFilters(column));

  $$VaultsTableFilterComposer get vaultId {
    final $$VaultsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.vaultId,
        referencedTable: $db.vaults,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$VaultsTableFilterComposer(
              $db: $db,
              $table: $db.vaults,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
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
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$DistributionSharesTableFilterComposer(
              $db: $db,
              $table: $db.distributionShares,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$DistributionsTableOrderingComposer extends Composer<_$AppDatabase, $DistributionsTable> {
  $$DistributionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get completedAt =>
      $composableBuilder(column: $table.completedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<Uint8List> get contentHmac =>
      $composableBuilder(column: $table.contentHmac, builder: (column) => ColumnOrderings(column));

  $$VaultsTableOrderingComposer get vaultId {
    final $$VaultsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.vaultId,
        referencedTable: $db.vaults,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$VaultsTableOrderingComposer(
              $db: $db,
              $table: $db.vaults,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DistributionsTableAnnotationComposer extends Composer<_$AppDatabase, $DistributionsTable> {
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

  GeneratedColumn<int> get completedAt =>
      $composableBuilder(column: $table.completedAt, builder: (column) => column);

  GeneratedColumn<Uint8List> get contentHmac =>
      $composableBuilder(column: $table.contentHmac, builder: (column) => column);

  $$VaultsTableAnnotationComposer get vaultId {
    final $$VaultsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.vaultId,
        referencedTable: $db.vaults,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$VaultsTableAnnotationComposer(
              $db: $db,
              $table: $db.vaults,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> distributionSharesRefs<T extends Object>(
      Expression<T> Function($$DistributionSharesTableAnnotationComposer a) f) {
    final $$DistributionSharesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.distributionShares,
        getReferencedColumn: (t) => t.distributionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$DistributionSharesTableAnnotationComposer(
              $db: $db,
              $table: $db.distributionShares,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
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
          createFilteringComposer: () => $$DistributionsTableFilterComposer($db: db, $table: table),
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
              .map((e) => (e.readTable(table), $$DistributionsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({vaultId = false, distributionSharesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (distributionSharesRefs) db.distributionShares],
              addJoins: <
                  T extends TableManagerState<dynamic, dynamic, dynamic, dynamic, dynamic, dynamic,
                      dynamic, dynamic, dynamic, dynamic, dynamic>>(state) {
                if (vaultId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.vaultId,
                    referencedTable: $$DistributionsTableReferences._vaultIdTable(db),
                    referencedColumn: $$DistributionsTableReferences._vaultIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (distributionSharesRefs)
                    await $_getPrefetchedData<DistributionRow, $DistributionsTable,
                            DistributionShareRow>(
                        currentTable: table,
                        referencedTable:
                            $$DistributionsTableReferences._distributionSharesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$DistributionsTableReferences(db, table, p0).distributionSharesRefs,
                        referencedItemsForCurrentItem: (item, referencedItems) =>
                            referencedItems.where((e) => e.distributionId == item.id),
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
typedef $$DistributionSharesTableCreateCompanionBuilder = DistributionSharesCompanion Function({
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
typedef $$DistributionSharesTableUpdateCompanionBuilder = DistributionSharesCompanion Function({
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

final class $$DistributionSharesTableReferences
    extends BaseReferences<_$AppDatabase, $DistributionSharesTable, DistributionShareRow> {
  $$DistributionSharesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DistributionsTable _distributionIdTable(_$AppDatabase db) => db.distributions
      .createAlias($_aliasNameGenerator(db.distributionShares.distributionId, db.distributions.id));

  $$DistributionsTableProcessedTableManager get distributionId {
    final $_column = $_itemColumn<String>('distribution_id')!;

    final manager = $$DistributionsTableTableManager($_db, $_db.distributions)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_distributionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static $StewardsTable _stewardIdTable(_$AppDatabase db) => db.stewards
      .createAlias($_aliasNameGenerator(db.distributionShares.stewardId, db.stewards.id));

  $$StewardsTableProcessedTableManager get stewardId {
    final $_column = $_itemColumn<String>('steward_id')!;

    final manager =
        $$StewardsTableTableManager($_db, $_db.stewards).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_stewardIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
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
  ColumnFilters<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get giftWrapEventId => $composableBuilder(
      column: $table.giftWrapEventId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sentAt =>
      $composableBuilder(column: $table.sentAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get acknowledgedAt =>
      $composableBuilder(column: $table.acknowledgedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get acknowledgmentEventId => $composableBuilder(
      column: $table.acknowledgmentEventId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get acknowledgmentDistributionVersion => $composableBuilder(
      column: $table.acknowledgmentDistributionVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get acknowledgmentCreatedAt => $composableBuilder(
      column: $table.acknowledgmentCreatedAt, builder: (column) => ColumnFilters(column));

  $$DistributionsTableFilterComposer get distributionId {
    final $$DistributionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.distributionId,
        referencedTable: $db.distributions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$DistributionsTableFilterComposer(
              $db: $db,
              $table: $db.distributions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
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
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$StewardsTableFilterComposer(
              $db: $db,
              $table: $db.stewards,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
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
  ColumnOrderings<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get giftWrapEventId => $composableBuilder(
      column: $table.giftWrapEventId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sentAt =>
      $composableBuilder(column: $table.sentAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get acknowledgedAt => $composableBuilder(
      column: $table.acknowledgedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get acknowledgmentEventId => $composableBuilder(
      column: $table.acknowledgmentEventId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get acknowledgmentDistributionVersion => $composableBuilder(
      column: $table.acknowledgmentDistributionVersion,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get acknowledgmentCreatedAt => $composableBuilder(
      column: $table.acknowledgmentCreatedAt, builder: (column) => ColumnOrderings(column));

  $$DistributionsTableOrderingComposer get distributionId {
    final $$DistributionsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.distributionId,
        referencedTable: $db.distributions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$DistributionsTableOrderingComposer(
              $db: $db,
              $table: $db.distributions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
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
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$StewardsTableOrderingComposer(
              $db: $db,
              $table: $db.stewards,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
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

  GeneratedColumn<String> get giftWrapEventId =>
      $composableBuilder(column: $table.giftWrapEventId, builder: (column) => column);

  GeneratedColumn<int> get sentAt =>
      $composableBuilder(column: $table.sentAt, builder: (column) => column);

  GeneratedColumn<int> get acknowledgedAt =>
      $composableBuilder(column: $table.acknowledgedAt, builder: (column) => column);

  GeneratedColumn<String> get acknowledgmentEventId =>
      $composableBuilder(column: $table.acknowledgmentEventId, builder: (column) => column);

  GeneratedColumn<int> get acknowledgmentDistributionVersion => $composableBuilder(
      column: $table.acknowledgmentDistributionVersion, builder: (column) => column);

  GeneratedColumn<int> get acknowledgmentCreatedAt =>
      $composableBuilder(column: $table.acknowledgmentCreatedAt, builder: (column) => column);

  $$DistributionsTableAnnotationComposer get distributionId {
    final $$DistributionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.distributionId,
        referencedTable: $db.distributions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$DistributionsTableAnnotationComposer(
              $db: $db,
              $table: $db.distributions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
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
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$StewardsTableAnnotationComposer(
              $db: $db,
              $table: $db.stewards,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
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
  $$DistributionSharesTableTableManager(_$AppDatabase db, $DistributionSharesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DistributionSharesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DistributionSharesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DistributionSharesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> distributionId = const Value.absent(),
            Value<String> stewardId = const Value.absent(),
            Value<String> giftWrapEventId = const Value.absent(),
            Value<int?> sentAt = const Value.absent(),
            Value<int?> acknowledgedAt = const Value.absent(),
            Value<String?> acknowledgmentEventId = const Value.absent(),
            Value<int?> acknowledgmentDistributionVersion = const Value.absent(),
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
            acknowledgmentDistributionVersion: acknowledgmentDistributionVersion,
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
            Value<int?> acknowledgmentDistributionVersion = const Value.absent(),
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
            acknowledgmentDistributionVersion: acknowledgmentDistributionVersion,
            acknowledgmentCreatedAt: acknowledgmentCreatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), $$DistributionSharesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({distributionId = false, stewardId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<dynamic, dynamic, dynamic, dynamic, dynamic, dynamic,
                      dynamic, dynamic, dynamic, dynamic, dynamic>>(state) {
                if (distributionId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.distributionId,
                    referencedTable: $$DistributionSharesTableReferences._distributionIdTable(db),
                    referencedColumn:
                        $$DistributionSharesTableReferences._distributionIdTable(db).id,
                  ) as T;
                }
                if (stewardId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.stewardId,
                    referencedTable: $$DistributionSharesTableReferences._stewardIdTable(db),
                    referencedColumn: $$DistributionSharesTableReferences._stewardIdTable(db).id,
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
typedef $$HeldSharesTableCreateCompanionBuilder = HeldSharesCompanion Function({
  required String id,
  required String vaultId,
  required int shareIndex,
  required String sharePayload,
  required int distributionVersion,
  required int receivedAt,
  Value<String?> nostrEventId,
  Value<String?> lastSeenRelay,
  Value<bool> pushEnabled,
  Value<int> rowid,
});
typedef $$HeldSharesTableUpdateCompanionBuilder = HeldSharesCompanion Function({
  Value<String> id,
  Value<String> vaultId,
  Value<int> shareIndex,
  Value<String> sharePayload,
  Value<int> distributionVersion,
  Value<int> receivedAt,
  Value<String?> nostrEventId,
  Value<String?> lastSeenRelay,
  Value<bool> pushEnabled,
  Value<int> rowid,
});

final class $$HeldSharesTableReferences
    extends BaseReferences<_$AppDatabase, $HeldSharesTable, HeldShareRow> {
  $$HeldSharesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $VaultsTable _vaultIdTable(_$AppDatabase db) =>
      db.vaults.createAlias($_aliasNameGenerator(db.heldShares.vaultId, db.vaults.id));

  $$VaultsTableProcessedTableManager get vaultId {
    final $_column = $_itemColumn<String>('vault_id')!;

    final manager =
        $$VaultsTableTableManager($_db, $_db.vaults).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_vaultIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$HeldSharesTableFilterComposer extends Composer<_$AppDatabase, $HeldSharesTable> {
  $$HeldSharesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get shareIndex =>
      $composableBuilder(column: $table.shareIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sharePayload =>
      $composableBuilder(column: $table.sharePayload, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get distributionVersion => $composableBuilder(
      column: $table.distributionVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get receivedAt =>
      $composableBuilder(column: $table.receivedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nostrEventId =>
      $composableBuilder(column: $table.nostrEventId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastSeenRelay =>
      $composableBuilder(column: $table.lastSeenRelay, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get pushEnabled =>
      $composableBuilder(column: $table.pushEnabled, builder: (column) => ColumnFilters(column));

  $$VaultsTableFilterComposer get vaultId {
    final $$VaultsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.vaultId,
        referencedTable: $db.vaults,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$VaultsTableFilterComposer(
              $db: $db,
              $table: $db.vaults,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$HeldSharesTableOrderingComposer extends Composer<_$AppDatabase, $HeldSharesTable> {
  $$HeldSharesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get shareIndex =>
      $composableBuilder(column: $table.shareIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sharePayload =>
      $composableBuilder(column: $table.sharePayload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get distributionVersion => $composableBuilder(
      column: $table.distributionVersion, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get receivedAt =>
      $composableBuilder(column: $table.receivedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nostrEventId =>
      $composableBuilder(column: $table.nostrEventId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastSeenRelay => $composableBuilder(
      column: $table.lastSeenRelay, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get pushEnabled =>
      $composableBuilder(column: $table.pushEnabled, builder: (column) => ColumnOrderings(column));

  $$VaultsTableOrderingComposer get vaultId {
    final $$VaultsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.vaultId,
        referencedTable: $db.vaults,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$VaultsTableOrderingComposer(
              $db: $db,
              $table: $db.vaults,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$HeldSharesTableAnnotationComposer extends Composer<_$AppDatabase, $HeldSharesTable> {
  $$HeldSharesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get shareIndex =>
      $composableBuilder(column: $table.shareIndex, builder: (column) => column);

  GeneratedColumn<String> get sharePayload =>
      $composableBuilder(column: $table.sharePayload, builder: (column) => column);

  GeneratedColumn<int> get distributionVersion =>
      $composableBuilder(column: $table.distributionVersion, builder: (column) => column);

  GeneratedColumn<int> get receivedAt =>
      $composableBuilder(column: $table.receivedAt, builder: (column) => column);

  GeneratedColumn<String> get nostrEventId =>
      $composableBuilder(column: $table.nostrEventId, builder: (column) => column);

  GeneratedColumn<String> get lastSeenRelay =>
      $composableBuilder(column: $table.lastSeenRelay, builder: (column) => column);

  GeneratedColumn<bool> get pushEnabled =>
      $composableBuilder(column: $table.pushEnabled, builder: (column) => column);

  $$VaultsTableAnnotationComposer get vaultId {
    final $$VaultsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.vaultId,
        referencedTable: $db.vaults,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$VaultsTableAnnotationComposer(
              $db: $db,
              $table: $db.vaults,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$HeldSharesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $HeldSharesTable,
    HeldShareRow,
    $$HeldSharesTableFilterComposer,
    $$HeldSharesTableOrderingComposer,
    $$HeldSharesTableAnnotationComposer,
    $$HeldSharesTableCreateCompanionBuilder,
    $$HeldSharesTableUpdateCompanionBuilder,
    (HeldShareRow, $$HeldSharesTableReferences),
    HeldShareRow,
    PrefetchHooks Function({bool vaultId})> {
  $$HeldSharesTableTableManager(_$AppDatabase db, $HeldSharesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$HeldSharesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$HeldSharesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HeldSharesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> vaultId = const Value.absent(),
            Value<int> shareIndex = const Value.absent(),
            Value<String> sharePayload = const Value.absent(),
            Value<int> distributionVersion = const Value.absent(),
            Value<int> receivedAt = const Value.absent(),
            Value<String?> nostrEventId = const Value.absent(),
            Value<String?> lastSeenRelay = const Value.absent(),
            Value<bool> pushEnabled = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              HeldSharesCompanion(
            id: id,
            vaultId: vaultId,
            shareIndex: shareIndex,
            sharePayload: sharePayload,
            distributionVersion: distributionVersion,
            receivedAt: receivedAt,
            nostrEventId: nostrEventId,
            lastSeenRelay: lastSeenRelay,
            pushEnabled: pushEnabled,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String vaultId,
            required int shareIndex,
            required String sharePayload,
            required int distributionVersion,
            required int receivedAt,
            Value<String?> nostrEventId = const Value.absent(),
            Value<String?> lastSeenRelay = const Value.absent(),
            Value<bool> pushEnabled = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              HeldSharesCompanion.insert(
            id: id,
            vaultId: vaultId,
            shareIndex: shareIndex,
            sharePayload: sharePayload,
            distributionVersion: distributionVersion,
            receivedAt: receivedAt,
            nostrEventId: nostrEventId,
            lastSeenRelay: lastSeenRelay,
            pushEnabled: pushEnabled,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), $$HeldSharesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({vaultId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<dynamic, dynamic, dynamic, dynamic, dynamic, dynamic,
                      dynamic, dynamic, dynamic, dynamic, dynamic>>(state) {
                if (vaultId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.vaultId,
                    referencedTable: $$HeldSharesTableReferences._vaultIdTable(db),
                    referencedColumn: $$HeldSharesTableReferences._vaultIdTable(db).id,
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

typedef $$HeldSharesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $HeldSharesTable,
    HeldShareRow,
    $$HeldSharesTableFilterComposer,
    $$HeldSharesTableOrderingComposer,
    $$HeldSharesTableAnnotationComposer,
    $$HeldSharesTableCreateCompanionBuilder,
    $$HeldSharesTableUpdateCompanionBuilder,
    (HeldShareRow, $$HeldSharesTableReferences),
    HeldShareRow,
    PrefetchHooks Function({bool vaultId})>;
typedef $$RecoveryRequestsTableCreateCompanionBuilder = RecoveryRequestsCompanion Function({
  required String id,
  required String vaultId,
  Value<String?> requestEventId,
  required String initiatorPubkey,
  required int startedAt,
  Value<int?> expiresAt,
  Value<int?> cancelledAt,
  Value<int?> completedAt,
  required int distributionVersionAtStart,
  required int thresholdAtStart,
  required String status,
  Value<bool> isPractice,
  Value<String?> errorMessage,
  Value<int?> eventCreationTimeMs,
  Value<int> rowid,
});
typedef $$RecoveryRequestsTableUpdateCompanionBuilder = RecoveryRequestsCompanion Function({
  Value<String> id,
  Value<String> vaultId,
  Value<String?> requestEventId,
  Value<String> initiatorPubkey,
  Value<int> startedAt,
  Value<int?> expiresAt,
  Value<int?> cancelledAt,
  Value<int?> completedAt,
  Value<int> distributionVersionAtStart,
  Value<int> thresholdAtStart,
  Value<String> status,
  Value<bool> isPractice,
  Value<String?> errorMessage,
  Value<int?> eventCreationTimeMs,
  Value<int> rowid,
});

final class $$RecoveryRequestsTableReferences
    extends BaseReferences<_$AppDatabase, $RecoveryRequestsTable, RecoveryRequestRow> {
  $$RecoveryRequestsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $VaultsTable _vaultIdTable(_$AppDatabase db) =>
      db.vaults.createAlias($_aliasNameGenerator(db.recoveryRequests.vaultId, db.vaults.id));

  $$VaultsTableProcessedTableManager get vaultId {
    final $_column = $_itemColumn<String>('vault_id')!;

    final manager =
        $$VaultsTableTableManager($_db, $_db.vaults).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_vaultIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$RecoveryRequestParticipantsTable, List<RecoveryRequestParticipantRow>>
      _recoveryRequestParticipantsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.recoveryRequestParticipants,
              aliasName: $_aliasNameGenerator(
                  db.recoveryRequests.id, db.recoveryRequestParticipants.requestId));

  $$RecoveryRequestParticipantsTableProcessedTableManager get recoveryRequestParticipantsRefs {
    final manager =
        $$RecoveryRequestParticipantsTableTableManager($_db, $_db.recoveryRequestParticipants)
            .filter((f) => f.requestId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_recoveryRequestParticipantsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$RecoveryResponsesTable, List<RecoveryResponseRow>>
      _recoveryResponsesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.recoveryResponses,
          aliasName: $_aliasNameGenerator(db.recoveryRequests.id, db.recoveryResponses.requestId));

  $$RecoveryResponsesTableProcessedTableManager get recoveryResponsesRefs {
    final manager = $$RecoveryResponsesTableTableManager($_db, $_db.recoveryResponses)
        .filter((f) => f.requestId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_recoveryResponsesRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$RecoveryRequestsTableFilterComposer
    extends Composer<_$AppDatabase, $RecoveryRequestsTable> {
  $$RecoveryRequestsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get requestEventId =>
      $composableBuilder(column: $table.requestEventId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get initiatorPubkey => $composableBuilder(
      column: $table.initiatorPubkey, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get cancelledAt =>
      $composableBuilder(column: $table.cancelledAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get completedAt =>
      $composableBuilder(column: $table.completedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get distributionVersionAtStart => $composableBuilder(
      column: $table.distributionVersionAtStart, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get thresholdAtStart => $composableBuilder(
      column: $table.thresholdAtStart, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isPractice =>
      $composableBuilder(column: $table.isPractice, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get errorMessage =>
      $composableBuilder(column: $table.errorMessage, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get eventCreationTimeMs => $composableBuilder(
      column: $table.eventCreationTimeMs, builder: (column) => ColumnFilters(column));

  $$VaultsTableFilterComposer get vaultId {
    final $$VaultsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.vaultId,
        referencedTable: $db.vaults,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$VaultsTableFilterComposer(
              $db: $db,
              $table: $db.vaults,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> recoveryRequestParticipantsRefs(
      Expression<bool> Function($$RecoveryRequestParticipantsTableFilterComposer f) f) {
    final $$RecoveryRequestParticipantsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.recoveryRequestParticipants,
        getReferencedColumn: (t) => t.requestId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$RecoveryRequestParticipantsTableFilterComposer(
              $db: $db,
              $table: $db.recoveryRequestParticipants,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> recoveryResponsesRefs(
      Expression<bool> Function($$RecoveryResponsesTableFilterComposer f) f) {
    final $$RecoveryResponsesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.recoveryResponses,
        getReferencedColumn: (t) => t.requestId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$RecoveryResponsesTableFilterComposer(
              $db: $db,
              $table: $db.recoveryResponses,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$RecoveryRequestsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecoveryRequestsTable> {
  $$RecoveryRequestsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get requestEventId => $composableBuilder(
      column: $table.requestEventId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get initiatorPubkey => $composableBuilder(
      column: $table.initiatorPubkey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get cancelledAt =>
      $composableBuilder(column: $table.cancelledAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get completedAt =>
      $composableBuilder(column: $table.completedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get distributionVersionAtStart => $composableBuilder(
      column: $table.distributionVersionAtStart, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get thresholdAtStart => $composableBuilder(
      column: $table.thresholdAtStart, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isPractice =>
      $composableBuilder(column: $table.isPractice, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get errorMessage =>
      $composableBuilder(column: $table.errorMessage, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get eventCreationTimeMs => $composableBuilder(
      column: $table.eventCreationTimeMs, builder: (column) => ColumnOrderings(column));

  $$VaultsTableOrderingComposer get vaultId {
    final $$VaultsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.vaultId,
        referencedTable: $db.vaults,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$VaultsTableOrderingComposer(
              $db: $db,
              $table: $db.vaults,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RecoveryRequestsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecoveryRequestsTable> {
  $$RecoveryRequestsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get requestEventId =>
      $composableBuilder(column: $table.requestEventId, builder: (column) => column);

  GeneratedColumn<String> get initiatorPubkey =>
      $composableBuilder(column: $table.initiatorPubkey, builder: (column) => column);

  GeneratedColumn<int> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<int> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<int> get cancelledAt =>
      $composableBuilder(column: $table.cancelledAt, builder: (column) => column);

  GeneratedColumn<int> get completedAt =>
      $composableBuilder(column: $table.completedAt, builder: (column) => column);

  GeneratedColumn<int> get distributionVersionAtStart =>
      $composableBuilder(column: $table.distributionVersionAtStart, builder: (column) => column);

  GeneratedColumn<int> get thresholdAtStart =>
      $composableBuilder(column: $table.thresholdAtStart, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<bool> get isPractice =>
      $composableBuilder(column: $table.isPractice, builder: (column) => column);

  GeneratedColumn<String> get errorMessage =>
      $composableBuilder(column: $table.errorMessage, builder: (column) => column);

  GeneratedColumn<int> get eventCreationTimeMs =>
      $composableBuilder(column: $table.eventCreationTimeMs, builder: (column) => column);

  $$VaultsTableAnnotationComposer get vaultId {
    final $$VaultsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.vaultId,
        referencedTable: $db.vaults,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$VaultsTableAnnotationComposer(
              $db: $db,
              $table: $db.vaults,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> recoveryRequestParticipantsRefs<T extends Object>(
      Expression<T> Function($$RecoveryRequestParticipantsTableAnnotationComposer a) f) {
    final $$RecoveryRequestParticipantsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.recoveryRequestParticipants,
        getReferencedColumn: (t) => t.requestId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$RecoveryRequestParticipantsTableAnnotationComposer(
              $db: $db,
              $table: $db.recoveryRequestParticipants,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> recoveryResponsesRefs<T extends Object>(
      Expression<T> Function($$RecoveryResponsesTableAnnotationComposer a) f) {
    final $$RecoveryResponsesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.recoveryResponses,
        getReferencedColumn: (t) => t.requestId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$RecoveryResponsesTableAnnotationComposer(
              $db: $db,
              $table: $db.recoveryResponses,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$RecoveryRequestsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RecoveryRequestsTable,
    RecoveryRequestRow,
    $$RecoveryRequestsTableFilterComposer,
    $$RecoveryRequestsTableOrderingComposer,
    $$RecoveryRequestsTableAnnotationComposer,
    $$RecoveryRequestsTableCreateCompanionBuilder,
    $$RecoveryRequestsTableUpdateCompanionBuilder,
    (RecoveryRequestRow, $$RecoveryRequestsTableReferences),
    RecoveryRequestRow,
    PrefetchHooks Function(
        {bool vaultId, bool recoveryRequestParticipantsRefs, bool recoveryResponsesRefs})> {
  $$RecoveryRequestsTableTableManager(_$AppDatabase db, $RecoveryRequestsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecoveryRequestsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecoveryRequestsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecoveryRequestsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> vaultId = const Value.absent(),
            Value<String?> requestEventId = const Value.absent(),
            Value<String> initiatorPubkey = const Value.absent(),
            Value<int> startedAt = const Value.absent(),
            Value<int?> expiresAt = const Value.absent(),
            Value<int?> cancelledAt = const Value.absent(),
            Value<int?> completedAt = const Value.absent(),
            Value<int> distributionVersionAtStart = const Value.absent(),
            Value<int> thresholdAtStart = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<bool> isPractice = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
            Value<int?> eventCreationTimeMs = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RecoveryRequestsCompanion(
            id: id,
            vaultId: vaultId,
            requestEventId: requestEventId,
            initiatorPubkey: initiatorPubkey,
            startedAt: startedAt,
            expiresAt: expiresAt,
            cancelledAt: cancelledAt,
            completedAt: completedAt,
            distributionVersionAtStart: distributionVersionAtStart,
            thresholdAtStart: thresholdAtStart,
            status: status,
            isPractice: isPractice,
            errorMessage: errorMessage,
            eventCreationTimeMs: eventCreationTimeMs,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String vaultId,
            Value<String?> requestEventId = const Value.absent(),
            required String initiatorPubkey,
            required int startedAt,
            Value<int?> expiresAt = const Value.absent(),
            Value<int?> cancelledAt = const Value.absent(),
            Value<int?> completedAt = const Value.absent(),
            required int distributionVersionAtStart,
            required int thresholdAtStart,
            required String status,
            Value<bool> isPractice = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
            Value<int?> eventCreationTimeMs = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RecoveryRequestsCompanion.insert(
            id: id,
            vaultId: vaultId,
            requestEventId: requestEventId,
            initiatorPubkey: initiatorPubkey,
            startedAt: startedAt,
            expiresAt: expiresAt,
            cancelledAt: cancelledAt,
            completedAt: completedAt,
            distributionVersionAtStart: distributionVersionAtStart,
            thresholdAtStart: thresholdAtStart,
            status: status,
            isPractice: isPractice,
            errorMessage: errorMessage,
            eventCreationTimeMs: eventCreationTimeMs,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), $$RecoveryRequestsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {vaultId = false,
              recoveryRequestParticipantsRefs = false,
              recoveryResponsesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (recoveryRequestParticipantsRefs) db.recoveryRequestParticipants,
                if (recoveryResponsesRefs) db.recoveryResponses
              ],
              addJoins: <
                  T extends TableManagerState<dynamic, dynamic, dynamic, dynamic, dynamic, dynamic,
                      dynamic, dynamic, dynamic, dynamic, dynamic>>(state) {
                if (vaultId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.vaultId,
                    referencedTable: $$RecoveryRequestsTableReferences._vaultIdTable(db),
                    referencedColumn: $$RecoveryRequestsTableReferences._vaultIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (recoveryRequestParticipantsRefs)
                    await $_getPrefetchedData<RecoveryRequestRow, $RecoveryRequestsTable,
                            RecoveryRequestParticipantRow>(
                        currentTable: table,
                        referencedTable: $$RecoveryRequestsTableReferences
                            ._recoveryRequestParticipantsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$RecoveryRequestsTableReferences(db, table, p0)
                                .recoveryRequestParticipantsRefs,
                        referencedItemsForCurrentItem: (item, referencedItems) =>
                            referencedItems.where((e) => e.requestId == item.id),
                        typedResults: items),
                  if (recoveryResponsesRefs)
                    await $_getPrefetchedData<RecoveryRequestRow, $RecoveryRequestsTable,
                            RecoveryResponseRow>(
                        currentTable: table,
                        referencedTable:
                            $$RecoveryRequestsTableReferences._recoveryResponsesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$RecoveryRequestsTableReferences(db, table, p0).recoveryResponsesRefs,
                        referencedItemsForCurrentItem: (item, referencedItems) =>
                            referencedItems.where((e) => e.requestId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$RecoveryRequestsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RecoveryRequestsTable,
    RecoveryRequestRow,
    $$RecoveryRequestsTableFilterComposer,
    $$RecoveryRequestsTableOrderingComposer,
    $$RecoveryRequestsTableAnnotationComposer,
    $$RecoveryRequestsTableCreateCompanionBuilder,
    $$RecoveryRequestsTableUpdateCompanionBuilder,
    (RecoveryRequestRow, $$RecoveryRequestsTableReferences),
    RecoveryRequestRow,
    PrefetchHooks Function(
        {bool vaultId, bool recoveryRequestParticipantsRefs, bool recoveryResponsesRefs})>;
typedef $$RecoveryRequestParticipantsTableCreateCompanionBuilder
    = RecoveryRequestParticipantsCompanion Function({
  required String requestId,
  required String pubkey,
  Value<int> rowid,
});
typedef $$RecoveryRequestParticipantsTableUpdateCompanionBuilder
    = RecoveryRequestParticipantsCompanion Function({
  Value<String> requestId,
  Value<String> pubkey,
  Value<int> rowid,
});

final class $$RecoveryRequestParticipantsTableReferences extends BaseReferences<_$AppDatabase,
    $RecoveryRequestParticipantsTable, RecoveryRequestParticipantRow> {
  $$RecoveryRequestParticipantsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RecoveryRequestsTable _requestIdTable(_$AppDatabase db) =>
      db.recoveryRequests.createAlias(
          $_aliasNameGenerator(db.recoveryRequestParticipants.requestId, db.recoveryRequests.id));

  $$RecoveryRequestsTableProcessedTableManager get requestId {
    final $_column = $_itemColumn<String>('request_id')!;

    final manager = $$RecoveryRequestsTableTableManager($_db, $_db.recoveryRequests)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_requestIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$RecoveryRequestParticipantsTableFilterComposer
    extends Composer<_$AppDatabase, $RecoveryRequestParticipantsTable> {
  $$RecoveryRequestParticipantsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get pubkey =>
      $composableBuilder(column: $table.pubkey, builder: (column) => ColumnFilters(column));

  $$RecoveryRequestsTableFilterComposer get requestId {
    final $$RecoveryRequestsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.requestId,
        referencedTable: $db.recoveryRequests,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$RecoveryRequestsTableFilterComposer(
              $db: $db,
              $table: $db.recoveryRequests,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RecoveryRequestParticipantsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecoveryRequestParticipantsTable> {
  $$RecoveryRequestParticipantsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get pubkey =>
      $composableBuilder(column: $table.pubkey, builder: (column) => ColumnOrderings(column));

  $$RecoveryRequestsTableOrderingComposer get requestId {
    final $$RecoveryRequestsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.requestId,
        referencedTable: $db.recoveryRequests,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$RecoveryRequestsTableOrderingComposer(
              $db: $db,
              $table: $db.recoveryRequests,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RecoveryRequestParticipantsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecoveryRequestParticipantsTable> {
  $$RecoveryRequestParticipantsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get pubkey =>
      $composableBuilder(column: $table.pubkey, builder: (column) => column);

  $$RecoveryRequestsTableAnnotationComposer get requestId {
    final $$RecoveryRequestsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.requestId,
        referencedTable: $db.recoveryRequests,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$RecoveryRequestsTableAnnotationComposer(
              $db: $db,
              $table: $db.recoveryRequests,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RecoveryRequestParticipantsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RecoveryRequestParticipantsTable,
    RecoveryRequestParticipantRow,
    $$RecoveryRequestParticipantsTableFilterComposer,
    $$RecoveryRequestParticipantsTableOrderingComposer,
    $$RecoveryRequestParticipantsTableAnnotationComposer,
    $$RecoveryRequestParticipantsTableCreateCompanionBuilder,
    $$RecoveryRequestParticipantsTableUpdateCompanionBuilder,
    (RecoveryRequestParticipantRow, $$RecoveryRequestParticipantsTableReferences),
    RecoveryRequestParticipantRow,
    PrefetchHooks Function({bool requestId})> {
  $$RecoveryRequestParticipantsTableTableManager(
      _$AppDatabase db, $RecoveryRequestParticipantsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecoveryRequestParticipantsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecoveryRequestParticipantsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecoveryRequestParticipantsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> requestId = const Value.absent(),
            Value<String> pubkey = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RecoveryRequestParticipantsCompanion(
            requestId: requestId,
            pubkey: pubkey,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String requestId,
            required String pubkey,
            Value<int> rowid = const Value.absent(),
          }) =>
              RecoveryRequestParticipantsCompanion.insert(
            requestId: requestId,
            pubkey: pubkey,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$RecoveryRequestParticipantsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({requestId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<dynamic, dynamic, dynamic, dynamic, dynamic, dynamic,
                      dynamic, dynamic, dynamic, dynamic, dynamic>>(state) {
                if (requestId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.requestId,
                    referencedTable:
                        $$RecoveryRequestParticipantsTableReferences._requestIdTable(db),
                    referencedColumn:
                        $$RecoveryRequestParticipantsTableReferences._requestIdTable(db).id,
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

typedef $$RecoveryRequestParticipantsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RecoveryRequestParticipantsTable,
    RecoveryRequestParticipantRow,
    $$RecoveryRequestParticipantsTableFilterComposer,
    $$RecoveryRequestParticipantsTableOrderingComposer,
    $$RecoveryRequestParticipantsTableAnnotationComposer,
    $$RecoveryRequestParticipantsTableCreateCompanionBuilder,
    $$RecoveryRequestParticipantsTableUpdateCompanionBuilder,
    (RecoveryRequestParticipantRow, $$RecoveryRequestParticipantsTableReferences),
    RecoveryRequestParticipantRow,
    PrefetchHooks Function({bool requestId})>;
typedef $$RecoveryResponsesTableCreateCompanionBuilder = RecoveryResponsesCompanion Function({
  required String id,
  required String requestId,
  Value<String?> stewardId,
  required String responderPubkey,
  required String sharePayload,
  required int shareDistributionVersion,
  required int receivedAt,
  Value<String?> nostrEventId,
  Value<String?> replyingToEventId,
  required bool approved,
  Value<int?> respondedAtMs,
  Value<String?> errorMessage,
  Value<int> rowid,
});
typedef $$RecoveryResponsesTableUpdateCompanionBuilder = RecoveryResponsesCompanion Function({
  Value<String> id,
  Value<String> requestId,
  Value<String?> stewardId,
  Value<String> responderPubkey,
  Value<String> sharePayload,
  Value<int> shareDistributionVersion,
  Value<int> receivedAt,
  Value<String?> nostrEventId,
  Value<String?> replyingToEventId,
  Value<bool> approved,
  Value<int?> respondedAtMs,
  Value<String?> errorMessage,
  Value<int> rowid,
});

final class $$RecoveryResponsesTableReferences
    extends BaseReferences<_$AppDatabase, $RecoveryResponsesTable, RecoveryResponseRow> {
  $$RecoveryResponsesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RecoveryRequestsTable _requestIdTable(_$AppDatabase db) => db.recoveryRequests
      .createAlias($_aliasNameGenerator(db.recoveryResponses.requestId, db.recoveryRequests.id));

  $$RecoveryRequestsTableProcessedTableManager get requestId {
    final $_column = $_itemColumn<String>('request_id')!;

    final manager = $$RecoveryRequestsTableTableManager($_db, $_db.recoveryRequests)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_requestIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static $StewardsTable _stewardIdTable(_$AppDatabase db) =>
      db.stewards.createAlias($_aliasNameGenerator(db.recoveryResponses.stewardId, db.stewards.id));

  $$StewardsTableProcessedTableManager? get stewardId {
    final $_column = $_itemColumn<String>('steward_id');
    if ($_column == null) return null;
    final manager =
        $$StewardsTableTableManager($_db, $_db.stewards).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_stewardIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$RecoveryResponsesTableFilterComposer
    extends Composer<_$AppDatabase, $RecoveryResponsesTable> {
  $$RecoveryResponsesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get responderPubkey => $composableBuilder(
      column: $table.responderPubkey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sharePayload =>
      $composableBuilder(column: $table.sharePayload, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get shareDistributionVersion => $composableBuilder(
      column: $table.shareDistributionVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get receivedAt =>
      $composableBuilder(column: $table.receivedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nostrEventId =>
      $composableBuilder(column: $table.nostrEventId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get replyingToEventId => $composableBuilder(
      column: $table.replyingToEventId, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get approved =>
      $composableBuilder(column: $table.approved, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get respondedAtMs =>
      $composableBuilder(column: $table.respondedAtMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get errorMessage =>
      $composableBuilder(column: $table.errorMessage, builder: (column) => ColumnFilters(column));

  $$RecoveryRequestsTableFilterComposer get requestId {
    final $$RecoveryRequestsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.requestId,
        referencedTable: $db.recoveryRequests,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$RecoveryRequestsTableFilterComposer(
              $db: $db,
              $table: $db.recoveryRequests,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
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
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$StewardsTableFilterComposer(
              $db: $db,
              $table: $db.stewards,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RecoveryResponsesTableOrderingComposer
    extends Composer<_$AppDatabase, $RecoveryResponsesTable> {
  $$RecoveryResponsesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get responderPubkey => $composableBuilder(
      column: $table.responderPubkey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sharePayload =>
      $composableBuilder(column: $table.sharePayload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get shareDistributionVersion => $composableBuilder(
      column: $table.shareDistributionVersion, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get receivedAt =>
      $composableBuilder(column: $table.receivedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nostrEventId =>
      $composableBuilder(column: $table.nostrEventId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get replyingToEventId => $composableBuilder(
      column: $table.replyingToEventId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get approved =>
      $composableBuilder(column: $table.approved, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get respondedAtMs => $composableBuilder(
      column: $table.respondedAtMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get errorMessage =>
      $composableBuilder(column: $table.errorMessage, builder: (column) => ColumnOrderings(column));

  $$RecoveryRequestsTableOrderingComposer get requestId {
    final $$RecoveryRequestsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.requestId,
        referencedTable: $db.recoveryRequests,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$RecoveryRequestsTableOrderingComposer(
              $db: $db,
              $table: $db.recoveryRequests,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
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
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$StewardsTableOrderingComposer(
              $db: $db,
              $table: $db.stewards,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RecoveryResponsesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecoveryResponsesTable> {
  $$RecoveryResponsesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get responderPubkey =>
      $composableBuilder(column: $table.responderPubkey, builder: (column) => column);

  GeneratedColumn<String> get sharePayload =>
      $composableBuilder(column: $table.sharePayload, builder: (column) => column);

  GeneratedColumn<int> get shareDistributionVersion =>
      $composableBuilder(column: $table.shareDistributionVersion, builder: (column) => column);

  GeneratedColumn<int> get receivedAt =>
      $composableBuilder(column: $table.receivedAt, builder: (column) => column);

  GeneratedColumn<String> get nostrEventId =>
      $composableBuilder(column: $table.nostrEventId, builder: (column) => column);

  GeneratedColumn<String> get replyingToEventId =>
      $composableBuilder(column: $table.replyingToEventId, builder: (column) => column);

  GeneratedColumn<bool> get approved =>
      $composableBuilder(column: $table.approved, builder: (column) => column);

  GeneratedColumn<int> get respondedAtMs =>
      $composableBuilder(column: $table.respondedAtMs, builder: (column) => column);

  GeneratedColumn<String> get errorMessage =>
      $composableBuilder(column: $table.errorMessage, builder: (column) => column);

  $$RecoveryRequestsTableAnnotationComposer get requestId {
    final $$RecoveryRequestsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.requestId,
        referencedTable: $db.recoveryRequests,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$RecoveryRequestsTableAnnotationComposer(
              $db: $db,
              $table: $db.recoveryRequests,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
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
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$StewardsTableAnnotationComposer(
              $db: $db,
              $table: $db.stewards,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RecoveryResponsesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RecoveryResponsesTable,
    RecoveryResponseRow,
    $$RecoveryResponsesTableFilterComposer,
    $$RecoveryResponsesTableOrderingComposer,
    $$RecoveryResponsesTableAnnotationComposer,
    $$RecoveryResponsesTableCreateCompanionBuilder,
    $$RecoveryResponsesTableUpdateCompanionBuilder,
    (RecoveryResponseRow, $$RecoveryResponsesTableReferences),
    RecoveryResponseRow,
    PrefetchHooks Function({bool requestId, bool stewardId})> {
  $$RecoveryResponsesTableTableManager(_$AppDatabase db, $RecoveryResponsesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecoveryResponsesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecoveryResponsesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecoveryResponsesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> requestId = const Value.absent(),
            Value<String?> stewardId = const Value.absent(),
            Value<String> responderPubkey = const Value.absent(),
            Value<String> sharePayload = const Value.absent(),
            Value<int> shareDistributionVersion = const Value.absent(),
            Value<int> receivedAt = const Value.absent(),
            Value<String?> nostrEventId = const Value.absent(),
            Value<String?> replyingToEventId = const Value.absent(),
            Value<bool> approved = const Value.absent(),
            Value<int?> respondedAtMs = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RecoveryResponsesCompanion(
            id: id,
            requestId: requestId,
            stewardId: stewardId,
            responderPubkey: responderPubkey,
            sharePayload: sharePayload,
            shareDistributionVersion: shareDistributionVersion,
            receivedAt: receivedAt,
            nostrEventId: nostrEventId,
            replyingToEventId: replyingToEventId,
            approved: approved,
            respondedAtMs: respondedAtMs,
            errorMessage: errorMessage,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String requestId,
            Value<String?> stewardId = const Value.absent(),
            required String responderPubkey,
            required String sharePayload,
            required int shareDistributionVersion,
            required int receivedAt,
            Value<String?> nostrEventId = const Value.absent(),
            Value<String?> replyingToEventId = const Value.absent(),
            required bool approved,
            Value<int?> respondedAtMs = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RecoveryResponsesCompanion.insert(
            id: id,
            requestId: requestId,
            stewardId: stewardId,
            responderPubkey: responderPubkey,
            sharePayload: sharePayload,
            shareDistributionVersion: shareDistributionVersion,
            receivedAt: receivedAt,
            nostrEventId: nostrEventId,
            replyingToEventId: replyingToEventId,
            approved: approved,
            respondedAtMs: respondedAtMs,
            errorMessage: errorMessage,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), $$RecoveryResponsesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({requestId = false, stewardId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<dynamic, dynamic, dynamic, dynamic, dynamic, dynamic,
                      dynamic, dynamic, dynamic, dynamic, dynamic>>(state) {
                if (requestId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.requestId,
                    referencedTable: $$RecoveryResponsesTableReferences._requestIdTable(db),
                    referencedColumn: $$RecoveryResponsesTableReferences._requestIdTable(db).id,
                  ) as T;
                }
                if (stewardId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.stewardId,
                    referencedTable: $$RecoveryResponsesTableReferences._stewardIdTable(db),
                    referencedColumn: $$RecoveryResponsesTableReferences._stewardIdTable(db).id,
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

typedef $$RecoveryResponsesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RecoveryResponsesTable,
    RecoveryResponseRow,
    $$RecoveryResponsesTableFilterComposer,
    $$RecoveryResponsesTableOrderingComposer,
    $$RecoveryResponsesTableAnnotationComposer,
    $$RecoveryResponsesTableCreateCompanionBuilder,
    $$RecoveryResponsesTableUpdateCompanionBuilder,
    (RecoveryResponseRow, $$RecoveryResponsesTableReferences),
    RecoveryResponseRow,
    PrefetchHooks Function({bool requestId, bool stewardId})>;
typedef $$OutboxTableCreateCompanionBuilder = OutboxCompanion Function({
  required String id,
  Value<String?> vaultId,
  required int kind,
  required String eventId,
  required int createdAt,
  Value<int?> nextAttemptAt,
  required String eventJson,
  Value<String?> correlationId,
  Value<int> rowid,
});
typedef $$OutboxTableUpdateCompanionBuilder = OutboxCompanion Function({
  Value<String> id,
  Value<String?> vaultId,
  Value<int> kind,
  Value<String> eventId,
  Value<int> createdAt,
  Value<int?> nextAttemptAt,
  Value<String> eventJson,
  Value<String?> correlationId,
  Value<int> rowid,
});

final class $$OutboxTableReferences extends BaseReferences<_$AppDatabase, $OutboxTable, OutboxRow> {
  $$OutboxTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $VaultsTable _vaultIdTable(_$AppDatabase db) =>
      db.vaults.createAlias($_aliasNameGenerator(db.outbox.vaultId, db.vaults.id));

  $$VaultsTableProcessedTableManager? get vaultId {
    final $_column = $_itemColumn<String>('vault_id');
    if ($_column == null) return null;
    final manager =
        $$VaultsTableTableManager($_db, $_db.vaults).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_vaultIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$OutboxRelaysTable, List<OutboxRelayRow>> _outboxRelaysRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.outboxRelays,
          aliasName: $_aliasNameGenerator(db.outbox.id, db.outboxRelays.outboxId));

  $$OutboxRelaysTableProcessedTableManager get outboxRelaysRefs {
    final manager = $$OutboxRelaysTableTableManager($_db, $_db.outboxRelays)
        .filter((f) => f.outboxId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_outboxRelaysRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$OutboxTableFilterComposer extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get nextAttemptAt =>
      $composableBuilder(column: $table.nextAttemptAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get eventJson =>
      $composableBuilder(column: $table.eventJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get correlationId =>
      $composableBuilder(column: $table.correlationId, builder: (column) => ColumnFilters(column));

  $$VaultsTableFilterComposer get vaultId {
    final $$VaultsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.vaultId,
        referencedTable: $db.vaults,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$VaultsTableFilterComposer(
              $db: $db,
              $table: $db.vaults,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> outboxRelaysRefs(
      Expression<bool> Function($$OutboxRelaysTableFilterComposer f) f) {
    final $$OutboxRelaysTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.outboxRelays,
        getReferencedColumn: (t) => t.outboxId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$OutboxRelaysTableFilterComposer(
              $db: $db,
              $table: $db.outboxRelays,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$OutboxTableOrderingComposer extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get nextAttemptAt => $composableBuilder(
      column: $table.nextAttemptAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get eventJson =>
      $composableBuilder(column: $table.eventJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get correlationId => $composableBuilder(
      column: $table.correlationId, builder: (column) => ColumnOrderings(column));

  $$VaultsTableOrderingComposer get vaultId {
    final $$VaultsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.vaultId,
        referencedTable: $db.vaults,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$VaultsTableOrderingComposer(
              $db: $db,
              $table: $db.vaults,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$OutboxTableAnnotationComposer extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get nextAttemptAt =>
      $composableBuilder(column: $table.nextAttemptAt, builder: (column) => column);

  GeneratedColumn<String> get eventJson =>
      $composableBuilder(column: $table.eventJson, builder: (column) => column);

  GeneratedColumn<String> get correlationId =>
      $composableBuilder(column: $table.correlationId, builder: (column) => column);

  $$VaultsTableAnnotationComposer get vaultId {
    final $$VaultsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.vaultId,
        referencedTable: $db.vaults,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$VaultsTableAnnotationComposer(
              $db: $db,
              $table: $db.vaults,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> outboxRelaysRefs<T extends Object>(
      Expression<T> Function($$OutboxRelaysTableAnnotationComposer a) f) {
    final $$OutboxRelaysTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.outboxRelays,
        getReferencedColumn: (t) => t.outboxId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$OutboxRelaysTableAnnotationComposer(
              $db: $db,
              $table: $db.outboxRelays,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$OutboxTableTableManager extends RootTableManager<
    _$AppDatabase,
    $OutboxTable,
    OutboxRow,
    $$OutboxTableFilterComposer,
    $$OutboxTableOrderingComposer,
    $$OutboxTableAnnotationComposer,
    $$OutboxTableCreateCompanionBuilder,
    $$OutboxTableUpdateCompanionBuilder,
    (OutboxRow, $$OutboxTableReferences),
    OutboxRow,
    PrefetchHooks Function({bool vaultId, bool outboxRelaysRefs})> {
  $$OutboxTableTableManager(_$AppDatabase db, $OutboxTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$OutboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$OutboxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String?> vaultId = const Value.absent(),
            Value<int> kind = const Value.absent(),
            Value<String> eventId = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int?> nextAttemptAt = const Value.absent(),
            Value<String> eventJson = const Value.absent(),
            Value<String?> correlationId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              OutboxCompanion(
            id: id,
            vaultId: vaultId,
            kind: kind,
            eventId: eventId,
            createdAt: createdAt,
            nextAttemptAt: nextAttemptAt,
            eventJson: eventJson,
            correlationId: correlationId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String?> vaultId = const Value.absent(),
            required int kind,
            required String eventId,
            required int createdAt,
            Value<int?> nextAttemptAt = const Value.absent(),
            required String eventJson,
            Value<String?> correlationId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              OutboxCompanion.insert(
            id: id,
            vaultId: vaultId,
            kind: kind,
            eventId: eventId,
            createdAt: createdAt,
            nextAttemptAt: nextAttemptAt,
            eventJson: eventJson,
            correlationId: correlationId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable(table), $$OutboxTableReferences(db, table, e))).toList(),
          prefetchHooksCallback: ({vaultId = false, outboxRelaysRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (outboxRelaysRefs) db.outboxRelays],
              addJoins: <
                  T extends TableManagerState<dynamic, dynamic, dynamic, dynamic, dynamic, dynamic,
                      dynamic, dynamic, dynamic, dynamic, dynamic>>(state) {
                if (vaultId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.vaultId,
                    referencedTable: $$OutboxTableReferences._vaultIdTable(db),
                    referencedColumn: $$OutboxTableReferences._vaultIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (outboxRelaysRefs)
                    await $_getPrefetchedData<OutboxRow, $OutboxTable, OutboxRelayRow>(
                        currentTable: table,
                        referencedTable: $$OutboxTableReferences._outboxRelaysRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$OutboxTableReferences(db, table, p0).outboxRelaysRefs,
                        referencedItemsForCurrentItem: (item, referencedItems) =>
                            referencedItems.where((e) => e.outboxId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$OutboxTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $OutboxTable,
    OutboxRow,
    $$OutboxTableFilterComposer,
    $$OutboxTableOrderingComposer,
    $$OutboxTableAnnotationComposer,
    $$OutboxTableCreateCompanionBuilder,
    $$OutboxTableUpdateCompanionBuilder,
    (OutboxRow, $$OutboxTableReferences),
    OutboxRow,
    PrefetchHooks Function({bool vaultId, bool outboxRelaysRefs})>;
typedef $$OutboxRelaysTableCreateCompanionBuilder = OutboxRelaysCompanion Function({
  required String outboxId,
  required String relayUrl,
  required String status,
  Value<int> attempts,
  Value<int?> nextAttemptAt,
  Value<String?> lastError,
  Value<int> rowid,
});
typedef $$OutboxRelaysTableUpdateCompanionBuilder = OutboxRelaysCompanion Function({
  Value<String> outboxId,
  Value<String> relayUrl,
  Value<String> status,
  Value<int> attempts,
  Value<int?> nextAttemptAt,
  Value<String?> lastError,
  Value<int> rowid,
});

final class $$OutboxRelaysTableReferences
    extends BaseReferences<_$AppDatabase, $OutboxRelaysTable, OutboxRelayRow> {
  $$OutboxRelaysTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $OutboxTable _outboxIdTable(_$AppDatabase db) =>
      db.outbox.createAlias($_aliasNameGenerator(db.outboxRelays.outboxId, db.outbox.id));

  $$OutboxTableProcessedTableManager get outboxId {
    final $_column = $_itemColumn<String>('outbox_id')!;

    final manager =
        $$OutboxTableTableManager($_db, $_db.outbox).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_outboxIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$OutboxRelaysTableFilterComposer extends Composer<_$AppDatabase, $OutboxRelaysTable> {
  $$OutboxRelaysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get relayUrl =>
      $composableBuilder(column: $table.relayUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get nextAttemptAt =>
      $composableBuilder(column: $table.nextAttemptAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => ColumnFilters(column));

  $$OutboxTableFilterComposer get outboxId {
    final $$OutboxTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.outboxId,
        referencedTable: $db.outbox,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$OutboxTableFilterComposer(
              $db: $db,
              $table: $db.outbox,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$OutboxRelaysTableOrderingComposer extends Composer<_$AppDatabase, $OutboxRelaysTable> {
  $$OutboxRelaysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get relayUrl =>
      $composableBuilder(column: $table.relayUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get nextAttemptAt => $composableBuilder(
      column: $table.nextAttemptAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => ColumnOrderings(column));

  $$OutboxTableOrderingComposer get outboxId {
    final $$OutboxTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.outboxId,
        referencedTable: $db.outbox,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$OutboxTableOrderingComposer(
              $db: $db,
              $table: $db.outbox,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$OutboxRelaysTableAnnotationComposer extends Composer<_$AppDatabase, $OutboxRelaysTable> {
  $$OutboxRelaysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get relayUrl =>
      $composableBuilder(column: $table.relayUrl, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<int> get nextAttemptAt =>
      $composableBuilder(column: $table.nextAttemptAt, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  $$OutboxTableAnnotationComposer get outboxId {
    final $$OutboxTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.outboxId,
        referencedTable: $db.outbox,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
            $$OutboxTableAnnotationComposer(
              $db: $db,
              $table: $db.outbox,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$OutboxRelaysTableTableManager extends RootTableManager<
    _$AppDatabase,
    $OutboxRelaysTable,
    OutboxRelayRow,
    $$OutboxRelaysTableFilterComposer,
    $$OutboxRelaysTableOrderingComposer,
    $$OutboxRelaysTableAnnotationComposer,
    $$OutboxRelaysTableCreateCompanionBuilder,
    $$OutboxRelaysTableUpdateCompanionBuilder,
    (OutboxRelayRow, $$OutboxRelaysTableReferences),
    OutboxRelayRow,
    PrefetchHooks Function({bool outboxId})> {
  $$OutboxRelaysTableTableManager(_$AppDatabase db, $OutboxRelaysTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$OutboxRelaysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$OutboxRelaysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxRelaysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> outboxId = const Value.absent(),
            Value<String> relayUrl = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> attempts = const Value.absent(),
            Value<int?> nextAttemptAt = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              OutboxRelaysCompanion(
            outboxId: outboxId,
            relayUrl: relayUrl,
            status: status,
            attempts: attempts,
            nextAttemptAt: nextAttemptAt,
            lastError: lastError,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String outboxId,
            required String relayUrl,
            required String status,
            Value<int> attempts = const Value.absent(),
            Value<int?> nextAttemptAt = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              OutboxRelaysCompanion.insert(
            outboxId: outboxId,
            relayUrl: relayUrl,
            status: status,
            attempts: attempts,
            nextAttemptAt: nextAttemptAt,
            lastError: lastError,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), $$OutboxRelaysTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({outboxId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<dynamic, dynamic, dynamic, dynamic, dynamic, dynamic,
                      dynamic, dynamic, dynamic, dynamic, dynamic>>(state) {
                if (outboxId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.outboxId,
                    referencedTable: $$OutboxRelaysTableReferences._outboxIdTable(db),
                    referencedColumn: $$OutboxRelaysTableReferences._outboxIdTable(db).id,
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

typedef $$OutboxRelaysTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $OutboxRelaysTable,
    OutboxRelayRow,
    $$OutboxRelaysTableFilterComposer,
    $$OutboxRelaysTableOrderingComposer,
    $$OutboxRelaysTableAnnotationComposer,
    $$OutboxRelaysTableCreateCompanionBuilder,
    $$OutboxRelaysTableUpdateCompanionBuilder,
    (OutboxRelayRow, $$OutboxRelaysTableReferences),
    OutboxRelayRow,
    PrefetchHooks Function({bool outboxId})>;
typedef $$KvTableCreateCompanionBuilder = KvCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$KvTableUpdateCompanionBuilder = KvCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$KvTableFilterComposer extends Composer<_$AppDatabase, $KvTable> {
  $$KvTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$KvTableOrderingComposer extends Composer<_$AppDatabase, $KvTable> {
  $$KvTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$KvTableAnnotationComposer extends Composer<_$AppDatabase, $KvTable> {
  $$KvTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$KvTableTableManager extends RootTableManager<
    _$AppDatabase,
    $KvTable,
    KvRow,
    $$KvTableFilterComposer,
    $$KvTableOrderingComposer,
    $$KvTableAnnotationComposer,
    $$KvTableCreateCompanionBuilder,
    $$KvTableUpdateCompanionBuilder,
    (KvRow, BaseReferences<_$AppDatabase, $KvTable, KvRow>),
    KvRow,
    PrefetchHooks Function()> {
  $$KvTableTableManager(_$AppDatabase db, $KvTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$KvTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$KvTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$KvTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              KvCompanion(
            key: key,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) =>
              KvCompanion.insert(
            key: key,
            value: value,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable(table), BaseReferences(db, table, e))).toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$KvTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $KvTable,
    KvRow,
    $$KvTableFilterComposer,
    $$KvTableOrderingComposer,
    $$KvTableAnnotationComposer,
    $$KvTableCreateCompanionBuilder,
    $$KvTableUpdateCompanionBuilder,
    (KvRow, BaseReferences<_$AppDatabase, $KvTable, KvRow>),
    KvRow,
    PrefetchHooks Function()>;
typedef $$ViewedNotificationsTableCreateCompanionBuilder = ViewedNotificationsCompanion Function({
  required String notificationId,
  required int viewedAt,
  Value<int> rowid,
});
typedef $$ViewedNotificationsTableUpdateCompanionBuilder = ViewedNotificationsCompanion Function({
  Value<String> notificationId,
  Value<int> viewedAt,
  Value<int> rowid,
});

class $$ViewedNotificationsTableFilterComposer
    extends Composer<_$AppDatabase, $ViewedNotificationsTable> {
  $$ViewedNotificationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get notificationId =>
      $composableBuilder(column: $table.notificationId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get viewedAt =>
      $composableBuilder(column: $table.viewedAt, builder: (column) => ColumnFilters(column));
}

class $$ViewedNotificationsTableOrderingComposer
    extends Composer<_$AppDatabase, $ViewedNotificationsTable> {
  $$ViewedNotificationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get notificationId => $composableBuilder(
      column: $table.notificationId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get viewedAt =>
      $composableBuilder(column: $table.viewedAt, builder: (column) => ColumnOrderings(column));
}

class $$ViewedNotificationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ViewedNotificationsTable> {
  $$ViewedNotificationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get notificationId =>
      $composableBuilder(column: $table.notificationId, builder: (column) => column);

  GeneratedColumn<int> get viewedAt =>
      $composableBuilder(column: $table.viewedAt, builder: (column) => column);
}

class $$ViewedNotificationsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ViewedNotificationsTable,
    ViewedNotificationRow,
    $$ViewedNotificationsTableFilterComposer,
    $$ViewedNotificationsTableOrderingComposer,
    $$ViewedNotificationsTableAnnotationComposer,
    $$ViewedNotificationsTableCreateCompanionBuilder,
    $$ViewedNotificationsTableUpdateCompanionBuilder,
    (
      ViewedNotificationRow,
      BaseReferences<_$AppDatabase, $ViewedNotificationsTable, ViewedNotificationRow>
    ),
    ViewedNotificationRow,
    PrefetchHooks Function()> {
  $$ViewedNotificationsTableTableManager(_$AppDatabase db, $ViewedNotificationsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ViewedNotificationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ViewedNotificationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ViewedNotificationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> notificationId = const Value.absent(),
            Value<int> viewedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ViewedNotificationsCompanion(
            notificationId: notificationId,
            viewedAt: viewedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String notificationId,
            required int viewedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ViewedNotificationsCompanion.insert(
            notificationId: notificationId,
            viewedAt: viewedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable(table), BaseReferences(db, table, e))).toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ViewedNotificationsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ViewedNotificationsTable,
    ViewedNotificationRow,
    $$ViewedNotificationsTableFilterComposer,
    $$ViewedNotificationsTableOrderingComposer,
    $$ViewedNotificationsTableAnnotationComposer,
    $$ViewedNotificationsTableCreateCompanionBuilder,
    $$ViewedNotificationsTableUpdateCompanionBuilder,
    (
      ViewedNotificationRow,
      BaseReferences<_$AppDatabase, $ViewedNotificationsTable, ViewedNotificationRow>
    ),
    ViewedNotificationRow,
    PrefetchHooks Function()>;
typedef $$SyncedConsentsTableCreateCompanionBuilder = SyncedConsentsCompanion Function({
  required String consentId,
  required String payload,
  required int syncedAt,
  Value<int> rowid,
});
typedef $$SyncedConsentsTableUpdateCompanionBuilder = SyncedConsentsCompanion Function({
  Value<String> consentId,
  Value<String> payload,
  Value<int> syncedAt,
  Value<int> rowid,
});

class $$SyncedConsentsTableFilterComposer extends Composer<_$AppDatabase, $SyncedConsentsTable> {
  $$SyncedConsentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get consentId =>
      $composableBuilder(column: $table.consentId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => ColumnFilters(column));
}

class $$SyncedConsentsTableOrderingComposer extends Composer<_$AppDatabase, $SyncedConsentsTable> {
  $$SyncedConsentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get consentId =>
      $composableBuilder(column: $table.consentId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => ColumnOrderings(column));
}

class $$SyncedConsentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncedConsentsTable> {
  $$SyncedConsentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get consentId =>
      $composableBuilder(column: $table.consentId, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$SyncedConsentsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncedConsentsTable,
    SyncedConsentRow,
    $$SyncedConsentsTableFilterComposer,
    $$SyncedConsentsTableOrderingComposer,
    $$SyncedConsentsTableAnnotationComposer,
    $$SyncedConsentsTableCreateCompanionBuilder,
    $$SyncedConsentsTableUpdateCompanionBuilder,
    (SyncedConsentRow, BaseReferences<_$AppDatabase, $SyncedConsentsTable, SyncedConsentRow>),
    SyncedConsentRow,
    PrefetchHooks Function()> {
  $$SyncedConsentsTableTableManager(_$AppDatabase db, $SyncedConsentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncedConsentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncedConsentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncedConsentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> consentId = const Value.absent(),
            Value<String> payload = const Value.absent(),
            Value<int> syncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncedConsentsCompanion(
            consentId: consentId,
            payload: payload,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String consentId,
            required String payload,
            required int syncedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncedConsentsCompanion.insert(
            consentId: consentId,
            payload: payload,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable(table), BaseReferences(db, table, e))).toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncedConsentsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SyncedConsentsTable,
    SyncedConsentRow,
    $$SyncedConsentsTableFilterComposer,
    $$SyncedConsentsTableOrderingComposer,
    $$SyncedConsentsTableAnnotationComposer,
    $$SyncedConsentsTableCreateCompanionBuilder,
    $$SyncedConsentsTableUpdateCompanionBuilder,
    (SyncedConsentRow, BaseReferences<_$AppDatabase, $SyncedConsentsTable, SyncedConsentRow>),
    SyncedConsentRow,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$VaultsTableTableManager get vaults => $$VaultsTableTableManager(_db, _db.vaults);
  $$VaultRelaysTableTableManager get vaultRelays =>
      $$VaultRelaysTableTableManager(_db, _db.vaultRelays);
  $$OwnedVaultsTableTableManager get ownedVaults =>
      $$OwnedVaultsTableTableManager(_db, _db.ownedVaults);
  $$StewardsTableTableManager get stewards => $$StewardsTableTableManager(_db, _db.stewards);
  $$InvitationsTableTableManager get invitations =>
      $$InvitationsTableTableManager(_db, _db.invitations);
  $$DistributionsTableTableManager get distributions =>
      $$DistributionsTableTableManager(_db, _db.distributions);
  $$DistributionSharesTableTableManager get distributionShares =>
      $$DistributionSharesTableTableManager(_db, _db.distributionShares);
  $$HeldSharesTableTableManager get heldShares =>
      $$HeldSharesTableTableManager(_db, _db.heldShares);
  $$RecoveryRequestsTableTableManager get recoveryRequests =>
      $$RecoveryRequestsTableTableManager(_db, _db.recoveryRequests);
  $$RecoveryRequestParticipantsTableTableManager get recoveryRequestParticipants =>
      $$RecoveryRequestParticipantsTableTableManager(_db, _db.recoveryRequestParticipants);
  $$RecoveryResponsesTableTableManager get recoveryResponses =>
      $$RecoveryResponsesTableTableManager(_db, _db.recoveryResponses);
  $$OutboxTableTableManager get outbox => $$OutboxTableTableManager(_db, _db.outbox);
  $$OutboxRelaysTableTableManager get outboxRelays =>
      $$OutboxRelaysTableTableManager(_db, _db.outboxRelays);
  $$KvTableTableManager get kv => $$KvTableTableManager(_db, _db.kv);
  $$ViewedNotificationsTableTableManager get viewedNotifications =>
      $$ViewedNotificationsTableTableManager(_db, _db.viewedNotifications);
  $$SyncedConsentsTableTableManager get syncedConsents =>
      $$SyncedConsentsTableTableManager(_db, _db.syncedConsents);
}
