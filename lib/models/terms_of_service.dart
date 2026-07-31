/// Response from `GET /tos` on the horcrux-api.
///
/// Contains the current Terms of Service text and its version number.
/// The version is used to detect when the ToS has been updated (re-prompt)
/// and to stamp the `POST /tos/accept` request.
class TermsOfService {
  /// The ToS / Privacy Policy text body (Markdown).
  final String text;

  /// Monotonically increasing version number. Bumped when the operator
  /// updates the terms; clients must re-accept when the served version is
  /// greater than the last locally-accepted version.
  final int version;

  const TermsOfService({required this.text, required this.version});

  factory TermsOfService.fromJson(Map<String, dynamic> json) {
    return TermsOfService(
      text: json['text'] as String? ?? '',
      version: json['version'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'text': text,
        'version': version,
      };
}
