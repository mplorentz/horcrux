import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/widgets/theme.dart';

import 'golden_test_helpers.dart';

/// Logical and physical sizes for App Store screenshot goldens.
///
/// Golden and store file names use [storeFolderName] as a suffix:
/// `{screenshotId}_{storeFolderName}.png` (e.g. `01_vault_list_iphone_6_9in.png`).
class AppStoreFormFactor {
  const AppStoreFormFactor({
    required this.storeFolderName,
    required this.logicalWidth,
    required this.logicalHeight,
    required this.physicalWidth,
  });

  /// Device suffix in screenshot file names (e.g. `01_vault_list_iphone_6_9in.png`).
  final String storeFolderName;
  final double logicalWidth;
  final double logicalHeight;
  final double physicalWidth;

  double get devicePixelRatio => physicalWidth / logicalWidth;
  double get physicalHeight => logicalHeight * devicePixelRatio;
}

/// iPhone 6.9" — 1320×2868 px (440×956 logical @ 3×). Apple's required
/// minimum iPhone screenshot size (e.g. iPhone 16/17 Pro Max).
const appStoreIphone69In = AppStoreFormFactor(
  storeFolderName: 'iphone_6_9in',
  logicalWidth: 440,
  logicalHeight: 956,
  physicalWidth: 1320,
);

/// iPad 13" — 2064×2752 px (1032×1376 logical @ 2×). Apple's required
/// minimum iPad screenshot size (e.g. 13" iPad Pro).
const appStoreIpad13In = AppStoreFormFactor(
  storeFolderName: 'ipad_13in',
  logicalWidth: 1032,
  logicalHeight: 1376,
  physicalWidth: 2064,
);

const appStoreFormFactors = [
  appStoreIphone69In,
  appStoreIpad13In,
];

/// Builds a golden file name for [formFactor] and [screenshotId].
String appStoreGoldenName(AppStoreFormFactor formFactor, String screenshotId) {
  return '${screenshotId}_${formFactor.storeFolderName}';
}

/// Pumps a widget at [formFactor] logical size, exported at App Store physical px.
///
/// Mirrors [pumpPlayStoreGoldenWidget]: [pumpWidgetBuilder] always sets
/// `devicePixelRatio` to 1.0, so a 1320×2868 logical surface makes 14pt body
/// text look tiny. This helper uses normal device logical width at higher
/// density instead.
Future<GoldenTestHarness> pumpAppStoreGoldenWidget(
  WidgetTester tester,
  Widget widget, {
  required AppStoreFormFactor formFactor,
  List<Override> overrides = const [],
  bool waitForSettle = true,
}) async {
  final logicalSize = Size(formFactor.logicalWidth, formFactor.logicalHeight);
  final devicePixelRatio = formFactor.devicePixelRatio;
  final harness = GoldenTestHarness.withOverrides(overrides);
  final container = harness.container;

  await tester.binding.setSurfaceSize(logicalSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  tester.view.physicalSize = Size(
    logicalSize.width * devicePixelRatio,
    logicalSize.height * devicePixelRatio,
  );
  tester.view.devicePixelRatio = devicePixelRatio;

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: horcrux3Dark,
        debugShowCheckedModeBanner: false,
        home: Material(child: widget),
      ),
    ),
  );

  if (waitForSettle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
  return harness;
}
