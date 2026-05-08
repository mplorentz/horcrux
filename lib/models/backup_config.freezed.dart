// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'backup_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$BackupConfig {
  String get vaultId => throw _privateConstructorUsedError;
  int get threshold => throw _privateConstructorUsedError;
  List<Steward> get stewards => throw _privateConstructorUsedError;
  List<String> get relays => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  int get distributionVersion => throw _privateConstructorUsedError;
  String? get instructions => throw _privateConstructorUsedError;

  /// Create a copy of BackupConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BackupConfigCopyWith<BackupConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BackupConfigCopyWith<$Res> {
  factory $BackupConfigCopyWith(
          BackupConfig value, $Res Function(BackupConfig) then) =
      _$BackupConfigCopyWithImpl<$Res, BackupConfig>;
  @useResult
  $Res call(
      {String vaultId,
      int threshold,
      List<Steward> stewards,
      List<String> relays,
      DateTime createdAt,
      int distributionVersion,
      String? instructions});
}

/// @nodoc
class _$BackupConfigCopyWithImpl<$Res, $Val extends BackupConfig>
    implements $BackupConfigCopyWith<$Res> {
  _$BackupConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BackupConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? vaultId = null,
    Object? threshold = null,
    Object? stewards = null,
    Object? relays = null,
    Object? createdAt = null,
    Object? distributionVersion = null,
    Object? instructions = freezed,
  }) {
    return _then(_value.copyWith(
      vaultId: null == vaultId
          ? _value.vaultId
          : vaultId // ignore: cast_nullable_to_non_nullable
              as String,
      threshold: null == threshold
          ? _value.threshold
          : threshold // ignore: cast_nullable_to_non_nullable
              as int,
      stewards: null == stewards
          ? _value.stewards
          : stewards // ignore: cast_nullable_to_non_nullable
              as List<Steward>,
      relays: null == relays
          ? _value.relays
          : relays // ignore: cast_nullable_to_non_nullable
              as List<String>,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      distributionVersion: null == distributionVersion
          ? _value.distributionVersion
          : distributionVersion // ignore: cast_nullable_to_non_nullable
              as int,
      instructions: freezed == instructions
          ? _value.instructions
          : instructions // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BackupConfigImplCopyWith<$Res>
    implements $BackupConfigCopyWith<$Res> {
  factory _$$BackupConfigImplCopyWith(
          _$BackupConfigImpl value, $Res Function(_$BackupConfigImpl) then) =
      __$$BackupConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String vaultId,
      int threshold,
      List<Steward> stewards,
      List<String> relays,
      DateTime createdAt,
      int distributionVersion,
      String? instructions});
}

/// @nodoc
class __$$BackupConfigImplCopyWithImpl<$Res>
    extends _$BackupConfigCopyWithImpl<$Res, _$BackupConfigImpl>
    implements _$$BackupConfigImplCopyWith<$Res> {
  __$$BackupConfigImplCopyWithImpl(
      _$BackupConfigImpl _value, $Res Function(_$BackupConfigImpl) _then)
      : super(_value, _then);

  /// Create a copy of BackupConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? vaultId = null,
    Object? threshold = null,
    Object? stewards = null,
    Object? relays = null,
    Object? createdAt = null,
    Object? distributionVersion = null,
    Object? instructions = freezed,
  }) {
    return _then(_$BackupConfigImpl(
      vaultId: null == vaultId
          ? _value.vaultId
          : vaultId // ignore: cast_nullable_to_non_nullable
              as String,
      threshold: null == threshold
          ? _value.threshold
          : threshold // ignore: cast_nullable_to_non_nullable
              as int,
      stewards: null == stewards
          ? _value._stewards
          : stewards // ignore: cast_nullable_to_non_nullable
              as List<Steward>,
      relays: null == relays
          ? _value._relays
          : relays // ignore: cast_nullable_to_non_nullable
              as List<String>,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      distributionVersion: null == distributionVersion
          ? _value.distributionVersion
          : distributionVersion // ignore: cast_nullable_to_non_nullable
              as int,
      instructions: freezed == instructions
          ? _value.instructions
          : instructions // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$BackupConfigImpl extends _BackupConfig {
  const _$BackupConfigImpl(
      {required this.vaultId,
      required this.threshold,
      required final List<Steward> stewards,
      required final List<String> relays,
      required this.createdAt,
      required this.distributionVersion,
      this.instructions})
      : _stewards = stewards,
        _relays = relays,
        super._();

  @override
  final String vaultId;
  @override
  final int threshold;
  final List<Steward> _stewards;
  @override
  List<Steward> get stewards {
    if (_stewards is EqualUnmodifiableListView) return _stewards;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_stewards);
  }

  final List<String> _relays;
  @override
  List<String> get relays {
    if (_relays is EqualUnmodifiableListView) return _relays;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_relays);
  }

  @override
  final DateTime createdAt;
  @override
  final int distributionVersion;
  @override
  final String? instructions;

  @override
  String toString() {
    return 'BackupConfig(vaultId: $vaultId, threshold: $threshold, stewards: $stewards, relays: $relays, createdAt: $createdAt, distributionVersion: $distributionVersion, instructions: $instructions)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BackupConfigImpl &&
            (identical(other.vaultId, vaultId) || other.vaultId == vaultId) &&
            (identical(other.threshold, threshold) ||
                other.threshold == threshold) &&
            const DeepCollectionEquality().equals(other._stewards, _stewards) &&
            const DeepCollectionEquality().equals(other._relays, _relays) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.distributionVersion, distributionVersion) ||
                other.distributionVersion == distributionVersion) &&
            (identical(other.instructions, instructions) ||
                other.instructions == instructions));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      vaultId,
      threshold,
      const DeepCollectionEquality().hash(_stewards),
      const DeepCollectionEquality().hash(_relays),
      createdAt,
      distributionVersion,
      instructions);

  /// Create a copy of BackupConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BackupConfigImplCopyWith<_$BackupConfigImpl> get copyWith =>
      __$$BackupConfigImplCopyWithImpl<_$BackupConfigImpl>(this, _$identity);
}

abstract class _BackupConfig extends BackupConfig {
  const factory _BackupConfig(
      {required final String vaultId,
      required final int threshold,
      required final List<Steward> stewards,
      required final List<String> relays,
      required final DateTime createdAt,
      required final int distributionVersion,
      final String? instructions}) = _$BackupConfigImpl;
  const _BackupConfig._() : super._();

  @override
  String get vaultId;
  @override
  int get threshold;
  @override
  List<Steward> get stewards;
  @override
  List<String> get relays;
  @override
  DateTime get createdAt;
  @override
  int get distributionVersion;
  @override
  String? get instructions;

  /// Create a copy of BackupConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BackupConfigImplCopyWith<_$BackupConfigImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
