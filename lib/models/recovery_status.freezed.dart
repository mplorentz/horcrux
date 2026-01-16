// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recovery_status.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$RecoveryStatus {
  String get recoveryRequestId => throw _privateConstructorUsedError;
  int get totalStewards => throw _privateConstructorUsedError;
  int get respondedCount => throw _privateConstructorUsedError;
  int get approvedCount => throw _privateConstructorUsedError;
  int get deniedCount => throw _privateConstructorUsedError;
  List<String> get collectedShardIds =>
      throw _privateConstructorUsedError; // List of shard data IDs
  int get threshold => throw _privateConstructorUsedError;
  bool get canRecover => throw _privateConstructorUsedError;
  DateTime get lastUpdated => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $RecoveryStatusCopyWith<RecoveryStatus> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RecoveryStatusCopyWith<$Res> {
  factory $RecoveryStatusCopyWith(RecoveryStatus value, $Res Function(RecoveryStatus) then) =
      _$RecoveryStatusCopyWithImpl<$Res, RecoveryStatus>;
  @useResult
  $Res call(
      {String recoveryRequestId,
      int totalStewards,
      int respondedCount,
      int approvedCount,
      int deniedCount,
      List<String> collectedShardIds,
      int threshold,
      bool canRecover,
      DateTime lastUpdated});
}

/// @nodoc
class _$RecoveryStatusCopyWithImpl<$Res, $Val extends RecoveryStatus>
    implements $RecoveryStatusCopyWith<$Res> {
  _$RecoveryStatusCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? recoveryRequestId = null,
    Object? totalStewards = null,
    Object? respondedCount = null,
    Object? approvedCount = null,
    Object? deniedCount = null,
    Object? collectedShardIds = null,
    Object? threshold = null,
    Object? canRecover = null,
    Object? lastUpdated = null,
  }) {
    return _then(_value.copyWith(
      recoveryRequestId: null == recoveryRequestId
          ? _value.recoveryRequestId
          : recoveryRequestId // ignore: cast_nullable_to_non_nullable
              as String,
      totalStewards: null == totalStewards
          ? _value.totalStewards
          : totalStewards // ignore: cast_nullable_to_non_nullable
              as int,
      respondedCount: null == respondedCount
          ? _value.respondedCount
          : respondedCount // ignore: cast_nullable_to_non_nullable
              as int,
      approvedCount: null == approvedCount
          ? _value.approvedCount
          : approvedCount // ignore: cast_nullable_to_non_nullable
              as int,
      deniedCount: null == deniedCount
          ? _value.deniedCount
          : deniedCount // ignore: cast_nullable_to_non_nullable
              as int,
      collectedShardIds: null == collectedShardIds
          ? _value.collectedShardIds
          : collectedShardIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      threshold: null == threshold
          ? _value.threshold
          : threshold // ignore: cast_nullable_to_non_nullable
              as int,
      canRecover: null == canRecover
          ? _value.canRecover
          : canRecover // ignore: cast_nullable_to_non_nullable
              as bool,
      lastUpdated: null == lastUpdated
          ? _value.lastUpdated
          : lastUpdated // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RecoveryStatusImplCopyWith<$Res> implements $RecoveryStatusCopyWith<$Res> {
  factory _$$RecoveryStatusImplCopyWith(
          _$RecoveryStatusImpl value, $Res Function(_$RecoveryStatusImpl) then) =
      __$$RecoveryStatusImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String recoveryRequestId,
      int totalStewards,
      int respondedCount,
      int approvedCount,
      int deniedCount,
      List<String> collectedShardIds,
      int threshold,
      bool canRecover,
      DateTime lastUpdated});
}

/// @nodoc
class __$$RecoveryStatusImplCopyWithImpl<$Res>
    extends _$RecoveryStatusCopyWithImpl<$Res, _$RecoveryStatusImpl>
    implements _$$RecoveryStatusImplCopyWith<$Res> {
  __$$RecoveryStatusImplCopyWithImpl(
      _$RecoveryStatusImpl _value, $Res Function(_$RecoveryStatusImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? recoveryRequestId = null,
    Object? totalStewards = null,
    Object? respondedCount = null,
    Object? approvedCount = null,
    Object? deniedCount = null,
    Object? collectedShardIds = null,
    Object? threshold = null,
    Object? canRecover = null,
    Object? lastUpdated = null,
  }) {
    return _then(_$RecoveryStatusImpl(
      recoveryRequestId: null == recoveryRequestId
          ? _value.recoveryRequestId
          : recoveryRequestId // ignore: cast_nullable_to_non_nullable
              as String,
      totalStewards: null == totalStewards
          ? _value.totalStewards
          : totalStewards // ignore: cast_nullable_to_non_nullable
              as int,
      respondedCount: null == respondedCount
          ? _value.respondedCount
          : respondedCount // ignore: cast_nullable_to_non_nullable
              as int,
      approvedCount: null == approvedCount
          ? _value.approvedCount
          : approvedCount // ignore: cast_nullable_to_non_nullable
              as int,
      deniedCount: null == deniedCount
          ? _value.deniedCount
          : deniedCount // ignore: cast_nullable_to_non_nullable
              as int,
      collectedShardIds: null == collectedShardIds
          ? _value._collectedShardIds
          : collectedShardIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      threshold: null == threshold
          ? _value.threshold
          : threshold // ignore: cast_nullable_to_non_nullable
              as int,
      canRecover: null == canRecover
          ? _value.canRecover
          : canRecover // ignore: cast_nullable_to_non_nullable
              as bool,
      lastUpdated: null == lastUpdated
          ? _value.lastUpdated
          : lastUpdated // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc

class _$RecoveryStatusImpl extends _RecoveryStatus {
  const _$RecoveryStatusImpl(
      {required this.recoveryRequestId,
      required this.totalStewards,
      required this.respondedCount,
      required this.approvedCount,
      required this.deniedCount,
      final List<String> collectedShardIds = const [],
      required this.threshold,
      required this.canRecover,
      required this.lastUpdated})
      : _collectedShardIds = collectedShardIds,
        super._();

  @override
  final String recoveryRequestId;
  @override
  final int totalStewards;
  @override
  final int respondedCount;
  @override
  final int approvedCount;
  @override
  final int deniedCount;
  final List<String> _collectedShardIds;
  @override
  @JsonKey()
  List<String> get collectedShardIds {
    if (_collectedShardIds is EqualUnmodifiableListView) return _collectedShardIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_collectedShardIds);
  }

// List of shard data IDs
  @override
  final int threshold;
  @override
  final bool canRecover;
  @override
  final DateTime lastUpdated;

  @override
  String toString() {
    return 'RecoveryStatus(recoveryRequestId: $recoveryRequestId, totalStewards: $totalStewards, respondedCount: $respondedCount, approvedCount: $approvedCount, deniedCount: $deniedCount, collectedShardIds: $collectedShardIds, threshold: $threshold, canRecover: $canRecover, lastUpdated: $lastUpdated)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RecoveryStatusImpl &&
            (identical(other.recoveryRequestId, recoveryRequestId) ||
                other.recoveryRequestId == recoveryRequestId) &&
            (identical(other.totalStewards, totalStewards) ||
                other.totalStewards == totalStewards) &&
            (identical(other.respondedCount, respondedCount) ||
                other.respondedCount == respondedCount) &&
            (identical(other.approvedCount, approvedCount) ||
                other.approvedCount == approvedCount) &&
            (identical(other.deniedCount, deniedCount) || other.deniedCount == deniedCount) &&
            const DeepCollectionEquality().equals(other._collectedShardIds, _collectedShardIds) &&
            (identical(other.threshold, threshold) || other.threshold == threshold) &&
            (identical(other.canRecover, canRecover) || other.canRecover == canRecover) &&
            (identical(other.lastUpdated, lastUpdated) || other.lastUpdated == lastUpdated));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      recoveryRequestId,
      totalStewards,
      respondedCount,
      approvedCount,
      deniedCount,
      const DeepCollectionEquality().hash(_collectedShardIds),
      threshold,
      canRecover,
      lastUpdated);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RecoveryStatusImplCopyWith<_$RecoveryStatusImpl> get copyWith =>
      __$$RecoveryStatusImplCopyWithImpl<_$RecoveryStatusImpl>(this, _$identity);
}

abstract class _RecoveryStatus extends RecoveryStatus {
  const factory _RecoveryStatus(
      {required final String recoveryRequestId,
      required final int totalStewards,
      required final int respondedCount,
      required final int approvedCount,
      required final int deniedCount,
      final List<String> collectedShardIds,
      required final int threshold,
      required final bool canRecover,
      required final DateTime lastUpdated}) = _$RecoveryStatusImpl;
  const _RecoveryStatus._() : super._();

  @override
  String get recoveryRequestId;
  @override
  int get totalStewards;
  @override
  int get respondedCount;
  @override
  int get approvedCount;
  @override
  int get deniedCount;
  @override
  List<String> get collectedShardIds;
  @override // List of shard data IDs
  int get threshold;
  @override
  bool get canRecover;
  @override
  DateTime get lastUpdated;
  @override
  @JsonKey(ignore: true)
  _$$RecoveryStatusImplCopyWith<_$RecoveryStatusImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
