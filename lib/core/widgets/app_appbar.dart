import 'package:flutter/material.dart';

/// Standard top app bar used across pages inside the AppShell.
/// Includes a gear icon to open the slide-in Settings banner (endDrawer).
class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppAppBar({super.key, this.title, this.actions});

  final Widget? title;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  void _openSettings(BuildContext context) {
    final scaffold = Scaffold.maybeOf(context);
    // Only open if there's an endDrawer (AppShell provides it).
    scaffold?.openEndDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final extraActions = <Widget>[
      IconButton(
        tooltip: 'Settings',
        icon: const Icon(Icons.settings_outlined),
        onPressed: () => _openSettings(context),
      ),
      const SizedBox(width: 4),
    ];

    return AppBar(
      title: title,
      actions: [...?actions, ...extraActions],
    );
  }
}
