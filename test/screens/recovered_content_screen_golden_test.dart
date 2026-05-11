import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:horcrux/screens/recovered_content_screen.dart';

import '../helpers/golden_test_helpers.dart';

void main() {
  group('RecoveredContentScreen golden tests', () {
    testGoldens('default', (tester) async {
      final harness = await pumpGoldenWidget(
        tester,
        const RecoveredContentScreen(
          content: 'my secret vault content',
        ),
        surfaceSize: const Size(375, 800),
      );
      addTearDown(() async {
        await harness.dispose();
      });

      await screenMatchesGolden(tester, 'recovered_content_screen');
    });
  });
}
