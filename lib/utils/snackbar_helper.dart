import 'package:flutter/material.dart';

/// Extension to show SnackBars at the top of the screen
extension TopSnackBar on BuildContext {
  /// Shows a SnackBar at the top of the screen
  void showTopSnackBar(SnackBar snackBar) {
    final messenger = ScaffoldMessenger.of(this);

    // Clone the SnackBar with margin positioned at the top
    final topSnackBar = SnackBar(
      content: snackBar.content,
      backgroundColor: snackBar.backgroundColor,
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(this).size.height - 75, // Position at top
        left: 16,
        right: 16,
        top: 16,
      ),
      duration: snackBar.duration,
      action: snackBar.action,
      actionOverflowThreshold: snackBar.actionOverflowThreshold,
      animation: snackBar.animation,
      closeIconColor: snackBar.closeIconColor,
      dismissDirection: snackBar.dismissDirection,
      elevation: snackBar.elevation,
      onVisible: snackBar.onVisible,
      padding: snackBar.padding,
      shape: snackBar.shape,
      showCloseIcon: snackBar.showCloseIcon,
      width: snackBar.width,
    );

    messenger.showSnackBar(topSnackBar);
  }
}

/// Custom ScaffoldMessenger that positions SnackBars at the top of the screen
/// This intercepts SnackBar calls and wraps them with margin to position at top
class TopSnackBarScaffoldMessenger extends StatefulWidget {
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;
  final Widget child;

  const TopSnackBarScaffoldMessenger({
    super.key,
    required this.scaffoldMessengerKey,
    required this.child,
  });

  @override
  State<TopSnackBarScaffoldMessenger> createState() => _TopSnackBarScaffoldMessengerState();
}

class _TopSnackBarScaffoldMessengerState extends State<TopSnackBarScaffoldMessenger> {
  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: widget.scaffoldMessengerKey,
      child: Builder(
        builder: (context) {
          // Wrap child with a custom ScaffoldMessenger that intercepts SnackBar calls
          return _TopSnackBarMessengerWrapper(
            scaffoldMessengerKey: widget.scaffoldMessengerKey,
            child: widget.child,
          );
        },
      ),
    );
  }
}

class _TopSnackBarMessengerWrapper extends StatelessWidget {
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;
  final Widget child;

  const _TopSnackBarMessengerWrapper({
    required this.scaffoldMessengerKey,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(key: scaffoldMessengerKey, child: child);
  }
}
