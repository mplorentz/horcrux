import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/services/feedback_service.dart';

void main() {
  group('FeedbackService', () {
    test('can be instantiated with a form ID', () {
      final service = FeedbackService(formspreeFormId: 'testform');
      expect(service.formspreeFormId, 'testform');
    });

    test('submitFeedback returns false on network error', () async {
      // Use an invalid form ID that will fail DNS resolution
      final service = FeedbackService(formspreeFormId: 'nonexistent');
      // This will fail because we can't reach formspree.io in a test environment
      // but it tests the error handling path
      final result = await service.submitFeedback(
        message: 'Test',
        includeDiagnostics: false,
      );
      // In a test environment without network, this should return false
      expect(result, isFalse);
    });

    test('submitFeedback handles empty message gracefully', () async {
      final service = FeedbackService(formspreeFormId: 'testform');
      // Even with an empty message, the service should not throw
      // (Validation is handled by the UI layer)
      final result = await service.submitFeedback(
        message: '',
        includeDiagnostics: false,
      );
      // Will fail due to network, but should not throw
      expect(result, isFalse);
    });

    test('submitFeedback with diagnostics enabled does not crash', () async {
      final service = FeedbackService(formspreeFormId: 'testform');
      // This tests that _buildDiagnostics() doesn't crash in a test environment
      // where PackageInfo.fromPlatform() may not work
      final result = await service.submitFeedback(
        message: 'Test with diagnostics',
        email: 'test@example.com',
        includeDiagnostics: true,
      );
      // Will fail due to network, but should not throw
      expect(result, isFalse);
    });
  });
}
