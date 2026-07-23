import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:horcrux/screens/recovery_status_screen.dart';
import 'package:horcrux/screens/vault_detail_screen.dart';
import 'package:horcrux/screens/vault_list_screen.dart';

import '../helpers/golden_test_helpers.dart';
import '../helpers/play_store_screenshot_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(resetPlayStoreViewConfiguration);

  group('Play Store screenshot goldens', () {
    for (final formFactor in playStoreFormFactors) {
      testGoldens('01 vault list — ${formFactor.storeFolderName}', (tester) async {
        final harness = await pumpPlayStoreGoldenWidget(
          tester,
          const VaultListScreen(),
          formFactor: formFactor,
          overrides: PlayStoreScreenshotFixtures.vaultListOverrides(),
        );
        addTearDown(() => harness.dispose());

        await screenMatchesGolden(
          tester,
          playStoreGoldenName(formFactor, '01_vault_list'),
        );
      });

      testGoldens(
        '02 vault detail steward — ${formFactor.storeFolderName}',
        (tester) async {
          final harness = await pumpPlayStoreGoldenWidget(
            tester,
            playStorePushedScreen(
              const VaultDetailScreen(
                vaultId: PlayStoreScreenshotFixtures.familyVaultId,
              ),
            ),
            formFactor: formFactor,
            overrides: PlayStoreScreenshotFixtures.vaultDetailStewardOverrides(),
          );
          addTearDown(() => harness.dispose());

          await screenMatchesGolden(
            tester,
            playStoreGoldenName(formFactor, '02_vault_detail_steward'),
          );
        },
      );

      testGoldens(
        '03 manage recovery — ${formFactor.storeFolderName}',
        (tester) async {
          final harness = await pumpPlayStoreGoldenWidget(
            tester,
            playStorePushedScreen(
              const RecoveryStatusScreen(
                recoveryRequestId: PlayStoreScreenshotFixtures.recoveryId,
              ),
            ),
            formFactor: formFactor,
            overrides: PlayStoreScreenshotFixtures.manageRecoveryOverrides(),
          );
          addTearDown(() => harness.dispose());

          await screenMatchesGolden(
            tester,
            playStoreGoldenName(formFactor, '03_manage_recovery'),
          );
        },
      );
    }
  });
}
