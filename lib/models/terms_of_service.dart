import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/services.dart' show AssetBundle;

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
  ///
  /// [bundle] defaults to [rootBundle]. Pass a test bundle (e.g.
  /// [TestAssetBundle]) in widget tests to avoid real file I/O.
  static Future<TermsOfService> loadBundled({AssetBundle? bundle}) async {
    final b = bundle ?? rootBundle;
    final tos = await b.loadString('assets/legal/terms_of_service.md');
    final privacyPolicy = await b.loadString('assets/legal/privacy_policy.md');
    return TermsOfService(
      text: '$tos\n\n---\n\n$privacyPolicy',
      version: kCurrentTosVersion,
    );
  }
}
