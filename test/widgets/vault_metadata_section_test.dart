import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/models/share.dart';
import 'package:horcrux/models/vault.dart';
import 'package:horcrux/providers/key_provider.dart';
import 'package:horcrux/providers/vault_provider.dart';
import 'package:horcrux/widgets/vault_metadata_section.dart';

void main() {
  testWidgets('shows threshold from the most recent shard', (tester) async {
    const vaultId = 'vault-latest-shard';
    final ownerPubkey = 'a' * 64;
    final stewardPubkey = 'b' * 64;

    final olderShard = createShare(
      payload: 'older-shard',
      threshold: 3,
      shareIndex: 0,
      totalShares: 3,
      primeMod: 'prime-mod',
      creatorPubkey: ownerPubkey,
      vaultId: vaultId,
      distributionVersion: 0,
    );

    final newerShard = olderShard.copyWith(
      payload: 'newer-shard',
      threshold: 2,
      shareIndex: 1,
      distributionVersion: 1,
      createdAt: olderShard.createdAt + 10,
    );

    final vault = Vault(
      id: vaultId,
      name: 'Latest Threshold Vault',
      content: null,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ownerPubkey: ownerPubkey,
      shares: [olderShard, newerShard],
    );

    final container = ProviderContainer(
      overrides: [
        vaultProvider(vaultId).overrideWith((ref) => Stream.value(vault)),
        currentPublicKeyProvider.overrideWith((ref) => Future.value(stewardPubkey)),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: VaultMetadataSection(vaultId: vaultId),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('minimum of 2 keys'), findsOneWidget);
  });
}
