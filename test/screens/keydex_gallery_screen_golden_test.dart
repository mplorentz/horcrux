import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import '../helpers/golden_test_helpers.dart';
import 'package:horcrux/screens/horcrux_gallery_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HorcruxGallery Golden Test', () {
    testGoldens('gallery screen - horcrux3 theme', (tester) async {
      final harness = await pumpGoldenWidget(
        tester,
        const HorcruxGallery(),
        surfaceSize: const Size(375, 812), // iPhone X size
      );

      await screenMatchesGolden(tester, 'horcrux_gallery_screen');

      await harness.dispose();
    });
  });
}
