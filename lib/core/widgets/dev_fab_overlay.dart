// lib/core/widgets/dev_fab_overlay.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dev_fab_navigator.dart';

/// Overlays the DevFabNavigator on every screen in non-release builds.
class DevFabOverlay extends StatelessWidget {
  final Widget child;
  const DevFabOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (kReleaseMode) return child; // hide in release
    return Stack(
      children: [
        child,
        const Positioned(
          right: 16,
          bottom: 24,
          child: DevFabNavigator(),
        ),
      ],
    );
  }
}
