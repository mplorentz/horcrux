import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/widgets/recovery_rules_widget.dart';

void main() {
  group('RecoveryRulesWidget', () {
    testWidgets('shows "Keys Needed to Unlock: N" with threshold value', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RecoveryRulesWidget(
            threshold: 2,
            stewardCount: 3,
            onThresholdChanged: (_) {},
            alertStewardsWithPush: false,
            onAlertStewardsWithPushChanged: (_) {},
          ),
        ),
      ));

      expect(find.text('Keys Needed to Unlock: 2'), findsOneWidget);
    });

    testWidgets('shows slider with correct min/max when stewardCount >= 2', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RecoveryRulesWidget(
            threshold: 2,
            stewardCount: 3,
            onThresholdChanged: (_) {},
            alertStewardsWithPush: false,
            onAlertStewardsWithPushChanged: (_) {},
          ),
        ),
      ));

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.min, equals(2.0)); // _minThreshold = 2 when stewardCount >= 2
      expect(slider.max, equals(3.0)); // stewardCount
      expect(slider.value, equals(2.0));
    });

    testWidgets('slider min is 1 when stewardCount is 1', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RecoveryRulesWidget(
            threshold: 1,
            stewardCount: 1,
            onThresholdChanged: (_) {},
            alertStewardsWithPush: false,
            onAlertStewardsWithPushChanged: (_) {},
          ),
        ),
      ));

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.min, equals(1.0)); // _minThreshold = 1 when stewardCount == 1
      expect(slider.max, equals(1.0));
      expect(slider.value, equals(1.0));
    });

    testWidgets('slider min is 1 when stewardCount is 0', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RecoveryRulesWidget(
            threshold: 1,
            stewardCount: 0,
            onThresholdChanged: (_) {},
            alertStewardsWithPush: false,
            onAlertStewardsWithPushChanged: (_) {},
          ),
        ),
      ));

      // With 0 stewards, the "You must add stewards" text is shown instead of slider
      expect(find.text('You must add stewards before adjusting the recovery threshold.'),
          findsOneWidget);
      expect(find.byType(Slider), findsNothing);
    });

    testWidgets('shows "You must add stewards" message when stewardCount is 0', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RecoveryRulesWidget(
            threshold: 1,
            stewardCount: 0,
            onThresholdChanged: (_) {},
            alertStewardsWithPush: false,
            onAlertStewardsWithPushChanged: (_) {},
          ),
        ),
      ));

      expect(
        find.text('You must add stewards before adjusting the recovery threshold.'),
        findsOneWidget,
      );
    });

    testWidgets('slider divisions are null when min == max (no range)', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RecoveryRulesWidget(
            threshold: 2,
            stewardCount: 2,
            onThresholdChanged: (_) {},
            alertStewardsWithPush: false,
            onAlertStewardsWithPushChanged: (_) {},
          ),
        ),
      ));

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.min, equals(2.0));
      expect(slider.max, equals(2.0));
      expect(slider.divisions, isNull); // No divisions when min == max
    });

    testWidgets('slider has divisions when range exists', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RecoveryRulesWidget(
            threshold: 2,
            stewardCount: 5,
            onThresholdChanged: (_) {},
            alertStewardsWithPush: false,
            onAlertStewardsWithPushChanged: (_) {},
          ),
        ),
      ));

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.min, equals(2.0));
      expect(slider.max, equals(5.0));
      expect(slider.divisions, equals(3)); // 5 - 2 = 3 divisions
    });

    testWidgets('calls onThresholdChanged when slider value changes', (tester) async {
      int? capturedThreshold;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RecoveryRulesWidget(
            threshold: 2,
            stewardCount: 5,
            onThresholdChanged: (v) => capturedThreshold = v,
            alertStewardsWithPush: false,
            onAlertStewardsWithPushChanged: (_) {},
          ),
        ),
      ));

      // Find the slider and change its value
      final slider = tester.widget<Slider>(find.byType(Slider));
      slider.onChanged!(3.0);
      expect(capturedThreshold, equals(3));
    });

    testWidgets('shows push notification switch', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RecoveryRulesWidget(
            threshold: 2,
            stewardCount: 3,
            onThresholdChanged: (_) {},
            alertStewardsWithPush: true,
            onAlertStewardsWithPushChanged: (_) {},
          ),
        ),
      ));

      expect(find.text('Enable push notifications'), findsOneWidget);
      expect(find.byKey(const ValueKey('alert_stewards_push_switch')), findsOneWidget);
    });

    testWidgets('calls onAlertStewardsWithPushChanged when switch toggled', (tester) async {
      bool? capturedValue;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RecoveryRulesWidget(
            threshold: 2,
            stewardCount: 3,
            onThresholdChanged: (_) {},
            alertStewardsWithPush: false,
            onAlertStewardsWithPushChanged: (v) => capturedValue = v,
          ),
        ),
      ));

      final switchWidget = tester.widget<Switch>(
        find.byKey(const ValueKey('alert_stewards_push_switch')),
      );
      switchWidget.onChanged!(true);
      expect(capturedValue, isTrue);
    });

    testWidgets('shows summary text with correct steward count and threshold', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RecoveryRulesWidget(
            threshold: 2,
            stewardCount: 3,
            onThresholdChanged: (_) {},
            alertStewardsWithPush: false,
            onAlertStewardsWithPushChanged: (_) {},
          ),
        ),
      ));

      expect(
        find.text(
          'With your current plan 3 keys will be generated and 2 stewards will need to agree to unlock the vault.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('summary text uses singular for 1 steward and 1 threshold', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RecoveryRulesWidget(
            threshold: 1,
            stewardCount: 1,
            onThresholdChanged: (_) {},
            alertStewardsWithPush: false,
            onAlertStewardsWithPushChanged: (_) {},
          ),
        ),
      ));

      expect(
        find.text(
          'With your current plan 1 key will be generated and 1 steward will need to agree to unlock the vault.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('_minThreshold is 2 with 2+ stewards, 1 with 1 steward', (tester) async {
      // Test with 2 stewards — min should be 2
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RecoveryRulesWidget(
            threshold: 2,
            stewardCount: 2,
            onThresholdChanged: (_) {},
            alertStewardsWithPush: false,
            onAlertStewardsWithPushChanged: (_) {},
          ),
        ),
      ));

      Slider slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.min, equals(2.0));

      // Test with 1 steward — min should be 1
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RecoveryRulesWidget(
            threshold: 1,
            stewardCount: 1,
            onThresholdChanged: (_) {},
            alertStewardsWithPush: false,
            onAlertStewardsWithPushChanged: (_) {},
          ),
        ),
      ));

      slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.min, equals(1.0));
    });
  });
}