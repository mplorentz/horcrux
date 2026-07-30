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
  String get pubkey =>
      throw _privateConstructorUsedError; // hex format, 64 characters
  bool get approved =>
      throw _privateConstructorUsedError; // Whether the steward approved the request
  DateTime? get respondedAt => throw _privateConstructorUsedError;

  /// Embedded share for reassembly when approved. JSON key stays `shardData`.
  Share? get share => throw _privateConstructorUsedError;
  String? get nostrEventId => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;

  /// Create a copy of RecoveryResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RecoveryResponseCopyWith<RecoveryResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RecoveryResponseCopyWith<$Res> {
  factory $RecoveryResponseCopyWith(
          RecoveryResponse value, $Res Function(RecoveryResponse) then) =
      _$RecoveryResponseCopyWithImpl<$Res, RecoveryResponse>;
  @useResult
  $Res call(
      {String pubkey,
      bool approved,
      DateTime? respondedAt,
      Share? share,
      String? nostrEventId,
      String? errorMessage});

  $ShareCopyWith<$Res>? get share;
}

/// @nodoc
class _$RecoveryResponseCopyWithImpl<$Res, $Val extends RecoveryResponse>
    implements $RecoveryResponseCopyWith<$Res> {
  _$RecoveryResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RecoveryResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? pubkey = null,
    Object? approved = null,
    Object? respondedAt = freezed,
    Object? share = freezed,
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
      share: freezed == share
          ? _value.share
          : share // ignore: cast_nullable_to_non_nullable
              as Share?,
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

  /// Create a copy of RecoveryResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ShareCopyWith<$Res>? get share {
    if (_value.share == null) {
      return null;
    }

    return $ShareCopyWith<$Res>(_value.share!, (value) {
      return _then(_value.copyWith(share: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$RecoveryResponseImplCopyWith<$Res>
    implements $RecoveryResponseCopyWith<$Res> {
  factory _$$RecoveryResponseImplCopyWith(_$RecoveryResponseImpl value,
          $Res Function(_$RecoveryResponseImpl) then) =
      __$$RecoveryResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String pubkey,
      bool approved,
      DateTime? respondedAt,
      Share? share,
      String? nostrEventId,
      String? errorMessage});

  @override
  $ShareCopyWith<$Res>? get share;
}

/// @nodoc
class __$$RecoveryResponseImplCopyWithImpl<$Res>
    extends _$RecoveryResponseCopyWithImpl<$Res, _$RecoveryResponseImpl>
    implements _$$RecoveryResponseImplCopyWith<$Res> {
  __$$RecoveryResponseImplCopyWithImpl(_$RecoveryResponseImpl _value,
      $Res Function(_$RecoveryResponseImpl) _then)
      : super(_value, _then);

  /// Create a copy of RecoveryResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? pubkey = null,
    Object? approved = null,
    Object? respondedAt = freezed,
    Object? share = freezed,
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
      share: freezed == share
          ? _value.share
          : share // ignore: cast_nullable_to_non_nullable
              as Share?,
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
      this.share,
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

  /// Embedded share for reassembly when approved. JSON key stays `shardData`.
  @override
  final Share? share;
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
            (identical(other.approved, approved) ||
                other.approved == approved) &&
            (identical(other.respondedAt, respondedAt) ||
                other.respondedAt == respondedAt) &&
            (identical(other.share, share) || other.share == share) &&
            (identical(other.nostrEventId, nostrEventId) ||
                other.nostrEventId == nostrEventId) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage));
  }

  @override
  int get hashCode => Object.hash(runtimeType, pubkey, approved, respondedAt,
      share, nostrEventId, errorMessage);

  /// Create a copy of RecoveryResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RecoveryResponseImplCopyWith<_$RecoveryResponseImpl> get copyWith =>
      __$$RecoveryResponseImplCopyWithImpl<_$RecoveryResponseImpl>(
          this, _$identity);
}

abstract class _RecoveryResponse extends RecoveryResponse {
  const factory _RecoveryResponse(
      {required final String pubkey,
      required final bool approved,
      final DateTime? respondedAt,
      final Share? share,
      final String? nostrEventId,
      final String? errorMessage}) = _$RecoveryResponseImpl;
  const _RecoveryResponse._() : super._();

  @override
  String get pubkey; // hex format, 64 characters
  @override
  bool get approved; // Whether the steward approved the request
  @override
  DateTime? get respondedAt;

  /// Embedded share for reassembly when approved. JSON key stays `shardData`.
  @override
  Share? get share;
  @override
  String? get nostrEventId;
  @override
  String? get errorMessage;

  /// Create a copy of RecoveryResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RecoveryResponseImplCopyWith<_$RecoveryResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$RecoveryRequest {
  String get id => throw _privateConstructorUsedError;
  String get vaultId => throw _privateConstructorUsedError;
  String get initiatorPubkey =>
      throw _privateConstructorUsedError; // hex format, 64 characters
  DateTime get requestedAt => throw _privateConstructorUsedError;
  RecoveryRequestStatus get status => throw _privateConstructorUsedError;
  int get threshold =>
      throw _privateConstructorUsedError; // Shamir threshold needed for recovery
  String? get nostrEventId => throw _privateConstructorUsedError;

  /// Unix `created_at` of the inner Nostr event (for live vs historical notification policy).
  DateTime? get eventCreationTime => throw _privateConstructorUsedError;
  DateTime? get expiresAt => throw _privateConstructorUsedError;
  List<String> get stewardPubkeys => throw _privateConstructorUsedError;
  List<RecoveryResponse> get responses => throw _privateConstructorUsedError;
  String? get errorMessage =>
      throw _privateConstructorUsedError; // Error message if status is failed
  bool get isPractice => throw _privateConstructorUsedError;

  /// Create a copy of RecoveryRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RecoveryRequestCopyWith<RecoveryRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RecoveryRequestCopyWith<$Res> {
  factory $RecoveryRequestCopyWith(
          RecoveryRequest value, $Res Function(RecoveryRequest) then) =
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
      DateTime? eventCreationTime,
      DateTime? expiresAt,
      List<String> stewardPubkeys,
      List<RecoveryResponse> responses,
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

  /// Create a copy of RecoveryRequest
  /// with the given fields replaced by the non-null parameter values.
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
    Object? eventCreationTime = freezed,
    Object? expiresAt = freezed,
    Object? stewardPubkeys = null,
    Object? responses = null,
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
      eventCreationTime: freezed == eventCreationTime
          ? _value.eventCreationTime
          : eventCreationTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      expiresAt: freezed == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      stewardPubkeys: null == stewardPubkeys
          ? _value.stewardPubkeys
          : stewardPubkeys // ignore: cast_nullable_to_non_nullable
              as List<String>,
      responses: null == responses
          ? _value.responses
          : responses // ignore: cast_nullable_to_non_nullable
              as List<RecoveryResponse>,
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
abstract class _$$RecoveryRequestImplCopyWith<$Res>
    implements $RecoveryRequestCopyWith<$Res> {
  factory _$$RecoveryRequestImplCopyWith(_$RecoveryRequestImpl value,
          $Res Function(_$RecoveryRequestImpl) then) =
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
      DateTime? eventCreationTime,
      DateTime? expiresAt,
      List<String> stewardPubkeys,
      List<RecoveryResponse> responses,
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

  /// Create a copy of RecoveryRequest
  /// with the given fields replaced by the non-null parameter values.
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
    Object? eventCreationTime = freezed,
    Object? expiresAt = freezed,
    Object? stewardPubkeys = null,
    Object? responses = null,
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
      eventCreationTime: freezed == eventCreationTime
          ? _value.eventCreationTime
          : eventCreationTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      expiresAt: freezed == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      stewardPubkeys: null == stewardPubkeys
          ? _value._stewardPubkeys
          : stewardPubkeys // ignore: cast_nullable_to_non_nullable
              as List<String>,
      responses: null == responses
          ? _value._responses
          : responses // ignore: cast_nullable_to_non_nullable
              as List<RecoveryResponse>,
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
      this.eventCreationTime,
      this.expiresAt,
      final List<String> stewardPubkeys = const [],
      final List<RecoveryResponse> responses = const [],
      this.errorMessage,
      this.isPractice = false})
      : _stewardPubkeys = stewardPubkeys,
        _responses = responses,
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

  /// Unix `created_at` of the inner Nostr event (for live vs historical notification policy).
  @override
  final DateTime? eventCreationTime;
  @override
  final DateTime? expiresAt;
  final List<String> _stewardPubkeys;
  @override
  @JsonKey()
  List<String> get stewardPubkeys {
    if (_stewardPubkeys is EqualUnmodifiableListView) return _stewardPubkeys;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_stewardPubkeys);
  }

  final List<RecoveryResponse> _responses;
  @override
  @JsonKey()
  List<RecoveryResponse> get responses {
    if (_responses is EqualUnmodifiableListView) return _responses;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_responses);
  }

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
            (identical(other.requestedAt, requestedAt) ||
                other.requestedAt == requestedAt) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.threshold, threshold) ||
                other.threshold == threshold) &&
            (identical(other.nostrEventId, nostrEventId) ||
                other.nostrEventId == nostrEventId) &&
            (identical(other.eventCreationTime, eventCreationTime) ||
                other.eventCreationTime == eventCreationTime) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt) &&
            const DeepCollectionEquality()
                .equals(other._stewardPubkeys, _stewardPubkeys) &&
            const DeepCollectionEquality()
                .equals(other._responses, _responses) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            (identical(other.isPractice, isPractice) ||
                other.isPractice == isPractice));
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
      eventCreationTime,
      expiresAt,
      const DeepCollectionEquality().hash(_stewardPubkeys),
      const DeepCollectionEquality().hash(_responses),
      errorMessage,
      isPractice);

  /// Create a copy of RecoveryRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RecoveryRequestImplCopyWith<_$RecoveryRequestImpl> get copyWith =>
      __$$RecoveryRequestImplCopyWithImpl<_$RecoveryRequestImpl>(
          this, _$identity);
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
      final DateTime? eventCreationTime,
      final DateTime? expiresAt,
      final List<String> stewardPubkeys,
      final List<RecoveryResponse> responses,
      final String? errorMessage,
      final bool isPractice}) = _$RecoveryRequestImpl;
  const _RecoveryRequest._() : super._();

  @override
  String get id;
  @override
  String get vaultId;
  @override
  String get initiatorPubkey; // hex format, 64 characters
  @override
  DateTime get requestedAt;
  @override
  RecoveryRequestStatus get status;
  @override
  int get threshold; // Shamir threshold needed for recovery
  @override
  String? get nostrEventId;

  /// Unix `created_at` of the inner Nostr event (for live vs historical notification policy).
  @override
  DateTime? get eventCreationTime;
  @override
  DateTime? get expiresAt;
  @override
  List<String> get stewardPubkeys;
  @override
  List<RecoveryResponse> get responses;
  @override
  String? get errorMessage; // Error message if status is failed
  @override
  bool get isPractice;

  /// Create a copy of RecoveryRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RecoveryRequestImplCopyWith<_$RecoveryRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
