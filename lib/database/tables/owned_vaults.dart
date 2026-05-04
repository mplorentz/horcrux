import 'package:drift/drift.dart';

import 'vaults.dart';

/// Owner-only extension table. Existence of a row here is the marker "this
/// device is the owner of this vault" and gates the cross-role write
/// precedence rules.
///
/// `content` is NIP-44 ciphertext (the same blob the owner replicates to
/// their Nostr profile). `contentHmac` is HMAC-SHA-256 of plaintext, keyed
/// under the DB key — used so an attacker with DB-only access cannot use
/// the hash as a low-entropy confirmation oracle.
@DataClassName('OwnedVaultRow')
class OwnedVaults extends Table {
  TextColumn get vaultId =>
      text().references(Vaults, #id, onDelete: KeyAction.cascade)();
  TextColumn get content => text()();
  BlobColumn get contentHmac => blob()();
  IntColumn get createdBySelfAt => integer()();

  @override
  Set<Column> get primaryKey => {vaultId};
}
