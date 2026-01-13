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
  String? get content =>
      throw _privateConstructorUsedError; // Nullable - null when content is not decrypted
  DateTime get createdAt => throw _privateConstructorUsedError;
  String get ownerPubkey => throw _privateConstructorUsedError; // Hex format, 64 characters
  String? get ownerName => throw _privateConstructorUsedError; // Name of the vault owner
  List<
          ({
            int createdAt,
            String creatorPubkey,
            int? distributionVersion,
            String? instructions,
            bool? isReceived,
            String? nostrEventId,
            String? ownerName,
            List<Map<String, String>>? peers,
            String primeMod,
            DateTime? receivedAt,
            String? recipientPubkey,
            List<String>? relayUrls,
            String shard,
            int shardIndex,
            int threshold,
            int totalShards,
            String? vaultId,
            String? vaultName
          })>
      get shards =>
          throw _privateConstructorUsedError; // List of shards (single as steward, multiple during recovery)
  List<RecoveryRequest> get recoveryRequests =>
      throw _privateConstructorUsedError; // Embedded recovery requests
  ({
    String? contentHash,
    DateTime createdAt,
    int distributionVersion,
    String? instructions,
    DateTime? lastContentChange,
    DateTime? lastRedistribution,
    DateTime lastUpdated,
    List<String> relays,
    String specVersion,
    BackupStatus status,
    List<
        ({
          DateTime? acknowledgedAt,
          int? acknowledgedDistributionVersion,
          String? acknowledgmentEventId,
          String? giftWrapEventId,
          String id,
          String? inviteCode,
          bool isOwner,
          String? keyShare,
          DateTime? lastSeen,
          String? name,
          String? pubkey,
          StewardStatus status
        })> stewards,
    int threshold,
    int totalKeys,
    String vaultId
  })? get backupConfig => throw _privateConstructorUsedError; // Optional backup configuration
  bool get isArchived => throw _privateConstructorUsedError; // Whether this vault is archived
  DateTime? get archivedAt => throw _privateConstructorUsedError; // When the vault was archived
  String? get archivedReason => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $VaultCopyWith<Vault> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VaultCopyWith<$Res> {
  factory $VaultCopyWith(Vault value, $Res Function(Vault) then) = _$VaultCopyWithImpl<$Res, Vault>;
  @useResult
  $Res call(
      {String id,
      String name,
      String? content,
      DateTime createdAt,
      String ownerPubkey,
      String? ownerName,
      List<
              ({
                int createdAt,
                String creatorPubkey,
                int? distributionVersion,
                String? instructions,
                bool? isReceived,
                String? nostrEventId,
                String? ownerName,
                List<Map<String, String>>? peers,
                String primeMod,
                DateTime? receivedAt,
                String? recipientPubkey,
                List<String>? relayUrls,
                String shard,
                int shardIndex,
                int threshold,
                int totalShards,
                String? vaultId,
                String? vaultName
              })>
          shards,
      List<RecoveryRequest> recoveryRequests,
      ({
        String? contentHash,
        DateTime createdAt,
        int distributionVersion,
        String? instructions,
        DateTime? lastContentChange,
        DateTime? lastRedistribution,
        DateTime lastUpdated,
        List<String> relays,
        String specVersion,
        BackupStatus status,
        List<
            ({
              DateTime? acknowledgedAt,
              int? acknowledgedDistributionVersion,
              String? acknowledgmentEventId,
              String? giftWrapEventId,
              String id,
              String? inviteCode,
              bool isOwner,
              String? keyShare,
              DateTime? lastSeen,
              String? name,
              String? pubkey,
              StewardStatus status
            })> stewards,
        int threshold,
        int totalKeys,
        String vaultId
      })? backupConfig,
      bool isArchived,
      DateTime? archivedAt,
      String? archivedReason});
}

/// @nodoc
class _$VaultCopyWithImpl<$Res, $Val extends Vault> implements $VaultCopyWith<$Res> {
  _$VaultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? content = freezed,
    Object? createdAt = null,
    Object? ownerPubkey = null,
    Object? ownerName = freezed,
    Object? shards = null,
    Object? recoveryRequests = null,
    Object? backupConfig = freezed,
    Object? isArchived = null,
    Object? archivedAt = freezed,
    Object? archivedReason = freezed,
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
      content: freezed == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String?,
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
      shards: null == shards
          ? _value.shards
          : shards // ignore: cast_nullable_to_non_nullable
              as List<
                  ({
                    int createdAt,
                    String creatorPubkey,
                    int? distributionVersion,
                    String? instructions,
                    bool? isReceived,
                    String? nostrEventId,
                    String? ownerName,
                    List<Map<String, String>>? peers,
                    String primeMod,
                    DateTime? receivedAt,
                    String? recipientPubkey,
                    List<String>? relayUrls,
                    String shard,
                    int shardIndex,
                    int threshold,
                    int totalShards,
                    String? vaultId,
                    String? vaultName
                  })>,
      recoveryRequests: null == recoveryRequests
          ? _value.recoveryRequests
          : recoveryRequests // ignore: cast_nullable_to_non_nullable
              as List<RecoveryRequest>,
      backupConfig: freezed == backupConfig
          ? _value.backupConfig
          : backupConfig // ignore: cast_nullable_to_non_nullable
              as ({
              String? contentHash,
              DateTime createdAt,
              int distributionVersion,
              String? instructions,
              DateTime? lastContentChange,
              DateTime? lastRedistribution,
              DateTime lastUpdated,
              List<String> relays,
              String specVersion,
              BackupStatus status,
              List<
                  ({
                    DateTime? acknowledgedAt,
                    int? acknowledgedDistributionVersion,
                    String? acknowledgmentEventId,
                    String? giftWrapEventId,
                    String id,
                    String? inviteCode,
                    bool isOwner,
                    String? keyShare,
                    DateTime? lastSeen,
                    String? name,
                    String? pubkey,
                    StewardStatus status
                  })> stewards,
              int threshold,
              int totalKeys,
              String vaultId
            })?,
      isArchived: null == isArchived
          ? _value.isArchived
          : isArchived // ignore: cast_nullable_to_non_nullable
              as bool,
      archivedAt: freezed == archivedAt
          ? _value.archivedAt
          : archivedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      archivedReason: freezed == archivedReason
          ? _value.archivedReason
          : archivedReason // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$VaultImplCopyWith<$Res> implements $VaultCopyWith<$Res> {
  factory _$$VaultImplCopyWith(_$VaultImpl value, $Res Function(_$VaultImpl) then) =
      __$$VaultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String? content,
      DateTime createdAt,
      String ownerPubkey,
      String? ownerName,
      List<
              ({
                int createdAt,
                String creatorPubkey,
                int? distributionVersion,
                String? instructions,
                bool? isReceived,
                String? nostrEventId,
                String? ownerName,
                List<Map<String, String>>? peers,
                String primeMod,
                DateTime? receivedAt,
                String? recipientPubkey,
                List<String>? relayUrls,
                String shard,
                int shardIndex,
                int threshold,
                int totalShards,
                String? vaultId,
                String? vaultName
              })>
          shards,
      List<RecoveryRequest> recoveryRequests,
      ({
        String? contentHash,
        DateTime createdAt,
        int distributionVersion,
        String? instructions,
        DateTime? lastContentChange,
        DateTime? lastRedistribution,
        DateTime lastUpdated,
        List<String> relays,
        String specVersion,
        BackupStatus status,
        List<
            ({
              DateTime? acknowledgedAt,
              int? acknowledgedDistributionVersion,
              String? acknowledgmentEventId,
              String? giftWrapEventId,
              String id,
              String? inviteCode,
              bool isOwner,
              String? keyShare,
              DateTime? lastSeen,
              String? name,
              String? pubkey,
              StewardStatus status
            })> stewards,
        int threshold,
        int totalKeys,
        String vaultId
      })? backupConfig,
      bool isArchived,
      DateTime? archivedAt,
      String? archivedReason});
}

/// @nodoc
class __$$VaultImplCopyWithImpl<$Res> extends _$VaultCopyWithImpl<$Res, _$VaultImpl>
    implements _$$VaultImplCopyWith<$Res> {
  __$$VaultImplCopyWithImpl(_$VaultImpl _value, $Res Function(_$VaultImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? content = freezed,
    Object? createdAt = null,
    Object? ownerPubkey = null,
    Object? ownerName = freezed,
    Object? shards = null,
    Object? recoveryRequests = null,
    Object? backupConfig = freezed,
    Object? isArchived = null,
    Object? archivedAt = freezed,
    Object? archivedReason = freezed,
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
      content: freezed == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String?,
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
      shards: null == shards
          ? _value._shards
          : shards // ignore: cast_nullable_to_non_nullable
              as List<
                  ({
                    int createdAt,
                    String creatorPubkey,
                    int? distributionVersion,
                    String? instructions,
                    bool? isReceived,
                    String? nostrEventId,
                    String? ownerName,
                    List<Map<String, String>>? peers,
                    String primeMod,
                    DateTime? receivedAt,
                    String? recipientPubkey,
                    List<String>? relayUrls,
                    String shard,
                    int shardIndex,
                    int threshold,
                    int totalShards,
                    String? vaultId,
                    String? vaultName
                  })>,
      recoveryRequests: null == recoveryRequests
          ? _value._recoveryRequests
          : recoveryRequests // ignore: cast_nullable_to_non_nullable
              as List<RecoveryRequest>,
      backupConfig: freezed == backupConfig
          ? _value.backupConfig
          : backupConfig // ignore: cast_nullable_to_non_nullable
              as ({
              String? contentHash,
              DateTime createdAt,
              int distributionVersion,
              String? instructions,
              DateTime? lastContentChange,
              DateTime? lastRedistribution,
              DateTime lastUpdated,
              List<String> relays,
              String specVersion,
              BackupStatus status,
              List<
                  ({
                    DateTime? acknowledgedAt,
                    int? acknowledgedDistributionVersion,
                    String? acknowledgmentEventId,
                    String? giftWrapEventId,
                    String id,
                    String? inviteCode,
                    bool isOwner,
                    String? keyShare,
                    DateTime? lastSeen,
                    String? name,
                    String? pubkey,
                    StewardStatus status
                  })> stewards,
              int threshold,
              int totalKeys,
              String vaultId
            })?,
      isArchived: null == isArchived
          ? _value.isArchived
          : isArchived // ignore: cast_nullable_to_non_nullable
              as bool,
      archivedAt: freezed == archivedAt
          ? _value.archivedAt
          : archivedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      archivedReason: freezed == archivedReason
          ? _value.archivedReason
          : archivedReason // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$VaultImpl implements _Vault {
  const _$VaultImpl(
      {required this.id,
      required this.name,
      this.content,
      required this.createdAt,
      required this.ownerPubkey,
      this.ownerName,
      final List<
              ({
                int createdAt,
                String creatorPubkey,
                int? distributionVersion,
                String? instructions,
                bool? isReceived,
                String? nostrEventId,
                String? ownerName,
                List<Map<String, String>>? peers,
                String primeMod,
                DateTime? receivedAt,
                String? recipientPubkey,
                List<String>? relayUrls,
                String shard,
                int shardIndex,
                int threshold,
                int totalShards,
                String? vaultId,
                String? vaultName
              })>
          shards = const [],
      final List<RecoveryRequest> recoveryRequests = const [],
      this.backupConfig,
      this.isArchived = false,
      this.archivedAt,
      this.archivedReason})
      : _shards = shards,
        _recoveryRequests = recoveryRequests;

  @override
  final String id;
  @override
  final String name;
  @override
  final String? content;
// Nullable - null when content is not decrypted
  @override
  final DateTime createdAt;
  @override
  final String ownerPubkey;
// Hex format, 64 characters
  @override
  final String? ownerName;
// Name of the vault owner
  final List<
      ({
        int createdAt,
        String creatorPubkey,
        int? distributionVersion,
        String? instructions,
        bool? isReceived,
        String? nostrEventId,
        String? ownerName,
        List<Map<String, String>>? peers,
        String primeMod,
        DateTime? receivedAt,
        String? recipientPubkey,
        List<String>? relayUrls,
        String shard,
        int shardIndex,
        int threshold,
        int totalShards,
        String? vaultId,
        String? vaultName
      })> _shards;
// Name of the vault owner
  @override
  @JsonKey()
  List<
      ({
        int createdAt,
        String creatorPubkey,
        int? distributionVersion,
        String? instructions,
        bool? isReceived,
        String? nostrEventId,
        String? ownerName,
        List<Map<String, String>>? peers,
        String primeMod,
        DateTime? receivedAt,
        String? recipientPubkey,
        List<String>? relayUrls,
        String shard,
        int shardIndex,
        int threshold,
        int totalShards,
        String? vaultId,
        String? vaultName
      })> get shards {
    if (_shards is EqualUnmodifiableListView) return _shards;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_shards);
  }

// List of shards (single as steward, multiple during recovery)
  final List<RecoveryRequest> _recoveryRequests;
// List of shards (single as steward, multiple during recovery)
  @override
  @JsonKey()
  List<RecoveryRequest> get recoveryRequests {
    if (_recoveryRequests is EqualUnmodifiableListView) return _recoveryRequests;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_recoveryRequests);
  }

// Embedded recovery requests
  @override
  final ({
    String? contentHash,
    DateTime createdAt,
    int distributionVersion,
    String? instructions,
    DateTime? lastContentChange,
    DateTime? lastRedistribution,
    DateTime lastUpdated,
    List<String> relays,
    String specVersion,
    BackupStatus status,
    List<
        ({
          DateTime? acknowledgedAt,
          int? acknowledgedDistributionVersion,
          String? acknowledgmentEventId,
          String? giftWrapEventId,
          String id,
          String? inviteCode,
          bool isOwner,
          String? keyShare,
          DateTime? lastSeen,
          String? name,
          String? pubkey,
          StewardStatus status
        })> stewards,
    int threshold,
    int totalKeys,
    String vaultId
  })? backupConfig;
// Optional backup configuration
  @override
  @JsonKey()
  final bool isArchived;
// Whether this vault is archived
  @override
  final DateTime? archivedAt;
// When the vault was archived
  @override
  final String? archivedReason;

  @override
  String toString() {
    return 'Vault(id: $id, name: $name, content: $content, createdAt: $createdAt, ownerPubkey: $ownerPubkey, ownerName: $ownerName, shards: $shards, recoveryRequests: $recoveryRequests, backupConfig: $backupConfig, isArchived: $isArchived, archivedAt: $archivedAt, archivedReason: $archivedReason)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VaultImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.createdAt, createdAt) || other.createdAt == createdAt) &&
            (identical(other.ownerPubkey, ownerPubkey) || other.ownerPubkey == ownerPubkey) &&
            (identical(other.ownerName, ownerName) || other.ownerName == ownerName) &&
            const DeepCollectionEquality().equals(other._shards, _shards) &&
            const DeepCollectionEquality().equals(other._recoveryRequests, _recoveryRequests) &&
            (identical(other.backupConfig, backupConfig) || other.backupConfig == backupConfig) &&
            (identical(other.isArchived, isArchived) || other.isArchived == isArchived) &&
            (identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt) &&
            (identical(other.archivedReason, archivedReason) ||
                other.archivedReason == archivedReason));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      content,
      createdAt,
      ownerPubkey,
      ownerName,
      const DeepCollectionEquality().hash(_shards),
      const DeepCollectionEquality().hash(_recoveryRequests),
      backupConfig,
      isArchived,
      archivedAt,
      archivedReason);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$VaultImplCopyWith<_$VaultImpl> get copyWith =>
      __$$VaultImplCopyWithImpl<_$VaultImpl>(this, _$identity);
}

abstract class _Vault implements Vault {
  const factory _Vault(
      {required final String id,
      required final String name,
      final String? content,
      required final DateTime createdAt,
      required final String ownerPubkey,
      final String? ownerName,
      final List<
              ({
                int createdAt,
                String creatorPubkey,
                int? distributionVersion,
                String? instructions,
                bool? isReceived,
                String? nostrEventId,
                String? ownerName,
                List<Map<String, String>>? peers,
                String primeMod,
                DateTime? receivedAt,
                String? recipientPubkey,
                List<String>? relayUrls,
                String shard,
                int shardIndex,
                int threshold,
                int totalShards,
                String? vaultId,
                String? vaultName
              })>
          shards,
      final List<RecoveryRequest> recoveryRequests,
      final ({
        String? contentHash,
        DateTime createdAt,
        int distributionVersion,
        String? instructions,
        DateTime? lastContentChange,
        DateTime? lastRedistribution,
        DateTime lastUpdated,
        List<String> relays,
        String specVersion,
        BackupStatus status,
        List<
            ({
              DateTime? acknowledgedAt,
              int? acknowledgedDistributionVersion,
              String? acknowledgmentEventId,
              String? giftWrapEventId,
              String id,
              String? inviteCode,
              bool isOwner,
              String? keyShare,
              DateTime? lastSeen,
              String? name,
              String? pubkey,
              StewardStatus status
            })> stewards,
        int threshold,
        int totalKeys,
        String vaultId
      })? backupConfig,
      final bool isArchived,
      final DateTime? archivedAt,
      final String? archivedReason}) = _$VaultImpl;

  @override
  String get id;
  @override
  String get name;
  @override
  String? get content;
  @override // Nullable - null when content is not decrypted
  DateTime get createdAt;
  @override
  String get ownerPubkey;
  @override // Hex format, 64 characters
  String? get ownerName;
  @override // Name of the vault owner
  List<
      ({
        int createdAt,
        String creatorPubkey,
        int? distributionVersion,
        String? instructions,
        bool? isReceived,
        String? nostrEventId,
        String? ownerName,
        List<Map<String, String>>? peers,
        String primeMod,
        DateTime? receivedAt,
        String? recipientPubkey,
        List<String>? relayUrls,
        String shard,
        int shardIndex,
        int threshold,
        int totalShards,
        String? vaultId,
        String? vaultName
      })> get shards;
  @override // List of shards (single as steward, multiple during recovery)
  List<RecoveryRequest> get recoveryRequests;
  @override // Embedded recovery requests
  ({
    String? contentHash,
    DateTime createdAt,
    int distributionVersion,
    String? instructions,
    DateTime? lastContentChange,
    DateTime? lastRedistribution,
    DateTime lastUpdated,
    List<String> relays,
    String specVersion,
    BackupStatus status,
    List<
        ({
          DateTime? acknowledgedAt,
          int? acknowledgedDistributionVersion,
          String? acknowledgmentEventId,
          String? giftWrapEventId,
          String id,
          String? inviteCode,
          bool isOwner,
          String? keyShare,
          DateTime? lastSeen,
          String? name,
          String? pubkey,
          StewardStatus status
        })> stewards,
    int threshold,
    int totalKeys,
    String vaultId
  })? get backupConfig;
  @override // Optional backup configuration
  bool get isArchived;
  @override // Whether this vault is archived
  DateTime? get archivedAt;
  @override // When the vault was archived
  String? get archivedReason;
  @override
  @JsonKey(ignore: true)
  _$$VaultImplCopyWith<_$VaultImpl> get copyWith => throw _privateConstructorUsedError;
}
