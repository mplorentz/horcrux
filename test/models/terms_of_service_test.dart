import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/models/terms_of_service.dart';

void main() {
  group('TermsOfService', () {
    test('fromJson parses valid response', () {
      final json = {
        'text': 'Terms of Service text not available yet.',
        'version': 1,
      };

      final tos = TermsOfService.fromJson(json);

      expect(tos.text, 'Terms of Service text not available yet.');
      expect(tos.version, 1);
    });

    test('fromJson handles missing fields gracefully', () {
      final json = <String, dynamic>{};

      final tos = TermsOfService.fromJson(json);

      expect(tos.text, '');
      expect(tos.version, 0);
    });

    test('fromJson handles null fields gracefully', () {
      final json = {
        'text': null,
        'version': null,
      };

      final tos = TermsOfService.fromJson(json);

      expect(tos.text, '');
      expect(tos.version, 0);
    });

    test('toJson produces correct output', () {
      const tos = TermsOfService(text: 'Some text', version: 2);

      final json = tos.toJson();

      expect(json['text'], 'Some text');
      expect(json['version'], 2);
    });
  });
}
