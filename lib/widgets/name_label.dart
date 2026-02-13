import 'package:flutter/material.dart';
import 'package:ndk/shared/nips/nip01/helpers.dart';

/// A widget that displays a person's name (if available), their npub, or "Unknown".
///
/// This widget encapsulates the common pattern of:
/// - Showing a name in regular font if provided
/// - Falling back to npub in monospace font when pubkey is available but no name
/// - Falling back to "Unknown" when neither name nor pubkey is available
///
/// Used for displaying owners, stewards, and other users throughout the app.
///
/// For inline use with a prefix (e.g. "Owner: "), use [getDisplayContent] with
/// [Text.rich] to ensure consistent baseline alignment across different fonts.
class NameLabel extends StatelessWidget {
  /// The person's name (optional)
  final String? name;

  /// The person's public key in hex format (optional; when null, falls back to "Unknown" if no name)
  final String? pubkey;

  /// Optional text style to apply. The font family will be overridden
  /// to monospace when displaying npub.
  final TextStyle? style;

  /// Maximum number of lines. Defaults to 1.
  final int? maxLines;

  /// How visual overflow should be handled. Defaults to ellipsis.
  final TextOverflow? overflow;

  const NameLabel({
    super.key,
    this.name,
    this.pubkey,
    this.style,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
  });

  /// Returns the display text and style for use in [Text.rich].
  /// Use this when combining with a prefix (e.g. "Owner: ") to ensure
  /// consistent baseline alignment across different fonts (name vs npub).
  static (String text, TextStyle? style) getDisplayContent({
    required String? name,
    required String? pubkey,
    TextStyle? baseStyle,
  }) {
    if (name != null && name.isNotEmpty) {
      return (name, baseStyle);
    }
    if (pubkey != null && pubkey.isNotEmpty) {
      final npubStyle = baseStyle?.copyWith(fontFamily: 'RobotoMono') ??
          const TextStyle(fontFamily: 'RobotoMono');
      return (Helpers.encodeBech32(pubkey, 'npub'), npubStyle);
    }
    return ('Unknown', baseStyle);
  }

  @override
  Widget build(BuildContext context) {
    final (displayText, textStyle) = getDisplayContent(
      name: name,
      pubkey: pubkey,
      baseStyle: style,
    );
    return Text(
      displayText,
      style: textStyle,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
