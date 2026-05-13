import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/models/backup_config.dart';
import 'package:horcrux/models/recovery_request.dart';
import 'package:horcrux/models/steward.dart';
import 'package:horcrux/models/vault.dart';
import 'package:horcrux/providers/recovery_provider.dart';
import 'package:horcrux/providers/vault_provider.dart';
import 'package:horcrux/widgets/recovery_stewards_widget.dart';
import 'package:horcrux/widgets/theme.dart';

void main() {
  final testPubkey1 = 'a' * 64;
  final testPubkey2 = 'b' * 64;
  final testPubkey3 = 'c' * 64;

  testWidgets('shows Awaiting Response when stewards have not responded', (tester) async {
    final request = RecoveryRequest.makeFromParticipants(
      id: 'test-request',
      vaultId: 'test-vault',
      initiatorPubkey: testPubkey1,
      requestedAt: DateTime.now().subtract(const Duration(hours: 1)),
      status: RecoveryRequestStatus.inProgress,
      threshold: 2,
      stewardPubkeys: const [],
    );

    final vault = Vault(
      id: 'test-vault',
      name: 'Test Vault',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ownerPubkey: testPubkey1,
      backupConfig: createBackupConfig(
        vaultId: 'test-vault',
        threshold: 2,
        totalKeys: 2,
        stewards: [
          createSteward(pubkey: testPubkey2, name: 'Alice'),
          createSteward(pubkey: testPubkey3, name: 'Bob'),
        ],
        relays: ['wss://relay.example.com'],
      ),
    );

    final container = ProviderContainer(
      overrides: [
        recoveryRequestByIdProvider('test-request').overrideWith(
          (ref) => AsyncValue.data(request),
        ),
        vaultProvider('test-vault').overrideWith((ref) => Stream.value(vault)),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: horcrux3Dark,
          home: const Scaffold(
            body: RecoveryStewardsWidget(recoveryRequestId: 'test-request'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Awaiting Response'), findsNWidgets(2));

    container.dispose();
  });
}
