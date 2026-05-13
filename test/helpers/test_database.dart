import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'package:horcrux/database/app_database.dart';

/// Builds an in-memory [AppDatabase] for plain Dart unit tests. SQLCipher is
/// intentionally NOT applied — the encryption layer is exercised by integration
/// tests only. Each call returns a fresh DB; close it via `await db.close()`.
AppDatabase newTestDatabase() {
  return AppDatabase(NativeDatabase.memory());
}

/// Builds an in-memory [AppDatabase] suitable for Flutter widget / golden
/// tests. Uses [DatabaseConnection] with `closeStreamsSynchronously: true` so
/// Drift query-stream teardown completes synchronously — this is the pattern
/// the Drift docs recommend to avoid "timer still pending" failures after a
/// widget test disposes its tree.
///
/// Each call returns a fresh DB. Pass the result to
/// `appDatabaseProvider.overrideWithValue(...)` in the test's
/// [ProviderContainer].
AppDatabase newWidgetTestDatabase() {
  return AppDatabase(
    DatabaseConnection(
      NativeDatabase.memory(),
      closeStreamsSynchronously: true,
    ),
  );
}

/// Convenience: a deterministic clock so fixtures can reason about ordering
/// without depending on `DateTime.now()`.
class FixedClock {
  FixedClock(int startEpochMillis) : _now = startEpochMillis;
  int _now;

  int now() => _now;
  int advance(Duration by) {
    _now += by.inMilliseconds;
    return _now;
  }
}

/// Typed fixture for inserting a vault row that this device owns. Composes
/// with [StewardFixture] to add stewards, and with [VaultFixture.selfShare] to
/// register the owner-as-self-steward carve-out.
///
/// Example:
/// ```dart
/// final db = newTestDatabase();
/// final fixture = await VaultFixture.owned(
///   db,
///   ownerPubkey: 'aabb...',
///   threshold: 2,
///   totalShares: 3,
///   content: 'ciphertext',
/// );
/// ```
class VaultFixture {
  VaultFixture._({
    required this.db,
    required this.vaultId,
    required this.role,
  });

  final AppDatabase db;
  final String vaultId;
  final VaultFixtureRole role;

  static Future<VaultFixture> owned(
    AppDatabase db, {
    String? id,
    String name = 'Test Vault',
    required String ownerPubkey,
    String? ownerName,
    int threshold = 2,
    int totalShares = 3,
    String content = 'placeholder-ciphertext',
    List<int>? contentHmac,
    int? createdAt,
  }) async {
    final vaultId = id ?? _uuid('vault');
    final now = createdAt ?? DateTime.now().millisecondsSinceEpoch;

    await db.transaction(() async {
      await db.into(db.vaults).insert(VaultsCompanion.insert(
            id: vaultId,
            name: name,
            ownerPubkey: ownerPubkey,
            ownerName: Value(ownerName),
            threshold: threshold,
            totalShares: totalShares,
            createdAt: now,
          ));
      await db.into(db.ownedVaults).insert(OwnedVaultsCompanion.insert(
            vaultId: vaultId,
            content: content,
            contentHmac: contentHmac == null
                ? Uint8List.fromList(List.filled(32, 0))
                : Uint8List.fromList(contentHmac),
            createdBySelfAt: now,
          ));
    });

    return VaultFixture._(
      db: db,
      vaultId: vaultId,
      role: VaultFixtureRole.owned,
    );
  }

  static Future<VaultFixture> stewarded(
    AppDatabase db, {
    String? id,
    String name = 'Stewarded Vault',
    required String ownerPubkey,
    String? ownerName,
    int threshold = 2,
    int totalShares = 3,
    int? createdAt,
  }) async {
    final vaultId = id ?? _uuid('vault');
    final now = createdAt ?? DateTime.now().millisecondsSinceEpoch;

    await db.into(db.vaults).insert(VaultsCompanion.insert(
          id: vaultId,
          name: name,
          ownerPubkey: ownerPubkey,
          ownerName: Value(ownerName),
          threshold: threshold,
          totalShares: totalShares,
          createdAt: now,
        ));

    return VaultFixture._(
      db: db,
      vaultId: vaultId,
      role: VaultFixtureRole.stewarded,
    );
  }

  /// Insert an active steward at the given [shareIndex]. Returns the
  /// generated steward id.
  Future<String> withSteward({
    required int shareIndex,
    String? id,
    String? pubkey,
    String? name,
    String? contactInfo,
    bool isOwner = false,
    int? joinedAt,
  }) async {
    final stewardId = id ?? _uuid('steward');
    final now = joinedAt ?? DateTime.now().millisecondsSinceEpoch;
    await db.into(db.stewards).insert(StewardsCompanion.insert(
          id: stewardId,
          vaultId: vaultId,
          shareIndex: shareIndex,
          pubkey: Value(pubkey),
          name: Value(name),
          contactInfo: Value(contactInfo),
          isOwner: Value(isOwner),
          joinedAt: now,
        ));
    return stewardId;
  }

  /// Add a relay row tagged with [role].
  Future<void> withRelay({required String url, String role = 'owner'}) async {
    await db.into(db.vaultRelays).insert(VaultRelaysCompanion.insert(
          id: _uuid('vrelay'),
          vaultId: vaultId,
          url: url,
          role: role,
          addedAt: DateTime.now().millisecondsSinceEpoch,
        ));
  }
}

enum VaultFixtureRole { owned, stewarded }

/// Fixture for inserting held_shares rows (Phase 2a+).
///
/// Example:
/// ```dart
/// final db = newTestDatabase();
/// final vaultFixture = await VaultFixture.stewarded(db, ownerPubkey: 'aa'*32);
/// await HeldShareFixture.insert(
///   db,
///   vaultId: vaultFixture.vaultId,
///   shareIndex: 0,
///   payload: 'shamir-bytes',
/// );
/// ```
class HeldShareFixture {
  /// Insert a [HeldShareRow] for [vaultId] and return the generated id.
  static Future<String> insert(
    AppDatabase db, {
    required String vaultId,
    required int shareIndex,
    required String payload,
    int distributionVersion = 1,
    String? nostrEventId,
    String? lastSeenRelay,
    bool pushEnabled = true,
    int? receivedAt,
  }) async {
    final now = receivedAt ?? DateTime.now().millisecondsSinceEpoch;
    final id = '${vaultId}_share_${shareIndex}_${distributionVersion}_$now';
    await db.into(db.heldShares).insert(HeldSharesCompanion.insert(
          id: id,
          vaultId: vaultId,
          shareIndex: shareIndex,
          sharePayload: payload,
          distributionVersion: distributionVersion,
          receivedAt: now,
          nostrEventId: Value(nostrEventId),
          lastSeenRelay: Value(lastSeenRelay),
          pushEnabled: Value(pushEnabled),
        ));
    return id;
  }
}

class RecoverySessionFixture {
  RecoverySessionFixture._({
    required this.db,
    required this.vaultId,
    required this.requestId,
    required this.initiatorPubkey,
    required this.participantPubkeys,
    required this.threshold,
    required this.startedAtMs,
    required this.expiresAtMs,
  });

  final AppDatabase db;
  final String vaultId;
  final String requestId;
  final String initiatorPubkey;
  final List<String> participantPubkeys;
  final int threshold;
  final int startedAtMs;
  final int expiresAtMs;

  /// Seed a recovery request in `inProgress` state plus participant rows.
  ///
  /// If [vaultId] does not already exist, this helper creates a minimal vault
  /// row first so foreign keys are satisfied.
  static Future<RecoverySessionFixture> inProgress(
    AppDatabase db, {
    String? vaultId,
    String? requestId,
    String ownerPubkey = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
    String initiatorPubkey = 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
    List<String>? participantPubkeys,
    int threshold = 2,
    int? startedAtMs,
    int? expiresAtMs,
    int distributionVersionAtStart = 1,
    bool isPractice = false,
  }) async {
    final resolvedVaultId = vaultId ?? _uuid('vault');
    final now = startedAtMs ?? DateTime.now().millisecondsSinceEpoch;
    final expires = expiresAtMs ?? now + const Duration(hours: 1).inMilliseconds;
    final participants = participantPubkeys ??
        <String>[
          'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
          'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd',
          'eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee',
        ];
    final resolvedRequestId = requestId ?? _uuid('recovery');

    final existingVault = await db.vaultDao.getById(resolvedVaultId);
    if (existingVault == null) {
      await db.into(db.vaults).insert(
            VaultsCompanion.insert(
              id: resolvedVaultId,
              name: 'Recovery Fixture Vault',
              ownerPubkey: ownerPubkey,
              threshold: threshold,
              totalShares: participants.length,
              createdAt: now,
            ),
          );
    }

    await db.transaction(() async {
      await db.into(db.recoveryRequests).insert(
            RecoveryRequestsCompanion.insert(
              id: resolvedRequestId,
              vaultId: resolvedVaultId,
              requestEventId: Value('req_evt_$resolvedRequestId'),
              initiatorPubkey: initiatorPubkey,
              startedAt: now,
              expiresAt: Value(expires),
              distributionVersionAtStart: distributionVersionAtStart,
              thresholdAtStart: threshold,
              status: 'inProgress',
              isPractice: Value(isPractice),
              eventCreationTimeMs: Value(now),
            ),
          );
      await db.batch((b) {
        for (final pubkey in participants) {
          b.insert(
            db.recoveryRequestParticipants,
            RecoveryRequestParticipantsCompanion.insert(
              requestId: resolvedRequestId,
              pubkey: pubkey,
            ),
            mode: InsertMode.insertOrIgnore,
          );
        }
      });
    });

    return RecoverySessionFixture._(
      db: db,
      vaultId: resolvedVaultId,
      requestId: resolvedRequestId,
      initiatorPubkey: initiatorPubkey,
      participantPubkeys: participants,
      threshold: threshold,
      startedAtMs: now,
      expiresAtMs: expires,
    );
  }

  /// Insert or replace a response row for this recovery request.
  Future<void> withResponse({
    required String responderPubkey,
    required bool approved,
    String sharePayload = '',
    int shareDistributionVersion = 1,
    int? receivedAtMs,
    int? respondedAtMs,
    String? nostrEventId,
    String? errorMessage,
  }) async {
    final now = receivedAtMs ?? DateTime.now().millisecondsSinceEpoch;
    await db.into(db.recoveryResponses).insertOnConflictUpdate(
          RecoveryResponsesCompanion.insert(
            id: '${requestId}_$responderPubkey',
            requestId: requestId,
            stewardId: const Value.absent(),
            responderPubkey: responderPubkey,
            sharePayload: sharePayload,
            shareDistributionVersion: shareDistributionVersion,
            receivedAt: now,
            nostrEventId: Value(nostrEventId),
            replyingToEventId: const Value.absent(),
            approved: approved,
            respondedAtMs: Value(respondedAtMs ?? now),
            errorMessage: Value(errorMessage),
          ),
        );
  }
}

int _counter = 0;
String _uuid(String prefix) {
  _counter += 1;
  return '$prefix-$_counter-${DateTime.now().microsecondsSinceEpoch}';
}
