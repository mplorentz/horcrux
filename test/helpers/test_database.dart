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

/// Placeholder for a recovery-session fixture. Recovery tables (`recovery_requests`,
/// `recovery_responses`) land in Phase 3, at which point this fixture grows a
/// real `inProgress(...)` constructor. Kept here so Phase 1+ tests can import
/// the same module and add session-state seeding without ripping helpers later.
class RecoverySessionFixture {
  RecoverySessionFixture._();

  /// Reserved for Phase 3.
  static Future<RecoverySessionFixture> inProgress(AppDatabase db) async {
    throw UnimplementedError(
      'RecoverySessionFixture.inProgress lands in Phase 3 with the '
      'recovery_requests / recovery_responses tables.',
    );
  }
}

int _counter = 0;
String _uuid(String prefix) {
  _counter += 1;
  return '$prefix-$_counter-${DateTime.now().microsecondsSinceEpoch}';
}
