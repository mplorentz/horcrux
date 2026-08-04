// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'vault.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$Vault {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  String get ownerPubkey => throw _privateConstructorUsedError;
  String? get ownerName => throw _privateConstructorUsedError;
  List<RecoveryRequest> get recoveryRequests =>
      throw _privateConstructorUsedError;
  BackupConfig? get backupConfig => throw _privateConstructorUsedError;
  DateTime? get archivedAt => throw _privateConstructorUsedError;
  String? get archivedReason =>
      throw _privateConstructorUsedError; // Whether the vault owner has opted this vault into push notifications.
//
// This is independent of the per-user global opt-in (see
// `PushNotificationReceiver.optInFlagKey`): a user who has never opted
// into push notifications will simply never send or receive any, even
// for vaults where `pushEnabled` is `true`.
//
// Defaults to `true` for newly-created vaults (set on the recovery plan
// screen) and `false` for vaults persisted before this field existed --
// legacy vaults stay off until the owner explicitly turns push on.
  bool get pushEnabled => throw _privateConstructorUsedError;

  /// Create a copy of Vault
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VaultCopyWith<Vault> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VaultCopyWith<$Res> {
  factory $VaultCopyWith(Vault value, $Res Function(Vault) then) =
      _$VaultCopyWithImpl<$Res, Vault>;
  @useResult
  $Res call(
      {String id,
      String name,
      DateTime createdAt,
      String ownerPubkey,
      String? ownerName,
      List<RecoveryRequest> recoveryRequests,
      BackupConfig? backupConfig,
      DateTime? archivedAt,
      String? archivedReason,
      bool pushEnabled});

  $BackupConfigCopyWith<$Res>? get backupConfig;
}

/// @nodoc
class _$VaultCopyWithImpl<$Res, $Val extends Vault>
    implements $VaultCopyWith<$Res> {
  _$VaultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Vault
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? createdAt = null,
    Object? ownerPubkey = null,
    Object? ownerName = freezed,
    Object? recoveryRequests = null,
    Object? backupConfig = freezed,
    Object? archivedAt = freezed,
    Object? archivedReason = freezed,
    Object? pushEnabled = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      ownerPubkey: null == ownerPubkey
          ? _value.ownerPubkey
          : ownerPubkey // ignore: cast_nullable_to_non_nullable
              as String,
      ownerName: freezed == ownerName
          ? _value.ownerName
          : ownerName // ignore: cast_nullable_to_non_nullable
              as String?,
      recoveryRequests: null == recoveryRequests
          ? _value.recoveryRequests
          : recoveryRequests // ignore: cast_nullable_to_non_nullable
              as List<RecoveryRequest>,
      backupConfig: freezed == backupConfig
          ? _value.backupConfig
          : backupConfig // ignore: cast_nullable_to_non_nullable
              as BackupConfig?,
      archivedAt: freezed == archivedAt
          ? _value.archivedAt
          : archivedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      archivedReason: freezed == archivedReason
          ? _value.archivedReason
          : archivedReason // ignore: cast_nullable_to_non_nullable
              as String?,
      pushEnabled: null == pushEnabled
          ? _value.pushEnabled
          : pushEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }

  /// Create a copy of Vault
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $BackupConfigCopyWith<$Res>? get backupConfig {
    if (_value.backupConfig == null) {
      return null;
    }

    return $BackupConfigCopyWith<$Res>(_value.backupConfig!, (value) {
      return _then(_value.copyWith(backupConfig: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$VaultImplCopyWith<$Res> implements $VaultCopyWith<$Res> {
  factory _$$VaultImplCopyWith(
          _$VaultImpl value, $Res Function(_$VaultImpl) then) =
      __$$VaultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      DateTime createdAt,
      String ownerPubkey,
      String? ownerName,
      List<RecoveryRequest> recoveryRequests,
      BackupConfig? backupConfig,
      DateTime? archivedAt,
      String? archivedReason,
      bool pushEnabled});

  @override
  $BackupConfigCopyWith<$Res>? get backupConfig;
}

/// @nodoc
class __$$VaultImplCopyWithImpl<$Res>
    extends _$VaultCopyWithImpl<$Res, _$VaultImpl>
    implements _$$VaultImplCopyWith<$Res> {
  __$$VaultImplCopyWithImpl(
      _$VaultImpl _value, $Res Function(_$VaultImpl) _then)
      : super(_value, _then);

  /// Create a copy of Vault
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? createdAt = null,
    Object? ownerPubkey = null,
    Object? ownerName = freezed,
    Object? recoveryRequests = null,
    Object? backupConfig = freezed,
    Object? archivedAt = freezed,
    Object? archivedReason = freezed,
    Object? pushEnabled = null,
  }) {
    return _then(_$VaultImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      ownerPubkey: null == ownerPubkey
          ? _value.ownerPubkey
          : ownerPubkey // ignore: cast_nullable_to_non_nullable
              as String,
      ownerName: freezed == ownerName
          ? _value.ownerName
          : ownerName // ignore: cast_nullable_to_non_nullable
              as String?,
      recoveryRequests: null == recoveryRequests
          ? _value._recoveryRequests
          : recoveryRequests // ignore: cast_nullable_to_non_nullable
              as List<RecoveryRequest>,
      backupConfig: freezed == backupConfig
          ? _value.backupConfig
          : backupConfig // ignore: cast_nullable_to_non_nullable
              as BackupConfig?,
      archivedAt: freezed == archivedAt
          ? _value.archivedAt
          : archivedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      archivedReason: freezed == archivedReason
          ? _value.archivedReason
          : archivedReason // ignore: cast_nullable_to_non_nullable
              as String?,
      pushEnabled: null == pushEnabled
          ? _value.pushEnabled
          : pushEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$VaultImpl extends _Vault {
  const _$VaultImpl(
      {required this.id,
      required this.name,
      required this.createdAt,
      required this.ownerPubkey,
      this.ownerName,
      final List<RecoveryRequest> recoveryRequests = const [],
      this.backupConfig,
      this.archivedAt,
      this.archivedReason,
      this.pushEnabled = true})
      : _recoveryRequests = recoveryRequests,
        super._();

  @override
  final String id;
  @override
  final String name;
  @override
  final DateTime createdAt;
  @override
  final String ownerPubkey;
  @override
  final String? ownerName;
  final List<RecoveryRequest> _recoveryRequests;
  @override
  @JsonKey()
  List<RecoveryRequest> get recoveryRequests {
    if (_recoveryRequests is EqualUnmodifiableListView)
      return _recoveryRequests;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_recoveryRequests);
  }

  @override
  final BackupConfig? backupConfig;
  @override
  final DateTime? archivedAt;
  @override
  final String? archivedReason;
// Whether the vault owner has opted this vault into push notifications.
//
// This is independent of the per-user global opt-in (see
// `PushNotificationReceiver.optInFlagKey`): a user who has never opted
// into push notifications will simply never send or receive any, even
// for vaults where `pushEnabled` is `true`.
//
// Defaults to `true` for newly-created vaults (set on the recovery plan
// screen) and `false` for vaults persisted before this field existed --
// legacy vaults stay off until the owner explicitly turns push on.
  @override
  @JsonKey()
  final bool pushEnabled;

  @override
  String toString() {
    return 'Vault(id: $id, name: $name, createdAt: $createdAt, ownerPubkey: $ownerPubkey, ownerName: $ownerName, recoveryRequests: $recoveryRequests, backupConfig: $backupConfig, archivedAt: $archivedAt, archivedReason: $archivedReason, pushEnabled: $pushEnabled)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VaultImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.ownerPubkey, ownerPubkey) ||
                other.ownerPubkey == ownerPubkey) &&
            (identical(other.ownerName, ownerName) ||
                other.ownerName == ownerName) &&
            const DeepCollectionEquality()
                .equals(other._recoveryRequests, _recoveryRequests) &&
            (identical(other.backupConfig, backupConfig) ||
                other.backupConfig == backupConfig) &&
            (identical(other.archivedAt, archivedAt) ||
                other.archivedAt == archivedAt) &&
            (identical(other.archivedReason, archivedReason) ||
                other.archivedReason == archivedReason) &&
            (identical(other.pushEnabled, pushEnabled) ||
                other.pushEnabled == pushEnabled));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      createdAt,
      ownerPubkey,
      ownerName,
      const DeepCollectionEquality().hash(_recoveryRequests),
      backupConfig,
      archivedAt,
      archivedReason,
      pushEnabled);

  /// Create a copy of Vault
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VaultImplCopyWith<_$VaultImpl> get copyWith =>
      __$$VaultImplCopyWithImpl<_$VaultImpl>(this, _$identity);
}

abstract class _Vault extends Vault {
  const factory _Vault(
      {required final String id,
      required final String name,
      required final DateTime createdAt,
      required final String ownerPubkey,
      final String? ownerName,
      final List<RecoveryRequest> recoveryRequests,
      final BackupConfig? backupConfig,
      final DateTime? archivedAt,
      final String? archivedReason,
      final bool pushEnabled}) = _$VaultImpl;
  const _Vault._() : super._();

  @override
  String get id;
  @override
  String get name;
  @override
  DateTime get createdAt;
  @override
  String get ownerPubkey;
  @override
  String? get ownerName;
  @override
  List<RecoveryRequest> get recoveryRequests;
  @override
  BackupConfig? get backupConfig;
  @override
  DateTime? get archivedAt;
  @override
  String?
      get archivedReason; // Whether the vault owner has opted this vault into push notifications.
//
// This is independent of the per-user global opt-in (see
// `PushNotificationReceiver.optInFlagKey`): a user who has never opted
// into push notifications will simply never send or receive any, even
// for vaults where `pushEnabled` is `true`.
//
// Defaults to `true` for newly-created vaults (set on the recovery plan
// screen) and `false` for vaults persisted before this field existed --
// legacy vaults stay off until the owner explicitly turns push on.
  @override
  bool get pushEnabled;

  /// Create a copy of Vault
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VaultImplCopyWith<_$VaultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
