import 'package:flutter/services.dart' show rootBundle;

/// The current bundled Terms of Service / Privacy Policy version.
///
/// Bump this whenever `assets/legal/terms_of_service.md` or
/// `assets/legal/privacy_policy.md` changes, as part of an app update.
/// [HorcruxApiService.needsConsentAcceptance] re-prompts the user when this
/// is greater than their last locally-accepted version. `POST /tos/accept`
/// records acceptance against this version for the server-side audit trail.
const int kCurrentTosVersion = 1;

/// The Terms of Service and Privacy Policy, bundled with the app so they're
/// available offline during onboarding.
class TermsOfService {
  /// Combined ToS + Privacy Policy text (Markdown), for display.
  final String text;

  /// The bundled version. See [kCurrentTosVersion].
  final int version;

  const TermsOfService({required this.text, required this.version});

  /// Loads the bundled Terms of Service and Privacy Policy from assets and
  /// concatenates them for display.
  static Future<TermsOfService> loadBundled() async {
    final tos = await rootBundle.loadString('assets/legal/terms_of_service.md');
    final privacyPolicy = await rootBundle.loadString('assets/legal/privacy_policy.md');
    return TermsOfService(
      text: '$tos\n\n---\n\n$privacyPolicy',
      version: kCurrentTosVersion,
    );
  }
}
