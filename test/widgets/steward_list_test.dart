import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/models/backup_config.dart';
import 'package:horcrux/models/share.dart';
import 'package:horcrux/models/steward.dart';
import 'package:horcrux/models/steward_status.dart';
import 'package:horcrux/models/vault_detail.dart';
import 'package:horcrux/providers/key_provider.dart';
import 'package:horcrux/providers/vault_provider.dart';
import 'package:horcrux/widgets/steward_list.dart';

void main() {
  testWidgets('shows invited steward before invitation acceptance', (tester) async {
    const vaultId = 'vault-invited-visible';
    final ownerPubkey = 'a' * 64;
    final backupConfig = createBackupConfig(
      vaultId: vaultId,
      threshold: 1,
      totalKeys: 1,
      stewards: [
        createInvitedSteward(name: 'Mac', inviteCode: 'invite-mac-001'),
      ],
      relays: const ['wss://relay.example.com'],
    );

    final vaultDetail = OwnedVaultDetail(
      id: vaultId,
      name: 'Vault With Pending Invite',
      ownerPubkey: ownerPubkey,
      ownerName: 'Owner',
      threshold: 1,
      totalShares: 1,
      stewards: backupConfig.stewards,
      recoveryRequests: const [],
      pushEnabled: true,
      createdAt: DateTime.now(),
      archivedAt: null,
      archivedReason: null,
      backupConfig: backupConfig,
      content: 'encrypted-content',
      selfHeldShare: null,
    );

    final container = ProviderContainer(
      overrides: [
        vaultDetailProvider(vaultId).overrideWith((ref) => Stream.value(vaultDetail)),
        currentPublicKeyProvider.overrideWith((ref) => ownerPubkey),
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

    expect(find.text('Mac'), findsOneWidget);
    expect(find.text('No stewards configured'), findsNothing);
  });

  testWidgets('includes owner in steward list when owner exists in backup config', (tester) async {
    const vaultId = 'vault-owner-in-peers';
    final ownerPubkey = 'a' * 64;
    final stewardPubkeyB = 'b' * 64;
    final stewardPubkeyC = 'c' * 64;

    final backupConfig = createBackupConfig(
      vaultId: vaultId,
      threshold: 2,
      totalKeys: 3,
      stewards: [
        createOwnerSteward(pubkey: ownerPubkey, name: 'Device A')
            .copyWith(status: StewardStatus.holdingKey),
        createSteward(pubkey: stewardPubkeyB, name: 'Device B'),
        createSteward(pubkey: stewardPubkeyC, name: 'Device C'),
      ],
      relays: const ['wss://relay.example.com'],
    );
    final shard = createShare(
      payload: 'shard-1',
      threshold: 2,
      shareIndex: 0,
      totalShares: 3,
      primeMod: 'prime-mod',
      creatorPubkey: ownerPubkey,
      vaultId: vaultId,
      vaultName: 'Vault Owner In Peers',
      ownerName: 'Device A',
      recipientPubkey: stewardPubkeyC,
      isReceived: true,
    );

    final vaultDetail = StewardedVaultDetail(
      id: vaultId,
      name: 'Vault Owner In Peers',
      ownerPubkey: ownerPubkey,
      ownerName: 'Device A',
      threshold: 2,
      totalShares: 3,
      stewards: const [],
      recoveryRequests: const [],
      pushEnabled: false,
      createdAt: DateTime.now(),
      archivedAt: null,
      archivedReason: null,
      backupConfig: backupConfig,
      latestShare: shard,
    );

    final container = ProviderContainer(
      overrides: [
        vaultDetailProvider(vaultId).overrideWith((ref) => Stream.value(vaultDetail)),
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

    // Owner SHOULD appear in steward list when included in backup config.
    expect(find.text('Device A'), findsOneWidget);
    // All stewards should appear
    expect(find.text('Device B'), findsOneWidget);
    expect(find.text('Device C (You)'), findsOneWidget);
  });
}
