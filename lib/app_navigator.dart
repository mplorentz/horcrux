import 'package:flutter/material.dart';

/// Root [NavigatorState] for the app — shared so services can push routes without a [BuildContext].
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
