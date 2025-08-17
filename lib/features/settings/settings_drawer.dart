import 'package:flutter/material.dart';

class SettingsDrawer extends StatelessWidget {
  const SettingsDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 340,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const _Header(),
            const Divider(),

            const _SectionLabel('Account'),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profile'),
              subtitle: const Text('Name, photo, username, units'),
              onTap: () => _go(context, '/settings/profile'),
            ),
            ListTile(
              leading: const Icon(Icons.lock_reset),
              title: const Text('Password'),
              onTap: () => _go(context, '/settings/password'),
            ),

            const _SectionLabel('Devices & Data'),
            ListTile(
              leading: const Icon(Icons.watch_outlined),
              title: const Text('Connected devices'),
              subtitle: const Text('Manage sync & permissions'),
              onTap: () => _go(context, '/settings/devices'),
            ),
            ListTile(
              leading: const Icon(Icons.sync_disabled_outlined),
              title: const Text('Revoke sync / Delete data'),
              onTap: () => _go(context, '/settings/data-control'),
            ),

            const _SectionLabel('Notifications'),
            ListTile(
              leading: const Icon(Icons.notifications_active_outlined),
              title: const Text('Push & email settings'),
              onTap: () => _go(context, '/settings/notifications'),
            ),

            const _SectionLabel('Privacy & Consent'),
            ListTile(
              leading: const Icon(Icons.fact_check_outlined),
              title: const Text('Consents'),
              onTap: () => _go(context, '/settings/consents'),
            ),

            const _SectionLabel('About'),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('App version & build'),
              onTap: () => _go(context, '/settings/about'),
            ),

            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FilledButton.tonalIcon(
                icon: const Icon(Icons.logout),
                label: const Text('Sign out'),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/auth/signin',
                        (r) => false,
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _go(BuildContext context, String route) {
    Navigator.pop(context);
    Navigator.pushNamed(context, route);
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.person)),
      title: const Text('Your Account'),
      subtitle: const Text('@username'),
      trailing: IconButton(
        tooltip: 'Close',
        icon: const Icon(Icons.close),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
    child: Text(text, style: Theme.of(context).textTheme.labelLarge),
  );
}
