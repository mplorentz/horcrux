import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'horcrux_screen_title.dart';
import 'recovery_request_banner.dart';

/// Scaffold wrapper that automatically includes the recovery request banner
/// below the AppBar when there are pending recovery requests.
///
/// For bead horcrux_app-dyc Option E, also supports a [screenTitle] field:
/// when set, HorcruxScaffold renders a `HorcruxScreenTitle` at the top of
/// the body (so the page title can wrap freely) and the AppBar becomes a
/// slim nav strip carrying only the back button and any actions. If no
/// [appBar] is provided alongside [screenTitle], a default `AppBar()` is
/// used.
class HorcruxScaffold extends ConsumerWidget {
  final PreferredSizeWidget? appBar;
  final String? screenTitle;
  final Widget? body;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final FloatingActionButtonAnimator? floatingActionButtonAnimator;
  final List<Widget>? persistentFooterButtons;
  final Widget? drawer;
  final Widget? endDrawer;
  final Widget? bottomSheet;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;
  final bool primary;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final Color? drawerScrimColor;
  final double? drawerEdgeDragWidth;
  final bool drawerEnableOpenDragGesture;
  final bool endDrawerEnableOpenDragGesture;
  final String? restorationId;
  final bool showNotificationBanner;

  const HorcruxScaffold({
    super.key,
    this.appBar,
    this.screenTitle,
    this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.floatingActionButtonAnimator,
    this.persistentFooterButtons,
    this.drawer,
    this.endDrawer,
    this.bottomSheet,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.primary = true,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.drawerScrimColor,
    this.drawerEdgeDragWidth,
    this.drawerEnableOpenDragGesture = true,
    this.endDrawerEnableOpenDragGesture = true,
    this.restorationId,
    this.showNotificationBanner = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveAppBar = appBar ?? (screenTitle != null ? AppBar() : null);
    return Scaffold(
      appBar: effectiveAppBar,
      body: _buildBody(context, ref, effectiveAppBar),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      floatingActionButtonAnimator: floatingActionButtonAnimator,
      persistentFooterButtons: persistentFooterButtons,
      drawer: drawer,
      endDrawer: endDrawer,
      bottomSheet: bottomSheet,
      bottomNavigationBar: bottomNavigationBar,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      primary: primary,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      drawerScrimColor: drawerScrimColor,
      drawerEdgeDragWidth: drawerEdgeDragWidth,
      drawerEnableOpenDragGesture: drawerEnableOpenDragGesture,
      endDrawerEnableOpenDragGesture: endDrawerEnableOpenDragGesture,
      restorationId: restorationId,
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    PreferredSizeWidget? effectiveAppBar,
  ) {
    Widget content = body ?? const SizedBox.shrink();

    if (screenTitle != null) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HorcruxScreenTitle(screenTitle!),
          Expanded(child: content),
        ],
      );
    }

    if (showNotificationBanner && effectiveAppBar != null) {
      content = Column(
        children: [
          const RecoveryRequestBanner(),
          Expanded(child: content),
        ],
      );
    }

    return content;
  }
}
