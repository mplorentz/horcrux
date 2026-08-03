import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/models/terms_of_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TermsOfService', () {
    test('loadBundled reads and concatenates the bundled ToS and Privacy Policy', () async {
      final tos = await TermsOfService.loadBundled();

      expect(tos.version, kCurrentTosVersion);
      expect(tos.text, contains('Terms of Service'));
      expect(tos.text, contains('Privacy Policy'));
    });
  });
}
