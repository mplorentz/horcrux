import 'package:flutter/material.dart';
import 'package:ndk/shared/nips/nip01/helpers.dart';

/// A widget that displays a person's name (if available) or their npub.
///
/// This widget encapsulates the common pattern of:
/// - Showing a name in regular font if provided
/// - Falling back to npub in monospace font if no name is available
///
/// Used for displaying owners, stewards, and other users throughout the app.
class PersonDisplay extends StatelessWidget {
  /// The person's name (optional)
  final String? name;

  /// The person's public key in hex format (required)
  final String pubkey;

  /// Optional text style to apply. The font family will be overridden
  /// to monospace when displaying npub.
  final TextStyle? style;

  /// Maximum number of lines. Defaults to 1.
  final int? maxLines;

  /// How visual overflow should be handled. Defaults to ellipsis.
  final TextOverflow? overflow;

  const PersonDisplay({
    super.key,
    this.name,
    required this.pubkey,
    this.style,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
  });

  @override
  Widget build(BuildContext context) {
    final hasName = name != null && name!.isNotEmpty;
    final displayText = hasName ? name! : Helpers.encodeBech32(pubkey, 'npub');
    final textStyle = hasName
        ? style
        : style?.copyWith(fontFamily: 'RobotoMono') ?? const TextStyle(fontFamily: 'RobotoMono');

    return Text(
      displayText,
      style: textStyle,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
