import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/services/feedback_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('FeedbackService', () {
    test('can be instantiated with a form ID', () {
      final service = FeedbackService(formspreeFormId: 'testform');
      expect(service.formspreeFormId, 'testform');
    });

    test('submitFeedback returns true on successful POST', () async {
      final service = FeedbackService(
        formspreeFormId: 'testform',
        httpClient: MockClient((request) async {
          expect(request.url.toString(), 'https://formspree.io/f/testform');
          expect(request.headers['Accept'], 'application/json');
          expect(request.headers['Content-Type'], 'application/json');

          // Verify the body is valid JSON
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['message'], 'Great app!');
          expect(body['email'], 'user@test.com');

          return http.Response('{"ok":true}', 200);
        }),
      );

      final result = await service.submitFeedback(
        message: 'Great app!',
        email: 'user@test.com',
        includeDiagnostics: false,
      );

      expect(result, isTrue);
    });

    test('submitFeedback returns false on failed POST', () async {
      final service = FeedbackService(
        formspreeFormId: 'testform',
        httpClient: MockClient((request) async {
          return http.Response('{"error":"bad request"}', 400);
        }),
      );

      final result = await service.submitFeedback(
        message: 'Test',
        includeDiagnostics: false,
      );

      expect(result, isFalse);
    });

    test('submitFeedback returns false on network error', () async {
      final service = FeedbackService(
        formspreeFormId: 'testform',
        httpClient: MockClient((request) async {
          throw Exception('Network error');
        }),
      );

      final result = await service.submitFeedback(
        message: 'Test',
        includeDiagnostics: false,
      );

      expect(result, isFalse);
    });

    test('submitFeedback omits email when empty', () async {
      final service = FeedbackService(
        formspreeFormId: 'testform',
        httpClient: MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body.containsKey('email'), isFalse);
          expect(body['message'], 'Hello');
          return http.Response('{"ok":true}', 200);
        }),
      );

      await service.submitFeedback(
        message: 'Hello',
        email: '',
        includeDiagnostics: false,
      );
    });

    test('submitFeedback includes email when provided', () async {
      final service = FeedbackService(
        formspreeFormId: 'testform',
        httpClient: MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['email'], 'user@test.com');
          return http.Response('{"ok":true}', 200);
        }),
      );

      await service.submitFeedback(
        message: 'Hello',
        email: 'user@test.com',
        includeDiagnostics: false,
      );
    });

    test('submitFeedback includes diagnostics when enabled', () async {
      final service = FeedbackService(
        formspreeFormId: 'testform',
        httpClient: MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body.containsKey('_diagnostics'), isTrue);
          expect(body['_diagnostics'], isA<String>());
          expect(body['_diagnostics'], contains('Platform'));
          return http.Response('{"ok":true}', 200);
        }),
      );

      await service.submitFeedback(
        message: 'Hello',
        includeDiagnostics: true,
      );
    });

    test('submitFeedback omits diagnostics when disabled', () async {
      final service = FeedbackService(
        formspreeFormId: 'testform',
        httpClient: MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body.containsKey('_diagnostics'), isFalse);
          return http.Response('{"ok":true}', 200);
        }),
      );

      await service.submitFeedback(
        message: 'Hello',
        includeDiagnostics: false,
      );
    });

    test('submitFeedback body is valid JSON (not form-encoded)', () async {
      final service = FeedbackService(
        formspreeFormId: 'testform',
        httpClient: MockClient((request) async {
          // The body must be parseable JSON
          expect(() => jsonDecode(request.body), returnsNormally);
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['message'], 'Test JSON encoding');
          return http.Response('{"ok":true}', 200);
        }),
      );

      await service.submitFeedback(
        message: 'Test JSON encoding',
        includeDiagnostics: false,
      );
    });
  });
}
