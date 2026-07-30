// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'share.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$Share {
  /// Shamir share bytes (encoding depends on generator); Nostr key `shard`.
  ///
  /// In `gf256_v1`, [payload] is a share of the **content-encryption key**,
  /// not the vault content itself. The encrypted content lives in [blob].
  String get payload => throw _privateConstructorUsedError;
  int get threshold => throw _privateConstructorUsedError;
  int get shareIndex => throw _privateConstructorUsedError;
  int get totalShares => throw _privateConstructorUsedError;
  String get creatorPubkey => throw _privateConstructorUsedError;
  int get createdAt =>
      throw _privateConstructorUsedError; // Shamir scheme identifier. 'gf256_v1' for GF(256) shares (current).
// Null means unsupported (legacy ntcdcrypto GF(p) format).
  String? get scheme => throw _privateConstructorUsedError;

  /// Base64url-encoded ChaCha20-Poly1305 bundle of the vault content:
  /// `nonce(12) || ciphertext(n) || poly1305 tag(16)`. Required for
  /// `gf256_v1` shares.
  ///
  /// Every share in a distribution carries an identical [blob]; recovery
  /// cross-checks for byte equality before reconstructing the key. The
  /// Poly1305 tag is what gives reconstructed content its integrity
  /// guarantee — SSS alone provides none.
  String? get blob => throw _privateConstructorUsedError; // Recovery metadata (optional fields)
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
  int? get distributionVersion =>
      throw _privateConstructorUsedError; // Version tracking for redistribution detection (nullable for backward compatibility)
// Whether the vault owner has push notifications enabled for this vault.
//
// Nullable for backward compatibility: pre-push shares arrive without this
// field, in which case receivers should preserve whatever push setting
// their local Vault already has (don't silently flip anything). When the
// owner re-distributes after changing the flag, the new value overrides.
// The owner is the only party whose opinion matters here because they are
// the one whose pubkey/IP/contact-graph leaks to the notifier.
  bool? get pushEnabled => throw _privateConstructorUsedError;

  /// Create a copy of Share
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ShareCopyWith<Share> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ShareCopyWith<$Res> {
  factory $ShareCopyWith(Share value, $Res Function(Share) then) = _$ShareCopyWithImpl<$Res, Share>;
  @useResult
  $Res call(
      {String payload,
      int threshold,
      int shareIndex,
      int totalShares,
      String creatorPubkey,
      int createdAt,
      String? scheme,
      String? blob,
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
      int? distributionVersion,
      bool? pushEnabled});
}

/// @nodoc
class _$ShareCopyWithImpl<$Res, $Val extends Share> implements $ShareCopyWith<$Res> {
  _$ShareCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Share
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? payload = null,
    Object? threshold = null,
    Object? shareIndex = null,
    Object? totalShares = null,
    Object? creatorPubkey = null,
    Object? createdAt = null,
    Object? scheme = freezed,
    Object? blob = freezed,
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
    Object? pushEnabled = freezed,
  }) {
    return _then(_value.copyWith(
      payload: null == payload
          ? _value.payload
          : payload // ignore: cast_nullable_to_non_nullable
              as String,
      threshold: null == threshold
          ? _value.threshold
          : threshold // ignore: cast_nullable_to_non_nullable
              as int,
      shareIndex: null == shareIndex
          ? _value.shareIndex
          : shareIndex // ignore: cast_nullable_to_non_nullable
              as int,
      totalShares: null == totalShares
          ? _value.totalShares
          : totalShares // ignore: cast_nullable_to_non_nullable
              as int,
      creatorPubkey: null == creatorPubkey
          ? _value.creatorPubkey
          : creatorPubkey // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as int,
      scheme: freezed == scheme
          ? _value.scheme
          : scheme // ignore: cast_nullable_to_non_nullable
              as String?,
      blob: freezed == blob
          ? _value.blob
          : blob // ignore: cast_nullable_to_non_nullable
              as String?,
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
      pushEnabled: freezed == pushEnabled
          ? _value.pushEnabled
          : pushEnabled // ignore: cast_nullable_to_non_nullable
              as bool?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ShareImplCopyWith<$Res> implements $ShareCopyWith<$Res> {
  factory _$$ShareImplCopyWith(_$ShareImpl value, $Res Function(_$ShareImpl) then) =
      __$$ShareImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String payload,
      int threshold,
      int shareIndex,
      int totalShares,
      String creatorPubkey,
      int createdAt,
      String? scheme,
      String? blob,
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
      int? distributionVersion,
      bool? pushEnabled});
}

/// @nodoc
class __$$ShareImplCopyWithImpl<$Res> extends _$ShareCopyWithImpl<$Res, _$ShareImpl>
    implements _$$ShareImplCopyWith<$Res> {
  __$$ShareImplCopyWithImpl(_$ShareImpl _value, $Res Function(_$ShareImpl) _then)
      : super(_value, _then);

  /// Create a copy of Share
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? payload = null,
    Object? threshold = null,
    Object? shareIndex = null,
    Object? totalShares = null,
    Object? creatorPubkey = null,
    Object? createdAt = null,
    Object? scheme = freezed,
    Object? blob = freezed,
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
    Object? pushEnabled = freezed,
  }) {
    return _then(_$ShareImpl(
      payload: null == payload
          ? _value.payload
          : payload // ignore: cast_nullable_to_non_nullable
              as String,
      threshold: null == threshold
          ? _value.threshold
          : threshold // ignore: cast_nullable_to_non_nullable
              as int,
      shareIndex: null == shareIndex
          ? _value.shareIndex
          : shareIndex // ignore: cast_nullable_to_non_nullable
              as int,
      totalShares: null == totalShares
          ? _value.totalShares
          : totalShares // ignore: cast_nullable_to_non_nullable
              as int,
      creatorPubkey: null == creatorPubkey
          ? _value.creatorPubkey
          : creatorPubkey // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as int,
      scheme: freezed == scheme
          ? _value.scheme
          : scheme // ignore: cast_nullable_to_non_nullable
              as String?,
      blob: freezed == blob
          ? _value.blob
          : blob // ignore: cast_nullable_to_non_nullable
              as String?,
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
      pushEnabled: freezed == pushEnabled
          ? _value.pushEnabled
          : pushEnabled // ignore: cast_nullable_to_non_nullable
              as bool?,
    ));
  }
}

/// @nodoc

class _$ShareImpl extends _Share {
  const _$ShareImpl(
      {required this.payload,
      required this.threshold,
      required this.shareIndex,
      required this.totalShares,
      required this.creatorPubkey,
      required this.createdAt,
      this.scheme,
      this.blob,
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
      this.distributionVersion,
      this.pushEnabled})
      : _stewards = stewards,
        _relayUrls = relayUrls,
        super._();

  /// Shamir share bytes (encoding depends on generator); Nostr key `shard`.
  ///
  /// In `gf256_v1`, [payload] is a share of the **content-encryption key**,
  /// not the vault content itself. The encrypted content lives in [blob].
  @override
  final String payload;
  @override
  final int threshold;
  @override
  final int shareIndex;
  @override
  final int totalShares;
  @override
  final String creatorPubkey;
  @override
  final int createdAt;
// Shamir scheme identifier. 'gf256_v1' for GF(256) shares (current).
// Null means unsupported (legacy ntcdcrypto GF(p) format).
  @override
  final String? scheme;

  /// Base64url-encoded ChaCha20-Poly1305 bundle of the vault content:
  /// `nonce(12) || ciphertext(n) || poly1305 tag(16)`. Required for
  /// `gf256_v1` shares.
  ///
  /// Every share in a distribution carries an identical [blob]; recovery
  /// cross-checks for byte equality before reconstructing the key. The
  /// Poly1305 tag is what gives reconstructed content its integrity
  /// guarantee — SSS alone provides none.
  @override
  final String? blob;
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
// Version tracking for redistribution detection (nullable for backward compatibility)
// Whether the vault owner has push notifications enabled for this vault.
//
// Nullable for backward compatibility: pre-push shares arrive without this
// field, in which case receivers should preserve whatever push setting
// their local Vault already has (don't silently flip anything). When the
// owner re-distributes after changing the flag, the new value overrides.
// The owner is the only party whose opinion matters here because they are
// the one whose pubkey/IP/contact-graph leaks to the notifier.
  @override
  final bool? pushEnabled;

  @override
  String toString() {
    return 'Share(payload: $payload, threshold: $threshold, shareIndex: $shareIndex, totalShares: $totalShares, creatorPubkey: $creatorPubkey, createdAt: $createdAt, scheme: $scheme, blob: $blob, vaultId: $vaultId, vaultName: $vaultName, stewards: $stewards, ownerName: $ownerName, instructions: $instructions, recipientPubkey: $recipientPubkey, isReceived: $isReceived, receivedAt: $receivedAt, nostrEventId: $nostrEventId, relayUrls: $relayUrls, distributionVersion: $distributionVersion, pushEnabled: $pushEnabled)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ShareImpl &&
            (identical(other.payload, payload) || other.payload == payload) &&
            (identical(other.threshold, threshold) || other.threshold == threshold) &&
            (identical(other.shareIndex, shareIndex) || other.shareIndex == shareIndex) &&
            (identical(other.totalShares, totalShares) || other.totalShares == totalShares) &&
            (identical(other.creatorPubkey, creatorPubkey) ||
                other.creatorPubkey == creatorPubkey) &&
            (identical(other.createdAt, createdAt) || other.createdAt == createdAt) &&
            (identical(other.scheme, scheme) || other.scheme == scheme) &&
            (identical(other.blob, blob) || other.blob == blob) &&
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
                other.distributionVersion == distributionVersion) &&
            (identical(other.pushEnabled, pushEnabled) || other.pushEnabled == pushEnabled));
  }

  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        payload,
        threshold,
        shareIndex,
        totalShares,
        creatorPubkey,
        createdAt,
        scheme,
        blob,
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
        distributionVersion,
        pushEnabled
      ]);

  /// Create a copy of Share
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ShareImplCopyWith<_$ShareImpl> get copyWith =>
      __$$ShareImplCopyWithImpl<_$ShareImpl>(this, _$identity);
}

abstract class _Share extends Share {
  const factory _Share(
      {required final String payload,
      required final int threshold,
      required final int shareIndex,
      required final int totalShares,
      required final String creatorPubkey,
      required final int createdAt,
      final String? scheme,
      final String? blob,
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
      final int? distributionVersion,
      final bool? pushEnabled}) = _$ShareImpl;
  const _Share._() : super._();

  /// Shamir share bytes (encoding depends on generator); Nostr key `shard`.
  ///
  /// In `gf256_v1`, [payload] is a share of the **content-encryption key**,
  /// not the vault content itself. The encrypted content lives in [blob].
  @override
  String get payload;
  @override
  int get threshold;
  @override
  int get shareIndex;
  @override
  int get totalShares;
  @override
  String get creatorPubkey;
  @override
  int get createdAt; // Shamir scheme identifier. 'gf256_v1' for GF(256) shares (current).
// Null means unsupported (legacy ntcdcrypto GF(p) format).
  @override
  String? get scheme;

  /// Base64url-encoded ChaCha20-Poly1305 bundle of the vault content:
  /// `nonce(12) || ciphertext(n) || poly1305 tag(16)`. Required for
  /// `gf256_v1` shares.
  ///
  /// Every share in a distribution carries an identical [blob]; recovery
  /// cross-checks for byte equality before reconstructing the key. The
  /// Poly1305 tag is what gives reconstructed content its integrity
  /// guarantee — SSS alone provides none.
  @override
  String? get blob; // Recovery metadata (optional fields)
  @override
  String? get vaultId;
  @override
  String? get vaultName;
  @override
  List<Map<String, String>>?
      get stewards; // List of maps with 'name', 'pubkey', and optionally 'contactInfo' for OTHER stewards (excludes creatorPubkey)
  @override
  String? get ownerName; // Name of the vault owner (creator)
  @override
  String? get instructions; // Instructions for stewards
  @override
  String? get recipientPubkey;
  @override
  bool? get isReceived;
  @override
  DateTime? get receivedAt;
  @override
  String? get nostrEventId;
  @override
  List<String>? get relayUrls; // Relay URLs from backup config for sending confirmations
  @override
  int?
      get distributionVersion; // Version tracking for redistribution detection (nullable for backward compatibility)
// Whether the vault owner has push notifications enabled for this vault.
//
// Nullable for backward compatibility: pre-push shares arrive without this
// field, in which case receivers should preserve whatever push setting
// their local Vault already has (don't silently flip anything). When the
// owner re-distributes after changing the flag, the new value overrides.
// The owner is the only party whose opinion matters here because they are
// the one whose pubkey/IP/contact-graph leaks to the notifier.
  @override
  bool? get pushEnabled;

  /// Create a copy of Share
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ShareImplCopyWith<_$ShareImpl> get copyWith => throw _privateConstructorUsedError;
}
