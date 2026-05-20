import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io' show Platform;

import 'logger.dart';

/// Service that sends user feedback to a Formspree form.
///
/// Formspree converts the POST into an email to the maintainer.
/// The form endpoint is swappable via [formspreeFormId].
class FeedbackService {
  final String formspreeFormId;
  final http.Client _httpClient;

  FeedbackService({
    required this.formspreeFormId,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  /// Submit feedback to Formspree.
  ///
  /// [email] — optional user email for reply.
  /// [message] — required feedback text.
  /// [includeDiagnostics] — if true, appends app version, OS info, and recent
  /// log entries to the submission.
  ///
  /// Returns `true` on success, `false` on failure.
  Future<bool> submitFeedback({
    required String message,
    String email = '',
    bool includeDiagnostics = true,
  }) async {
    try {
      final uri = Uri.parse('https://formspree.io/f/$formspreeFormId');

      final body = <String, dynamic>{
        'message': message,
      };

      if (email.isNotEmpty) {
        body['email'] = email;
      }

      if (includeDiagnostics) {
        body['_diagnostics'] = await _buildDiagnostics();
      }

      final response = await _httpClient
          .post(
            uri,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        Log.info('Feedback submitted successfully');
        return true;
      } else {
        Log.error('Feedback submission failed: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      Log.error('Feedback submission error', e);
      return false;
    }
  }

  /// Build a diagnostics string with app version, OS info, relay status, and
  /// recent log entries.
  Future<String> _buildDiagnostics() async {
    final buffer = StringBuffer();

    // App version
    try {
      final info = await PackageInfo.fromPlatform();
      buffer.writeln('App: ${info.appName} ${info.version}+${info.buildNumber}');
      buffer.writeln('Package: ${info.packageName}');
    } catch (e) {
      buffer.writeln('App: unknown (${e.runtimeType})');
    }

    // OS info
    buffer.writeln('Platform: ${Platform.operatingSystem}');
    buffer.writeln('OS version: ${Platform.operatingSystemVersion}');

    // Recent log entries
    final logs = Log.recentLogs();
    buffer.writeln('--- recent logs (${logs.length}) ---');
    for (final line in logs) {
      buffer.writeln(line);
    }

    return buffer.toString();
  }
}
