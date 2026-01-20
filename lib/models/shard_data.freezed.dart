// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shard_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ShardData {
  String get shard => throw _privateConstructorUsedError;
  int get threshold => throw _privateConstructorUsedError;
  int get shardIndex => throw _privateConstructorUsedError;
  int get totalShards => throw _privateConstructorUsedError;
  String get primeMod => throw _privateConstructorUsedError;
  String get creatorPubkey => throw _privateConstructorUsedError;
  int get createdAt => throw _privateConstructorUsedError; // Recovery metadata (optional fields)
  String? get vaultId => throw _privateConstructorUsedError;
  String? get vaultName => throw _privateConstructorUsedError;
  List<Map<String, String>>? get stewards =>
      throw _privateConstructorUsedError; // List of maps with 'name', 'pubkey', and optionally 'contactInfo' for OTHER stewards (excludes creatorPubkey)
  String? get ownerName => throw _privateConstructorUsedError; // Name of the vault owner (creator)
  String? get instructions => throw _privateConstructorUsedError; // Instructions for stewards
  String? get recipientPubkey => throw _privateConstructorUsedError;
  bool? get isReceived => throw _privateConstructorUsedError;
  DateTime? get receivedAt => throw _privateConstructorUsedError;
  String? get nostrEventId => throw _privateConstructorUsedError;
  List<String>? get relayUrls =>
      throw _privateConstructorUsedError; // Relay URLs from backup config for sending confirmations
  int? get distributionVersion => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $ShardDataCopyWith<ShardData> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ShardDataCopyWith<$Res> {
  factory $ShardDataCopyWith(ShardData value, $Res Function(ShardData) then) =
      _$ShardDataCopyWithImpl<$Res, ShardData>;
  @useResult
  $Res call(
      {String shard,
      int threshold,
      int shardIndex,
      int totalShards,
      String primeMod,
      String creatorPubkey,
      int createdAt,
      String? vaultId,
      String? vaultName,
      List<Map<String, String>>? stewards,
      String? ownerName,
      String? instructions,
      String? recipientPubkey,
      bool? isReceived,
      DateTime? receivedAt,
      String? nostrEventId,
      List<String>? relayUrls,
      int? distributionVersion});
}

/// @nodoc
class _$ShardDataCopyWithImpl<$Res, $Val extends ShardData> implements $ShardDataCopyWith<$Res> {
  _$ShardDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? shard = null,
    Object? threshold = null,
    Object? shardIndex = null,
    Object? totalShards = null,
    Object? primeMod = null,
    Object? creatorPubkey = null,
    Object? createdAt = null,
    Object? vaultId = freezed,
    Object? vaultName = freezed,
    Object? stewards = freezed,
    Object? ownerName = freezed,
    Object? instructions = freezed,
    Object? recipientPubkey = freezed,
    Object? isReceived = freezed,
    Object? receivedAt = freezed,
    Object? nostrEventId = freezed,
    Object? relayUrls = freezed,
    Object? distributionVersion = freezed,
  }) {
    return _then(_value.copyWith(
      shard: null == shard
          ? _value.shard
          : shard // ignore: cast_nullable_to_non_nullable
              as String,
      threshold: null == threshold
          ? _value.threshold
          : threshold // ignore: cast_nullable_to_non_nullable
              as int,
      shardIndex: null == shardIndex
          ? _value.shardIndex
          : shardIndex // ignore: cast_nullable_to_non_nullable
              as int,
      totalShards: null == totalShards
          ? _value.totalShards
          : totalShards // ignore: cast_nullable_to_non_nullable
              as int,
      primeMod: null == primeMod
          ? _value.primeMod
          : primeMod // ignore: cast_nullable_to_non_nullable
              as String,
      creatorPubkey: null == creatorPubkey
          ? _value.creatorPubkey
          : creatorPubkey // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as int,
      vaultId: freezed == vaultId
          ? _value.vaultId
          : vaultId // ignore: cast_nullable_to_non_nullable
              as String?,
      vaultName: freezed == vaultName
          ? _value.vaultName
          : vaultName // ignore: cast_nullable_to_non_nullable
              as String?,
      stewards: freezed == stewards
          ? _value.stewards
          : stewards // ignore: cast_nullable_to_non_nullable
              as List<Map<String, String>>?,
      ownerName: freezed == ownerName
          ? _value.ownerName
          : ownerName // ignore: cast_nullable_to_non_nullable
              as String?,
      instructions: freezed == instructions
          ? _value.instructions
          : instructions // ignore: cast_nullable_to_non_nullable
              as String?,
      recipientPubkey: freezed == recipientPubkey
          ? _value.recipientPubkey
          : recipientPubkey // ignore: cast_nullable_to_non_nullable
              as String?,
      isReceived: freezed == isReceived
          ? _value.isReceived
          : isReceived // ignore: cast_nullable_to_non_nullable
              as bool?,
      receivedAt: freezed == receivedAt
          ? _value.receivedAt
          : receivedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      nostrEventId: freezed == nostrEventId
          ? _value.nostrEventId
          : nostrEventId // ignore: cast_nullable_to_non_nullable
              as String?,
      relayUrls: freezed == relayUrls
          ? _value.relayUrls
          : relayUrls // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      distributionVersion: freezed == distributionVersion
          ? _value.distributionVersion
          : distributionVersion // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ShardDataImplCopyWith<$Res> implements $ShardDataCopyWith<$Res> {
  factory _$$ShardDataImplCopyWith(_$ShardDataImpl value, $Res Function(_$ShardDataImpl) then) =
      __$$ShardDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String shard,
      int threshold,
      int shardIndex,
      int totalShards,
      String primeMod,
      String creatorPubkey,
      int createdAt,
      String? vaultId,
      String? vaultName,
      List<Map<String, String>>? stewards,
      String? ownerName,
      String? instructions,
      String? recipientPubkey,
      bool? isReceived,
      DateTime? receivedAt,
      String? nostrEventId,
      List<String>? relayUrls,
      int? distributionVersion});
}

/// @nodoc
class __$$ShardDataImplCopyWithImpl<$Res> extends _$ShardDataCopyWithImpl<$Res, _$ShardDataImpl>
    implements _$$ShardDataImplCopyWith<$Res> {
  __$$ShardDataImplCopyWithImpl(_$ShardDataImpl _value, $Res Function(_$ShardDataImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? shard = null,
    Object? threshold = null,
    Object? shardIndex = null,
    Object? totalShards = null,
    Object? primeMod = null,
    Object? creatorPubkey = null,
    Object? createdAt = null,
    Object? vaultId = freezed,
    Object? vaultName = freezed,
    Object? stewards = freezed,
    Object? ownerName = freezed,
    Object? instructions = freezed,
    Object? recipientPubkey = freezed,
    Object? isReceived = freezed,
    Object? receivedAt = freezed,
    Object? nostrEventId = freezed,
    Object? relayUrls = freezed,
    Object? distributionVersion = freezed,
  }) {
    return _then(_$ShardDataImpl(
      shard: null == shard
          ? _value.shard
          : shard // ignore: cast_nullable_to_non_nullable
              as String,
      threshold: null == threshold
          ? _value.threshold
          : threshold // ignore: cast_nullable_to_non_nullable
              as int,
      shardIndex: null == shardIndex
          ? _value.shardIndex
          : shardIndex // ignore: cast_nullable_to_non_nullable
              as int,
      totalShards: null == totalShards
          ? _value.totalShards
          : totalShards // ignore: cast_nullable_to_non_nullable
              as int,
      primeMod: null == primeMod
          ? _value.primeMod
          : primeMod // ignore: cast_nullable_to_non_nullable
              as String,
      creatorPubkey: null == creatorPubkey
          ? _value.creatorPubkey
          : creatorPubkey // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as int,
      vaultId: freezed == vaultId
          ? _value.vaultId
          : vaultId // ignore: cast_nullable_to_non_nullable
              as String?,
      vaultName: freezed == vaultName
          ? _value.vaultName
          : vaultName // ignore: cast_nullable_to_non_nullable
              as String?,
      stewards: freezed == stewards
          ? _value._stewards
          : stewards // ignore: cast_nullable_to_non_nullable
              as List<Map<String, String>>?,
      ownerName: freezed == ownerName
          ? _value.ownerName
          : ownerName // ignore: cast_nullable_to_non_nullable
              as String?,
      instructions: freezed == instructions
          ? _value.instructions
          : instructions // ignore: cast_nullable_to_non_nullable
              as String?,
      recipientPubkey: freezed == recipientPubkey
          ? _value.recipientPubkey
          : recipientPubkey // ignore: cast_nullable_to_non_nullable
              as String?,
      isReceived: freezed == isReceived
          ? _value.isReceived
          : isReceived // ignore: cast_nullable_to_non_nullable
              as bool?,
      receivedAt: freezed == receivedAt
          ? _value.receivedAt
          : receivedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      nostrEventId: freezed == nostrEventId
          ? _value.nostrEventId
          : nostrEventId // ignore: cast_nullable_to_non_nullable
              as String?,
      relayUrls: freezed == relayUrls
          ? _value._relayUrls
          : relayUrls // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      distributionVersion: freezed == distributionVersion
          ? _value.distributionVersion
          : distributionVersion // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc

class _$ShardDataImpl extends _ShardData {
  const _$ShardDataImpl(
      {required this.shard,
      required this.threshold,
      required this.shardIndex,
      required this.totalShards,
      required this.primeMod,
      required this.creatorPubkey,
      required this.createdAt,
      this.vaultId,
      this.vaultName,
      final List<Map<String, String>>? stewards,
      this.ownerName,
      this.instructions,
      this.recipientPubkey,
      this.isReceived,
      this.receivedAt,
      this.nostrEventId,
      final List<String>? relayUrls,
      this.distributionVersion})
      : _stewards = stewards,
        _relayUrls = relayUrls,
        super._();

  @override
  final String shard;
  @override
  final int threshold;
  @override
  final int shardIndex;
  @override
  final int totalShards;
  @override
  final String primeMod;
  @override
  final String creatorPubkey;
  @override
  final int createdAt;
// Recovery metadata (optional fields)
  @override
  final String? vaultId;
  @override
  final String? vaultName;
  final List<Map<String, String>>? _stewards;
  @override
  List<Map<String, String>>? get stewards {
    final value = _stewards;
    if (value == null) return null;
    if (_stewards is EqualUnmodifiableListView) return _stewards;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

// List of maps with 'name', 'pubkey', and optionally 'contactInfo' for OTHER stewards (excludes creatorPubkey)
  @override
  final String? ownerName;
// Name of the vault owner (creator)
  @override
  final String? instructions;
// Instructions for stewards
  @override
  final String? recipientPubkey;
  @override
  final bool? isReceived;
  @override
  final DateTime? receivedAt;
  @override
  final String? nostrEventId;
  final List<String>? _relayUrls;
  @override
  List<String>? get relayUrls {
    final value = _relayUrls;
    if (value == null) return null;
    if (_relayUrls is EqualUnmodifiableListView) return _relayUrls;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

// Relay URLs from backup config for sending confirmations
  @override
  final int? distributionVersion;

  @override
  String toString() {
    return 'ShardData(shard: $shard, threshold: $threshold, shardIndex: $shardIndex, totalShards: $totalShards, primeMod: $primeMod, creatorPubkey: $creatorPubkey, createdAt: $createdAt, vaultId: $vaultId, vaultName: $vaultName, stewards: $stewards, ownerName: $ownerName, instructions: $instructions, recipientPubkey: $recipientPubkey, isReceived: $isReceived, receivedAt: $receivedAt, nostrEventId: $nostrEventId, relayUrls: $relayUrls, distributionVersion: $distributionVersion)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ShardDataImpl &&
            (identical(other.shard, shard) || other.shard == shard) &&
            (identical(other.threshold, threshold) || other.threshold == threshold) &&
            (identical(other.shardIndex, shardIndex) || other.shardIndex == shardIndex) &&
            (identical(other.totalShards, totalShards) || other.totalShards == totalShards) &&
            (identical(other.primeMod, primeMod) || other.primeMod == primeMod) &&
            (identical(other.creatorPubkey, creatorPubkey) ||
                other.creatorPubkey == creatorPubkey) &&
            (identical(other.createdAt, createdAt) || other.createdAt == createdAt) &&
            (identical(other.vaultId, vaultId) || other.vaultId == vaultId) &&
            (identical(other.vaultName, vaultName) || other.vaultName == vaultName) &&
            const DeepCollectionEquality().equals(other._stewards, _stewards) &&
            (identical(other.ownerName, ownerName) || other.ownerName == ownerName) &&
            (identical(other.instructions, instructions) || other.instructions == instructions) &&
            (identical(other.recipientPubkey, recipientPubkey) ||
                other.recipientPubkey == recipientPubkey) &&
            (identical(other.isReceived, isReceived) || other.isReceived == isReceived) &&
            (identical(other.receivedAt, receivedAt) || other.receivedAt == receivedAt) &&
            (identical(other.nostrEventId, nostrEventId) || other.nostrEventId == nostrEventId) &&
            const DeepCollectionEquality().equals(other._relayUrls, _relayUrls) &&
            (identical(other.distributionVersion, distributionVersion) ||
                other.distributionVersion == distributionVersion));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      shard,
      threshold,
      shardIndex,
      totalShards,
      primeMod,
      creatorPubkey,
      createdAt,
      vaultId,
      vaultName,
      const DeepCollectionEquality().hash(_stewards),
      ownerName,
      instructions,
      recipientPubkey,
      isReceived,
      receivedAt,
      nostrEventId,
      const DeepCollectionEquality().hash(_relayUrls),
      distributionVersion);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ShardDataImplCopyWith<_$ShardDataImpl> get copyWith =>
      __$$ShardDataImplCopyWithImpl<_$ShardDataImpl>(this, _$identity);
}

abstract class _ShardData extends ShardData {
  const factory _ShardData(
      {required final String shard,
      required final int threshold,
      required final int shardIndex,
      required final int totalShards,
      required final String primeMod,
      required final String creatorPubkey,
      required final int createdAt,
      final String? vaultId,
      final String? vaultName,
      final List<Map<String, String>>? stewards,
      final String? ownerName,
      final String? instructions,
      final String? recipientPubkey,
      final bool? isReceived,
      final DateTime? receivedAt,
      final String? nostrEventId,
      final List<String>? relayUrls,
      final int? distributionVersion}) = _$ShardDataImpl;
  const _ShardData._() : super._();

  @override
  String get shard;
  @override
  int get threshold;
  @override
  int get shardIndex;
  @override
  int get totalShards;
  @override
  String get primeMod;
  @override
  String get creatorPubkey;
  @override
  int get createdAt;
  @override // Recovery metadata (optional fields)
  String? get vaultId;
  @override
  String? get vaultName;
  @override
  List<Map<String, String>>? get stewards;
  @override // List of maps with 'name', 'pubkey', and optionally 'contactInfo' for OTHER stewards (excludes creatorPubkey)
  String? get ownerName;
  @override // Name of the vault owner (creator)
  String? get instructions;
  @override // Instructions for stewards
  String? get recipientPubkey;
  @override
  bool? get isReceived;
  @override
  DateTime? get receivedAt;
  @override
  String? get nostrEventId;
  @override
  List<String>? get relayUrls;
  @override // Relay URLs from backup config for sending confirmations
  int? get distributionVersion;
  @override
  @JsonKey(ignore: true)
  _$$ShardDataImplCopyWith<_$ShardDataImpl> get copyWith => throw _privateConstructorUsedError;
}
