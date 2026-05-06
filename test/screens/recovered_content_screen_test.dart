import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/screens/recovered_content_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  String? clipboardText;

  setUp(() {
    clipboardText = null;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      switch (call.method) {
        case 'Clipboard.setData':
          final args = call.arguments as Map<Object?, Object?>?;
          clipboardText = args?['text'] as String?;
          return null;
        case 'Clipboard.getData':
          return clipboardText != null ? <String, dynamic>{'text': clipboardText} : null;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('Copy toolbar icon copies content to clipboard', (tester) async {
    const secret = 'nsec1...';
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: RecoveredContentScreen(content: secret),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Copy'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(clipboardText, secret);
    expect(find.text('Copied to clipboard'), findsOneWidget);
  });

  testWidgets('back pops route', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: _PushRecoveredContentScreenButton(),
        ),
      ),
    );

    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('go'), findsOneWidget);
  });
}

class _PushRecoveredContentScreenButton extends StatelessWidget {
  const _PushRecoveredContentScreenButton();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TextButton(
        onPressed: () {
          Navigator.push<void>(
            context,
            MaterialPageRoute<void>(
              builder: (_) => const RecoveredContentScreen(content: 'x'),
            ),
          );
        },
        child: const Text('go'),
      ),
    );
  }
}
