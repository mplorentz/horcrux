// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'steward.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$Steward {
  String get id => throw _privateConstructorUsedError; // Unique identifier for this steward
  String? get pubkey =>
      throw _privateConstructorUsedError; // Hex format - nullable for invited stewards
  String? get name => throw _privateConstructorUsedError;
  String? get inviteCode =>
      throw _privateConstructorUsedError; // Invitation code for invited stewards (before they accept)
  StewardStatus get status => throw _privateConstructorUsedError;
  DateTime? get lastSeen => throw _privateConstructorUsedError;
  String? get keyShare => throw _privateConstructorUsedError;
  String? get giftWrapEventId => throw _privateConstructorUsedError;
  DateTime? get acknowledgedAt => throw _privateConstructorUsedError;
  String? get acknowledgmentEventId => throw _privateConstructorUsedError;
  int? get acknowledgedDistributionVersion =>
      throw _privateConstructorUsedError; // Version tracking for redistribution detection (nullable for backward compatibility)
  bool get isOwner =>
      throw _privateConstructorUsedError; // True when this steward is the vault owner
  String? get contactInfo => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $StewardCopyWith<Steward> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StewardCopyWith<$Res> {
  factory $StewardCopyWith(Steward value, $Res Function(Steward) then) =
      _$StewardCopyWithImpl<$Res, Steward>;
  @useResult
  $Res call(
      {String id,
      String? pubkey,
      String? name,
      String? inviteCode,
      StewardStatus status,
      DateTime? lastSeen,
      String? keyShare,
      String? giftWrapEventId,
      DateTime? acknowledgedAt,
      String? acknowledgmentEventId,
      int? acknowledgedDistributionVersion,
      bool isOwner,
      String? contactInfo});
}

/// @nodoc
class _$StewardCopyWithImpl<$Res, $Val extends Steward> implements $StewardCopyWith<$Res> {
  _$StewardCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? pubkey = freezed,
    Object? name = freezed,
    Object? inviteCode = freezed,
    Object? status = null,
    Object? lastSeen = freezed,
    Object? keyShare = freezed,
    Object? giftWrapEventId = freezed,
    Object? acknowledgedAt = freezed,
    Object? acknowledgmentEventId = freezed,
    Object? acknowledgedDistributionVersion = freezed,
    Object? isOwner = null,
    Object? contactInfo = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      pubkey: freezed == pubkey
          ? _value.pubkey
          : pubkey // ignore: cast_nullable_to_non_nullable
              as String?,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      inviteCode: freezed == inviteCode
          ? _value.inviteCode
          : inviteCode // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as StewardStatus,
      lastSeen: freezed == lastSeen
          ? _value.lastSeen
          : lastSeen // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      keyShare: freezed == keyShare
          ? _value.keyShare
          : keyShare // ignore: cast_nullable_to_non_nullable
              as String?,
      giftWrapEventId: freezed == giftWrapEventId
          ? _value.giftWrapEventId
          : giftWrapEventId // ignore: cast_nullable_to_non_nullable
              as String?,
      acknowledgedAt: freezed == acknowledgedAt
          ? _value.acknowledgedAt
          : acknowledgedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      acknowledgmentEventId: freezed == acknowledgmentEventId
          ? _value.acknowledgmentEventId
          : acknowledgmentEventId // ignore: cast_nullable_to_non_nullable
              as String?,
      acknowledgedDistributionVersion: freezed == acknowledgedDistributionVersion
          ? _value.acknowledgedDistributionVersion
          : acknowledgedDistributionVersion // ignore: cast_nullable_to_non_nullable
              as int?,
      isOwner: null == isOwner
          ? _value.isOwner
          : isOwner // ignore: cast_nullable_to_non_nullable
              as bool,
      contactInfo: freezed == contactInfo
          ? _value.contactInfo
          : contactInfo // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$StewardImplCopyWith<$Res> implements $StewardCopyWith<$Res> {
  factory _$$StewardImplCopyWith(_$StewardImpl value, $Res Function(_$StewardImpl) then) =
      __$$StewardImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String? pubkey,
      String? name,
      String? inviteCode,
      StewardStatus status,
      DateTime? lastSeen,
      String? keyShare,
      String? giftWrapEventId,
      DateTime? acknowledgedAt,
      String? acknowledgmentEventId,
      int? acknowledgedDistributionVersion,
      bool isOwner,
      String? contactInfo});
}

/// @nodoc
class __$$StewardImplCopyWithImpl<$Res> extends _$StewardCopyWithImpl<$Res, _$StewardImpl>
    implements _$$StewardImplCopyWith<$Res> {
  __$$StewardImplCopyWithImpl(_$StewardImpl _value, $Res Function(_$StewardImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? pubkey = freezed,
    Object? name = freezed,
    Object? inviteCode = freezed,
    Object? status = null,
    Object? lastSeen = freezed,
    Object? keyShare = freezed,
    Object? giftWrapEventId = freezed,
    Object? acknowledgedAt = freezed,
    Object? acknowledgmentEventId = freezed,
    Object? acknowledgedDistributionVersion = freezed,
    Object? isOwner = null,
    Object? contactInfo = freezed,
  }) {
    return _then(_$StewardImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      pubkey: freezed == pubkey
          ? _value.pubkey
          : pubkey // ignore: cast_nullable_to_non_nullable
              as String?,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      inviteCode: freezed == inviteCode
          ? _value.inviteCode
          : inviteCode // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as StewardStatus,
      lastSeen: freezed == lastSeen
          ? _value.lastSeen
          : lastSeen // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      keyShare: freezed == keyShare
          ? _value.keyShare
          : keyShare // ignore: cast_nullable_to_non_nullable
              as String?,
      giftWrapEventId: freezed == giftWrapEventId
          ? _value.giftWrapEventId
          : giftWrapEventId // ignore: cast_nullable_to_non_nullable
              as String?,
      acknowledgedAt: freezed == acknowledgedAt
          ? _value.acknowledgedAt
          : acknowledgedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      acknowledgmentEventId: freezed == acknowledgmentEventId
          ? _value.acknowledgmentEventId
          : acknowledgmentEventId // ignore: cast_nullable_to_non_nullable
              as String?,
      acknowledgedDistributionVersion: freezed == acknowledgedDistributionVersion
          ? _value.acknowledgedDistributionVersion
          : acknowledgedDistributionVersion // ignore: cast_nullable_to_non_nullable
              as int?,
      isOwner: null == isOwner
          ? _value.isOwner
          : isOwner // ignore: cast_nullable_to_non_nullable
              as bool,
      contactInfo: freezed == contactInfo
          ? _value.contactInfo
          : contactInfo // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$StewardImpl extends _Steward {
  const _$StewardImpl(
      {required this.id,
      this.pubkey,
      this.name,
      this.inviteCode,
      required this.status,
      this.lastSeen,
      this.keyShare,
      this.giftWrapEventId,
      this.acknowledgedAt,
      this.acknowledgmentEventId,
      this.acknowledgedDistributionVersion,
      this.isOwner = false,
      this.contactInfo})
      : super._();

  @override
  final String id;
// Unique identifier for this steward
  @override
  final String? pubkey;
// Hex format - nullable for invited stewards
  @override
  final String? name;
  @override
  final String? inviteCode;
// Invitation code for invited stewards (before they accept)
  @override
  final StewardStatus status;
  @override
  final DateTime? lastSeen;
  @override
  final String? keyShare;
  @override
  final String? giftWrapEventId;
  @override
  final DateTime? acknowledgedAt;
  @override
  final String? acknowledgmentEventId;
  @override
  final int? acknowledgedDistributionVersion;
// Version tracking for redistribution detection (nullable for backward compatibility)
  @override
  @JsonKey()
  final bool isOwner;
// True when this steward is the vault owner
  @override
  final String? contactInfo;

  @override
  String toString() {
    return 'Steward(id: $id, pubkey: $pubkey, name: $name, inviteCode: $inviteCode, status: $status, lastSeen: $lastSeen, keyShare: $keyShare, giftWrapEventId: $giftWrapEventId, acknowledgedAt: $acknowledgedAt, acknowledgmentEventId: $acknowledgmentEventId, acknowledgedDistributionVersion: $acknowledgedDistributionVersion, isOwner: $isOwner, contactInfo: $contactInfo)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StewardImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.pubkey, pubkey) || other.pubkey == pubkey) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.inviteCode, inviteCode) || other.inviteCode == inviteCode) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.lastSeen, lastSeen) || other.lastSeen == lastSeen) &&
            (identical(other.keyShare, keyShare) || other.keyShare == keyShare) &&
            (identical(other.giftWrapEventId, giftWrapEventId) ||
                other.giftWrapEventId == giftWrapEventId) &&
            (identical(other.acknowledgedAt, acknowledgedAt) ||
                other.acknowledgedAt == acknowledgedAt) &&
            (identical(other.acknowledgmentEventId, acknowledgmentEventId) ||
                other.acknowledgmentEventId == acknowledgmentEventId) &&
            (identical(other.acknowledgedDistributionVersion, acknowledgedDistributionVersion) ||
                other.acknowledgedDistributionVersion == acknowledgedDistributionVersion) &&
            (identical(other.isOwner, isOwner) || other.isOwner == isOwner) &&
            (identical(other.contactInfo, contactInfo) || other.contactInfo == contactInfo));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      pubkey,
      name,
      inviteCode,
      status,
      lastSeen,
      keyShare,
      giftWrapEventId,
      acknowledgedAt,
      acknowledgmentEventId,
      acknowledgedDistributionVersion,
      isOwner,
      contactInfo);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$StewardImplCopyWith<_$StewardImpl> get copyWith =>
      __$$StewardImplCopyWithImpl<_$StewardImpl>(this, _$identity);
}

abstract class _Steward extends Steward {
  const factory _Steward(
      {required final String id,
      final String? pubkey,
      final String? name,
      final String? inviteCode,
      required final StewardStatus status,
      final DateTime? lastSeen,
      final String? keyShare,
      final String? giftWrapEventId,
      final DateTime? acknowledgedAt,
      final String? acknowledgmentEventId,
      final int? acknowledgedDistributionVersion,
      final bool isOwner,
      final String? contactInfo}) = _$StewardImpl;
  const _Steward._() : super._();

  @override
  String get id;
  @override // Unique identifier for this steward
  String? get pubkey;
  @override // Hex format - nullable for invited stewards
  String? get name;
  @override
  String? get inviteCode;
  @override // Invitation code for invited stewards (before they accept)
  StewardStatus get status;
  @override
  DateTime? get lastSeen;
  @override
  String? get keyShare;
  @override
  String? get giftWrapEventId;
  @override
  DateTime? get acknowledgedAt;
  @override
  String? get acknowledgmentEventId;
  @override
  int? get acknowledgedDistributionVersion;
  @override // Version tracking for redistribution detection (nullable for backward compatibility)
  bool get isOwner;
  @override // True when this steward is the vault owner
  String? get contactInfo;
  @override
  @JsonKey(ignore: true)
  _$$StewardImplCopyWith<_$StewardImpl> get copyWith => throw _privateConstructorUsedError;
}
