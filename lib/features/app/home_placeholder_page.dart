import 'package:flutter/material.dart';

class HomePlaceholderPage extends StatelessWidget {
  const HomePlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard (Placeholder)'),
        actions: [
          IconButton(onPressed: ()=> Navigator.pushNamed(context, '/dev'), icon: const Icon(Icons.bug_report_outlined)),
          IconButton(onPressed: ()=> Scaffold.of(context).openEndDrawer(), icon: const Icon(Icons.settings_outlined)),
        ],
      ),
      endDrawer: const _SimpleSettingsDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Replace this with your real Dashboard.'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              children: [
                FilledButton(onPressed: ()=> Navigator.pushNamed(context, '/app/data-hub'), child: const Text('Go to Data Hub')),
                FilledButton(onPressed: ()=> Navigator.pushNamed(context, '/experiments'), child: const Text('Go to Experiments')),
                FilledButton(onPressed: ()=> Navigator.pushNamed(context, '/community'), child: const Text('Go to Community')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SimpleSettingsDrawer extends StatelessWidget {
  const _SimpleSettingsDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: const EdgeInsets.only(top: 24),
        children: [
          const ListTile(title: Text('Quick Settings')),
          ListTile(leading: const Icon(Icons.person_outline), title: const Text('My Profile'), onTap: ()=> Navigator.pushNamed(context, '/profile/me')),
          ListTile(leading: const Icon(Icons.settings_outlined), title: const Text('Open full settings'), onTap: ()=> Navigator.pushNamed(context, '/settings')),
          ListTile(leading: const Icon(Icons.logout), title: const Text('Sign out'), onTap: ()=> Navigator.pushNamedAndRemoveUntil(context, '/auth/signin', (_) => false)),
        ],
      ),
    );
  }
}
