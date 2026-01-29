import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/models/shard_data.dart';
import 'package:horcrux/models/vault.dart';
import 'package:horcrux/providers/key_provider.dart';
import 'package:horcrux/providers/vault_provider.dart';
import 'package:horcrux/widgets/steward_list.dart';
import '../fixtures/test_keys.dart';

void main() {
  testWidgets('includes owner in steward list when owner is in shard peers', (tester) async {
    const vaultId = 'vault-owner-in-peers';
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
      vaultName: 'Vault Owner In Peers',
      ownerName: 'Device A',
      stewards: [
        {'name': 'Device A', 'pubkey': ownerPubkey}, // Owner included in peers
        {'name': 'Device B', 'pubkey': stewardPubkeyB},
        {'name': 'Device C', 'pubkey': stewardPubkeyC},
      ],
      recipientPubkey: stewardPubkeyC,
      isReceived: true,
    );

    final vault = Vault(
      id: vaultId,
      name: 'Vault Owner In Peers',
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
          home: Scaffold(body: StewardList(vaultId: vaultId)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Owner SHOULD appear in steward list when they're in shard peers
    expect(find.text('Device A'), findsOneWidget);
    // All stewards should appear
    expect(find.text('Device B'), findsOneWidget);
    expect(find.text('You (Device C)'), findsOneWidget);
  });
}
