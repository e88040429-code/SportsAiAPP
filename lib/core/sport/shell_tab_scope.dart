import 'package:flutter/material.dart';

/// Bottom-nav branch index for Live Coach (see AppShell destinations).
const int kCoachShellBranchIndex = 2;

/// Exposes the active bottom-nav branch index to shell screens.
///
/// Used so heavy tabs (e.g. Live Coach camera) only start when visible.
class ShellTabScope extends InheritedWidget {
  const ShellTabScope({
    super.key,
    required this.currentIndex,
    required super.child,
  });

  final int currentIndex;

  static ShellTabScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ShellTabScope>();
  }

  static int? indexOf(BuildContext context) => maybeOf(context)?.currentIndex;

  @override
  bool updateShouldNotify(ShellTabScope oldWidget) {
    return currentIndex != oldWidget.currentIndex;
  }
}
