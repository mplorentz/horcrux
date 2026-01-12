import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/models/shard_data.dart';
import 'package:horcrux/models/vault.dart';
import 'package:horcrux/providers/key_provider.dart';
import 'package:horcrux/providers/vault_provider.dart';
import 'package:horcrux/widgets/steward_list.dart';

void main() {
  testWidgets('deduplicates owner when shard peers include creator', (tester) async {
    const vaultId = 'vault-dedupe';
    final ownerPubkey = 'a' * 64;
    final stewardPubkeyB = 'b' * 64;
    final stewardPubkeyC = 'c' * 64;

    final shard = createShardData(
      shard: 'shard-1',
      threshold: 2,
      shardIndex: 0,
      totalShards: 3,
      primeMod: 'prime-mod',
      creatorPubkey: ownerPubkey,
      vaultId: vaultId,
      vaultName: 'Vault Dedupe',
      ownerName: 'Device A',
      peers: [
        {'name': 'Device A', 'pubkey': ownerPubkey}, // Owner included in peers
        {'name': 'Device B', 'pubkey': stewardPubkeyB},
        {'name': 'Device C', 'pubkey': stewardPubkeyC},
      ],
      recipientPubkey: stewardPubkeyC,
      isReceived: true,
    );

    final vault = Vault(
      id: vaultId,
      name: 'Vault Dedupe',
      content: null,
      createdAt: DateTime.now(),
      ownerPubkey: ownerPubkey,
      ownerName: 'Device A',
      shards: [shard],
      recoveryRequests: const [],
    );

    final container = ProviderContainer(
      overrides: [
        vaultProvider(vaultId).overrideWith((ref) => Stream.value(vault)),
        currentPublicKeyProvider.overrideWith((ref) => stewardPubkeyC),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: StewardList(vaultId: vaultId),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Device A'), findsOneWidget);
    expect(find.text('Device B'), findsOneWidget);
    expect(find.text('You (Device C)'), findsOneWidget);
  });
}
