import 'package:flutter/material.dart';
import 'horcrux_app_bar_title.dart';

/// Toolbar height for screens using `HorcruxAppBar`. Sized to fit two lines
/// of the 40pt Archivo title used by `HorcruxAppBarTitle`. Kept in sync with
/// `horcrux3.appBarTheme.toolbarHeight` in `theme.dart`.
const double kHorcruxAppBarToolbarHeight = 132.0;

/// AppBar with the project's Option-B title behavior baked in: titles wrap
/// to two lines on small phones, and `centerTitle` defaults to `false` to
/// match the brutalist left-aligned header in DESIGN_GUIDE.md.
///
/// Use a `String` title; it is rendered through `HorcruxAppBarTitle`.
/// Standard `AppBar` props (`leading`, `actions`, `automaticallyImplyLeading`,
/// `backgroundColor`, `foregroundColor`, `bottom`) are forwarded as-is.
///
/// For the rare case where the title needs to be a custom widget (e.g. the
/// branded icon + wordmark on the home screen), use `AppBar` directly.
class HorcruxAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;
  final bool centerTitle;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final PreferredSizeWidget? bottom;

  const HorcruxAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.centerTitle = false,
    this.backgroundColor,
    this.foregroundColor,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: HorcruxAppBarTitle(title),
      leading: leading,
      actions: actions,
      automaticallyImplyLeading: automaticallyImplyLeading,
      centerTitle: centerTitle,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize {
    final bottomHeight = bottom?.preferredSize.height ?? 0;
    return Size.fromHeight(kHorcruxAppBarToolbarHeight + bottomHeight);
  }
}
