import 'package:flutter/material.dart';

class SettingsPanel extends StatelessWidget {
  const SettingsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionHeader('Account'),
          const _Tile(
              Icons.person_outline, 'Profile', 'Update name, avatar, bio'),
          const _Tile(Icons.alternate_email, 'Username', 'Change your handle'),
          const _Tile(Icons.lock_outline, 'Password', 'Update password'),
          const _Tile(Icons.verified_user_outlined, 'Two-factor authentication',
              'Add extra security'),
          const _SectionHeader('Devices & Data'),
          const _Tile(Icons.devices_other_outlined, 'Connected devices',
              'Manage providers and permissions'),
          const _Tile(Icons.sync_outlined, 'Sync now', 'Trigger a manual sync'),
          const _Tile(Icons.download_outlined, 'Export data', 'CSV/JSON'),
          const _Tile(Icons.delete_outline, 'Delete data', 'Request deletion'),
          const _SectionHeader('Notifications'),
          const _Tile(Icons.notifications_active_outlined, 'Push notifications',
              'Challenges, badges, coach'),
          const _Tile(Icons.email_outlined, 'Email preferences',
              'Summaries and alerts'),
          const _SectionHeader('Privacy & Consent'),
          const _Tile(Icons.privacy_tip_outlined, 'Privacy policy',
              'How we handle data'),
          const _Tile(
              Icons.article_outlined, 'Terms of service', 'Legal information'),
          const _Tile(Icons.rule_folder_outlined, 'Consent history',
              'What you agreed to'),
          const _SectionHeader('About'),
          const _Tile(
              Icons.info_outline, 'About Aevara', 'App and model versions'),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            onTap: () => Navigator.pushNamedAndRemoveUntil(
                context, '/auth/signin', (_) => false),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _Tile(this.icon, this.title, this.subtitle);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {},
    );
  }
}
