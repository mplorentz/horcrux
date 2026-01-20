// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recovery_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$RecoveryResponse {
  String get pubkey => throw _privateConstructorUsedError; // hex format, 64 characters
  bool get approved =>
      throw _privateConstructorUsedError; // Whether the steward approved the request
  DateTime? get respondedAt => throw _privateConstructorUsedError;
  ShardData? get shardData =>
      throw _privateConstructorUsedError; // Actual shard data for reassembly (if approved)
  String? get nostrEventId => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $RecoveryResponseCopyWith<RecoveryResponse> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RecoveryResponseCopyWith<$Res> {
  factory $RecoveryResponseCopyWith(RecoveryResponse value, $Res Function(RecoveryResponse) then) =
      _$RecoveryResponseCopyWithImpl<$Res, RecoveryResponse>;
  @useResult
  $Res call(
      {String pubkey,
      bool approved,
      DateTime? respondedAt,
      ShardData? shardData,
      String? nostrEventId,
      String? errorMessage});

  $ShardDataCopyWith<$Res>? get shardData;
}

/// @nodoc
class _$RecoveryResponseCopyWithImpl<$Res, $Val extends RecoveryResponse>
    implements $RecoveryResponseCopyWith<$Res> {
  _$RecoveryResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? pubkey = null,
    Object? approved = null,
    Object? respondedAt = freezed,
    Object? shardData = freezed,
    Object? nostrEventId = freezed,
    Object? errorMessage = freezed,
  }) {
    return _then(_value.copyWith(
      pubkey: null == pubkey
          ? _value.pubkey
          : pubkey // ignore: cast_nullable_to_non_nullable
              as String,
      approved: null == approved
          ? _value.approved
          : approved // ignore: cast_nullable_to_non_nullable
              as bool,
      respondedAt: freezed == respondedAt
          ? _value.respondedAt
          : respondedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      shardData: freezed == shardData
          ? _value.shardData
          : shardData // ignore: cast_nullable_to_non_nullable
              as ShardData?,
      nostrEventId: freezed == nostrEventId
          ? _value.nostrEventId
          : nostrEventId // ignore: cast_nullable_to_non_nullable
              as String?,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $ShardDataCopyWith<$Res>? get shardData {
    if (_value.shardData == null) {
      return null;
    }

    return $ShardDataCopyWith<$Res>(_value.shardData!, (value) {
      return _then(_value.copyWith(shardData: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$RecoveryResponseImplCopyWith<$Res> implements $RecoveryResponseCopyWith<$Res> {
  factory _$$RecoveryResponseImplCopyWith(
          _$RecoveryResponseImpl value, $Res Function(_$RecoveryResponseImpl) then) =
      __$$RecoveryResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String pubkey,
      bool approved,
      DateTime? respondedAt,
      ShardData? shardData,
      String? nostrEventId,
      String? errorMessage});

  @override
  $ShardDataCopyWith<$Res>? get shardData;
}

/// @nodoc
class __$$RecoveryResponseImplCopyWithImpl<$Res>
    extends _$RecoveryResponseCopyWithImpl<$Res, _$RecoveryResponseImpl>
    implements _$$RecoveryResponseImplCopyWith<$Res> {
  __$$RecoveryResponseImplCopyWithImpl(
      _$RecoveryResponseImpl _value, $Res Function(_$RecoveryResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? pubkey = null,
    Object? approved = null,
    Object? respondedAt = freezed,
    Object? shardData = freezed,
    Object? nostrEventId = freezed,
    Object? errorMessage = freezed,
  }) {
    return _then(_$RecoveryResponseImpl(
      pubkey: null == pubkey
          ? _value.pubkey
          : pubkey // ignore: cast_nullable_to_non_nullable
              as String,
      approved: null == approved
          ? _value.approved
          : approved // ignore: cast_nullable_to_non_nullable
              as bool,
      respondedAt: freezed == respondedAt
          ? _value.respondedAt
          : respondedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      shardData: freezed == shardData
          ? _value.shardData
          : shardData // ignore: cast_nullable_to_non_nullable
              as ShardData?,
      nostrEventId: freezed == nostrEventId
          ? _value.nostrEventId
          : nostrEventId // ignore: cast_nullable_to_non_nullable
              as String?,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$RecoveryResponseImpl extends _RecoveryResponse {
  const _$RecoveryResponseImpl(
      {required this.pubkey,
      required this.approved,
      this.respondedAt,
      this.shardData,
      this.nostrEventId,
      this.errorMessage})
      : super._();

  @override
  final String pubkey;
// hex format, 64 characters
  @override
  final bool approved;
// Whether the steward approved the request
  @override
  final DateTime? respondedAt;
  @override
  final ShardData? shardData;
// Actual shard data for reassembly (if approved)
  @override
  final String? nostrEventId;
  @override
  final String? errorMessage;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RecoveryResponseImpl &&
            (identical(other.pubkey, pubkey) || other.pubkey == pubkey) &&
            (identical(other.approved, approved) || other.approved == approved) &&
            (identical(other.respondedAt, respondedAt) || other.respondedAt == respondedAt) &&
            (identical(other.shardData, shardData) || other.shardData == shardData) &&
            (identical(other.nostrEventId, nostrEventId) || other.nostrEventId == nostrEventId) &&
            (identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, pubkey, approved, respondedAt, shardData, nostrEventId, errorMessage);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RecoveryResponseImplCopyWith<_$RecoveryResponseImpl> get copyWith =>
      __$$RecoveryResponseImplCopyWithImpl<_$RecoveryResponseImpl>(this, _$identity);
}

abstract class _RecoveryResponse extends RecoveryResponse {
  const factory _RecoveryResponse(
      {required final String pubkey,
      required final bool approved,
      final DateTime? respondedAt,
      final ShardData? shardData,
      final String? nostrEventId,
      final String? errorMessage}) = _$RecoveryResponseImpl;
  const _RecoveryResponse._() : super._();

  @override
  String get pubkey;
  @override // hex format, 64 characters
  bool get approved;
  @override // Whether the steward approved the request
  DateTime? get respondedAt;
  @override
  ShardData? get shardData;
  @override // Actual shard data for reassembly (if approved)
  String? get nostrEventId;
  @override
  String? get errorMessage;
  @override
  @JsonKey(ignore: true)
  _$$RecoveryResponseImplCopyWith<_$RecoveryResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$RecoveryRequest {
  String get id => throw _privateConstructorUsedError;
  String get vaultId => throw _privateConstructorUsedError;
  String get initiatorPubkey => throw _privateConstructorUsedError; // hex format, 64 characters
  DateTime get requestedAt => throw _privateConstructorUsedError;
  RecoveryRequestStatus get status => throw _privateConstructorUsedError;
  int get threshold => throw _privateConstructorUsedError; // Shamir threshold needed for recovery
  String? get nostrEventId => throw _privateConstructorUsedError;
  DateTime? get expiresAt => throw _privateConstructorUsedError;
  Map<String, RecoveryResponse> get stewardResponses =>
      throw _privateConstructorUsedError; // pubkey -> response
  String? get errorMessage =>
      throw _privateConstructorUsedError; // Error message if status is failed
  bool get isPractice => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $RecoveryRequestCopyWith<RecoveryRequest> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RecoveryRequestCopyWith<$Res> {
  factory $RecoveryRequestCopyWith(RecoveryRequest value, $Res Function(RecoveryRequest) then) =
      _$RecoveryRequestCopyWithImpl<$Res, RecoveryRequest>;
  @useResult
  $Res call(
      {String id,
      String vaultId,
      String initiatorPubkey,
      DateTime requestedAt,
      RecoveryRequestStatus status,
      int threshold,
      String? nostrEventId,
      DateTime? expiresAt,
      Map<String, RecoveryResponse> stewardResponses,
      String? errorMessage,
      bool isPractice});
}

/// @nodoc
class _$RecoveryRequestCopyWithImpl<$Res, $Val extends RecoveryRequest>
    implements $RecoveryRequestCopyWith<$Res> {
  _$RecoveryRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? vaultId = null,
    Object? initiatorPubkey = null,
    Object? requestedAt = null,
    Object? status = null,
    Object? threshold = null,
    Object? nostrEventId = freezed,
    Object? expiresAt = freezed,
    Object? stewardResponses = null,
    Object? errorMessage = freezed,
    Object? isPractice = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      vaultId: null == vaultId
          ? _value.vaultId
          : vaultId // ignore: cast_nullable_to_non_nullable
              as String,
      initiatorPubkey: null == initiatorPubkey
          ? _value.initiatorPubkey
          : initiatorPubkey // ignore: cast_nullable_to_non_nullable
              as String,
      requestedAt: null == requestedAt
          ? _value.requestedAt
          : requestedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as RecoveryRequestStatus,
      threshold: null == threshold
          ? _value.threshold
          : threshold // ignore: cast_nullable_to_non_nullable
              as int,
      nostrEventId: freezed == nostrEventId
          ? _value.nostrEventId
          : nostrEventId // ignore: cast_nullable_to_non_nullable
              as String?,
      expiresAt: freezed == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      stewardResponses: null == stewardResponses
          ? _value.stewardResponses
          : stewardResponses // ignore: cast_nullable_to_non_nullable
              as Map<String, RecoveryResponse>,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      isPractice: null == isPractice
          ? _value.isPractice
          : isPractice // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RecoveryRequestImplCopyWith<$Res> implements $RecoveryRequestCopyWith<$Res> {
  factory _$$RecoveryRequestImplCopyWith(
          _$RecoveryRequestImpl value, $Res Function(_$RecoveryRequestImpl) then) =
      __$$RecoveryRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String vaultId,
      String initiatorPubkey,
      DateTime requestedAt,
      RecoveryRequestStatus status,
      int threshold,
      String? nostrEventId,
      DateTime? expiresAt,
      Map<String, RecoveryResponse> stewardResponses,
      String? errorMessage,
      bool isPractice});
}

/// @nodoc
class __$$RecoveryRequestImplCopyWithImpl<$Res>
    extends _$RecoveryRequestCopyWithImpl<$Res, _$RecoveryRequestImpl>
    implements _$$RecoveryRequestImplCopyWith<$Res> {
  __$$RecoveryRequestImplCopyWithImpl(
      _$RecoveryRequestImpl _value, $Res Function(_$RecoveryRequestImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? vaultId = null,
    Object? initiatorPubkey = null,
    Object? requestedAt = null,
    Object? status = null,
    Object? threshold = null,
    Object? nostrEventId = freezed,
    Object? expiresAt = freezed,
    Object? stewardResponses = null,
    Object? errorMessage = freezed,
    Object? isPractice = null,
  }) {
    return _then(_$RecoveryRequestImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      vaultId: null == vaultId
          ? _value.vaultId
          : vaultId // ignore: cast_nullable_to_non_nullable
              as String,
      initiatorPubkey: null == initiatorPubkey
          ? _value.initiatorPubkey
          : initiatorPubkey // ignore: cast_nullable_to_non_nullable
              as String,
      requestedAt: null == requestedAt
          ? _value.requestedAt
          : requestedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as RecoveryRequestStatus,
      threshold: null == threshold
          ? _value.threshold
          : threshold // ignore: cast_nullable_to_non_nullable
              as int,
      nostrEventId: freezed == nostrEventId
          ? _value.nostrEventId
          : nostrEventId // ignore: cast_nullable_to_non_nullable
              as String?,
      expiresAt: freezed == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      stewardResponses: null == stewardResponses
          ? _value._stewardResponses
          : stewardResponses // ignore: cast_nullable_to_non_nullable
              as Map<String, RecoveryResponse>,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      isPractice: null == isPractice
          ? _value.isPractice
          : isPractice // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$RecoveryRequestImpl extends _RecoveryRequest {
  const _$RecoveryRequestImpl(
      {required this.id,
      required this.vaultId,
      required this.initiatorPubkey,
      required this.requestedAt,
      required this.status,
      required this.threshold,
      this.nostrEventId,
      this.expiresAt,
      final Map<String, RecoveryResponse> stewardResponses = const {},
      this.errorMessage,
      this.isPractice = false})
      : _stewardResponses = stewardResponses,
        super._();

  @override
  final String id;
  @override
  final String vaultId;
  @override
  final String initiatorPubkey;
// hex format, 64 characters
  @override
  final DateTime requestedAt;
  @override
  final RecoveryRequestStatus status;
  @override
  final int threshold;
// Shamir threshold needed for recovery
  @override
  final String? nostrEventId;
  @override
  final DateTime? expiresAt;
  final Map<String, RecoveryResponse> _stewardResponses;
  @override
  @JsonKey()
  Map<String, RecoveryResponse> get stewardResponses {
    if (_stewardResponses is EqualUnmodifiableMapView) return _stewardResponses;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_stewardResponses);
  }

// pubkey -> response
  @override
  final String? errorMessage;
// Error message if status is failed
  @override
  @JsonKey()
  final bool isPractice;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RecoveryRequestImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.vaultId, vaultId) || other.vaultId == vaultId) &&
            (identical(other.initiatorPubkey, initiatorPubkey) ||
                other.initiatorPubkey == initiatorPubkey) &&
            (identical(other.requestedAt, requestedAt) || other.requestedAt == requestedAt) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.threshold, threshold) || other.threshold == threshold) &&
            (identical(other.nostrEventId, nostrEventId) || other.nostrEventId == nostrEventId) &&
            (identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt) &&
            const DeepCollectionEquality().equals(other._stewardResponses, _stewardResponses) &&
            (identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage) &&
            (identical(other.isPractice, isPractice) || other.isPractice == isPractice));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      vaultId,
      initiatorPubkey,
      requestedAt,
      status,
      threshold,
      nostrEventId,
      expiresAt,
      const DeepCollectionEquality().hash(_stewardResponses),
      errorMessage,
      isPractice);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RecoveryRequestImplCopyWith<_$RecoveryRequestImpl> get copyWith =>
      __$$RecoveryRequestImplCopyWithImpl<_$RecoveryRequestImpl>(this, _$identity);
}

abstract class _RecoveryRequest extends RecoveryRequest {
  const factory _RecoveryRequest(
      {required final String id,
      required final String vaultId,
      required final String initiatorPubkey,
      required final DateTime requestedAt,
      required final RecoveryRequestStatus status,
      required final int threshold,
      final String? nostrEventId,
      final DateTime? expiresAt,
      final Map<String, RecoveryResponse> stewardResponses,
      final String? errorMessage,
      final bool isPractice}) = _$RecoveryRequestImpl;
  const _RecoveryRequest._() : super._();

  @override
  String get id;
  @override
  String get vaultId;
  @override
  String get initiatorPubkey;
  @override // hex format, 64 characters
  DateTime get requestedAt;
  @override
  RecoveryRequestStatus get status;
  @override
  int get threshold;
  @override // Shamir threshold needed for recovery
  String? get nostrEventId;
  @override
  DateTime? get expiresAt;
  @override
  Map<String, RecoveryResponse> get stewardResponses;
  @override // pubkey -> response
  String? get errorMessage;
  @override // Error message if status is failed
  bool get isPractice;
  @override
  @JsonKey(ignore: true)
  _$$RecoveryRequestImplCopyWith<_$RecoveryRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
