import 'package:flutter/material.dart';

/// Body-level page title used with the slim AppBar pattern.
///
/// Option E for bead horcrux_app-dyc: the AppBar becomes a slim nav strip
/// (back button + actions) and the large page title moves into the body as
/// the first item, where it can wrap freely without eating toolbar chrome.
///
/// Renders the title at displaySmall scale (28pt Archivo w700 from the
/// theme) on as many lines as it needs, with horizontal padding that
/// matches the screen content padding. Place it as the first child of your
/// scrollable body, above any other content.
class HorcruxScreenTitle extends StatelessWidget {
  final String text;

  const HorcruxScreenTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.displaySmall;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Text(text, style: style),
    );
  }
}
