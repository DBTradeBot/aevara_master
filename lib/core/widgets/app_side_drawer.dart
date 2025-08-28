import 'package:flutter/material.dart';

/// Optional left-side navigation drawer.
/// Contains a Settings entry that opens the endDrawer (settings banner).
class AppSideDrawer extends StatelessWidget {
  const AppSideDrawer({super.key});

  void _openSettingsFromDrawer(BuildContext context) {
    // Capture the scaffold BEFORE closing this drawer, then open the endDrawer.
    final scaffold = Scaffold.maybeOf(context);
    if (scaffold == null) return;

    // Close the left drawer first…
    Navigator.of(context).pop();

    // …then open the end drawer on the next frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scaffold.openEndDrawer();
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            ListTile(
              title: Text('Aevara', style: text.titleLarge),
              subtitle: const Text('Navigation'),
            ),
            const Divider(height: 1),

            // Add other nav links here if/when you want.

            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () => _openSettingsFromDrawer(context),
            ),
          ],
        ),
      ),
    );
  }
}
