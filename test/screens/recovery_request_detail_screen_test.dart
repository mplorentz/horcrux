import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/models/backup_config.dart';
import 'package:horcrux/models/recovery_request.dart';
import 'package:horcrux/models/steward.dart';
import 'package:horcrux/models/vault.dart';
import 'package:horcrux/providers/key_provider.dart';
import 'package:horcrux/providers/vault_provider.dart';
import 'package:horcrux/screens/recovery_request_detail_screen.dart';
import 'package:horcrux/services/login_service.dart';

void main() {
  String repeatedHex(String char) => List.filled(64, char).join();

  final currentStewardPubkey = repeatedHex('a');
  final initiatorPubkey = repeatedHex('b');
  final ownerPubkey = repeatedHex('c');

  Vault buildTestVault() {
    return Vault(
      id: 'vault-1',
      name: 'Test Vault',
      content: null,
      createdAt: DateTime(2026, 1, 1),
      ownerPubkey: ownerPubkey,
      ownerName: 'Owner',
      backupConfig: createBackupConfig(
        vaultId: 'vault-1',
        threshold: 2,
        totalKeys: 2,
        stewards: [
          createSteward(pubkey: initiatorPubkey, name: 'Initiator'),
          createSteward(pubkey: currentStewardPubkey, name: 'Current Steward'),
        ],
        relays: const ['wss://relay.example.com'],
      ),
    );
  }

  RecoveryRequest buildRecoveryRequest({
    required RecoveryResponse responseForCurrentSteward,
  }) {
    return RecoveryRequest(
      id: 'request-1',
      vaultId: 'vault-1',
      initiatorPubkey: initiatorPubkey,
      requestedAt: DateTime.now().subtract(const Duration(hours: 1)),
      status: RecoveryRequestStatus.inProgress,
      threshold: 2,
      stewardResponses: {
        currentStewardPubkey: responseForCurrentSteward,
      },
    );
  }

  Future<void> pumpScreen(
    WidgetTester tester, {
    required RecoveryRequest request,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          loginServiceProvider.overrideWithValue(
            _FakeLoginService(currentStewardPubkey),
          ),
          vaultProvider('vault-1').overrideWith((_) => Stream.value(buildTestVault())),
        ],
        child: MaterialApp(
          home: RecoveryRequestDetailScreen(recoveryRequest: request),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('error response does not trigger already-responded gate', (tester) async {
    final request = buildRecoveryRequest(
      responseForCurrentSteward: RecoveryResponse(
        pubkey: currentStewardPubkey,
        approved: false,
        errorMessage: 'Failed to send response',
      ),
    );

    await pumpScreen(tester, request: request);

    expect(find.text('Already Responded'), findsNothing);
    expect(find.text('Approve'), findsOneWidget);
    expect(find.text('Deny'), findsOneWidget);
  });

  testWidgets('approved response still shows already-responded dialog', (tester) async {
    final request = buildRecoveryRequest(
      responseForCurrentSteward: RecoveryResponse(
        pubkey: currentStewardPubkey,
        approved: true,
        respondedAt: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
    );

    await pumpScreen(tester, request: request);

    expect(find.text('Already Responded'), findsOneWidget);
    expect(find.text('You already approved this recovery request.'), findsOneWidget);
    expect(find.text('Approve'), findsNothing);
    expect(find.text('Deny'), findsNothing);
  });
}

class _FakeLoginService extends LoginService {
  _FakeLoginService(this._pubkey);

  final String _pubkey;

  @override
  Future<String?> getCurrentPublicKey() async => _pubkey;
}
