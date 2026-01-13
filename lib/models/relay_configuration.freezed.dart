// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'relay_configuration.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$RelayConfiguration {
  String get id => throw _privateConstructorUsedError;
  String get url => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  bool get isEnabled => throw _privateConstructorUsedError;
  DateTime? get lastScanned => throw _privateConstructorUsedError;
  Duration? get scanInterval => throw _privateConstructorUsedError;
  bool get isTrusted => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $RelayConfigurationCopyWith<RelayConfiguration> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RelayConfigurationCopyWith<$Res> {
  factory $RelayConfigurationCopyWith(
          RelayConfiguration value, $Res Function(RelayConfiguration) then) =
      _$RelayConfigurationCopyWithImpl<$Res, RelayConfiguration>;
  @useResult
  $Res call(
      {String id,
      String url,
      String name,
      bool isEnabled,
      DateTime? lastScanned,
      Duration? scanInterval,
      bool isTrusted});
}

/// @nodoc
class _$RelayConfigurationCopyWithImpl<$Res, $Val extends RelayConfiguration>
    implements $RelayConfigurationCopyWith<$Res> {
  _$RelayConfigurationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? url = null,
    Object? name = null,
    Object? isEnabled = null,
    Object? lastScanned = freezed,
    Object? scanInterval = freezed,
    Object? isTrusted = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      url: null == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      isEnabled: null == isEnabled
          ? _value.isEnabled
          : isEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      lastScanned: freezed == lastScanned
          ? _value.lastScanned
          : lastScanned // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      scanInterval: freezed == scanInterval
          ? _value.scanInterval
          : scanInterval // ignore: cast_nullable_to_non_nullable
              as Duration?,
      isTrusted: null == isTrusted
          ? _value.isTrusted
          : isTrusted // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RelayConfigurationImplCopyWith<$Res>
    implements $RelayConfigurationCopyWith<$Res> {
  factory _$$RelayConfigurationImplCopyWith(
          _$RelayConfigurationImpl value, $Res Function(_$RelayConfigurationImpl) then) =
      __$$RelayConfigurationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String url,
      String name,
      bool isEnabled,
      DateTime? lastScanned,
      Duration? scanInterval,
      bool isTrusted});
}

/// @nodoc
class __$$RelayConfigurationImplCopyWithImpl<$Res>
    extends _$RelayConfigurationCopyWithImpl<$Res, _$RelayConfigurationImpl>
    implements _$$RelayConfigurationImplCopyWith<$Res> {
  __$$RelayConfigurationImplCopyWithImpl(
      _$RelayConfigurationImpl _value, $Res Function(_$RelayConfigurationImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? url = null,
    Object? name = null,
    Object? isEnabled = null,
    Object? lastScanned = freezed,
    Object? scanInterval = freezed,
    Object? isTrusted = null,
  }) {
    return _then(_$RelayConfigurationImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      url: null == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      isEnabled: null == isEnabled
          ? _value.isEnabled
          : isEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      lastScanned: freezed == lastScanned
          ? _value.lastScanned
          : lastScanned // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      scanInterval: freezed == scanInterval
          ? _value.scanInterval
          : scanInterval // ignore: cast_nullable_to_non_nullable
              as Duration?,
      isTrusted: null == isTrusted
          ? _value.isTrusted
          : isTrusted // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$RelayConfigurationImpl extends _RelayConfiguration {
  const _$RelayConfigurationImpl(
      {required this.id,
      required this.url,
      required this.name,
      this.isEnabled = true,
      this.lastScanned,
      this.scanInterval,
      this.isTrusted = false})
      : super._();

  @override
  final String id;
  @override
  final String url;
  @override
  final String name;
  @override
  @JsonKey()
  final bool isEnabled;
  @override
  final DateTime? lastScanned;
  @override
  final Duration? scanInterval;
  @override
  @JsonKey()
  final bool isTrusted;

  @override
  String toString() {
    return 'RelayConfiguration(id: $id, url: $url, name: $name, isEnabled: $isEnabled, lastScanned: $lastScanned, scanInterval: $scanInterval, isTrusted: $isTrusted)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RelayConfigurationImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.isEnabled, isEnabled) || other.isEnabled == isEnabled) &&
            (identical(other.lastScanned, lastScanned) || other.lastScanned == lastScanned) &&
            (identical(other.scanInterval, scanInterval) || other.scanInterval == scanInterval) &&
            (identical(other.isTrusted, isTrusted) || other.isTrusted == isTrusted));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, id, url, name, isEnabled, lastScanned, scanInterval, isTrusted);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RelayConfigurationImplCopyWith<_$RelayConfigurationImpl> get copyWith =>
      __$$RelayConfigurationImplCopyWithImpl<_$RelayConfigurationImpl>(this, _$identity);
}

abstract class _RelayConfiguration extends RelayConfiguration {
  const factory _RelayConfiguration(
      {required final String id,
      required final String url,
      required final String name,
      final bool isEnabled,
      final DateTime? lastScanned,
      final Duration? scanInterval,
      final bool isTrusted}) = _$RelayConfigurationImpl;
  const _RelayConfiguration._() : super._();

  @override
  String get id;
  @override
  String get url;
  @override
  String get name;
  @override
  bool get isEnabled;
  @override
  DateTime? get lastScanned;
  @override
  Duration? get scanInterval;
  @override
  bool get isTrusted;
  @override
  @JsonKey(ignore: true)
  _$$RelayConfigurationImplCopyWith<_$RelayConfigurationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
