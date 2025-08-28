import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../routing/route_paths.dart';
import '../../state/user_providers.dart';
import '../../state/theme_providers.dart';

class SettingsBanner extends ConsumerWidget {
  const SettingsBanner({super.key, required this.onReturnToShell});

  /// Called after a pushed settings page pops, so we reopen the banner.
  final VoidCallback onReturnToShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final profile = profileAsync.asData?.value;

    final uname = profile?.username;
    final displayUsername =
    (uname != null && uname.isNotEmpty) ? '@$uname' : 'Set username';

    final themeMode = ref.watch(themeModeProvider);

    void go(String route) {
      // Close drawer, push page, then reopen the drawer when returning.
      Navigator.of(context).pop();
      Navigator.of(context)
          .pushNamed(route)
          .then((_) => onReturnToShell());
    }

    final text = Theme.of(context).textTheme;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
        children: [
          Row(
            children: [
              const SizedBox(width: 8),
              Text('Settings', style: text.titleLarge),
              const Spacer(),
              IconButton(
                tooltip: 'Close',
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),

          const SizedBox(height: 8),
          _SectionHeader('Account'),
          _Tile(
            icon: Icons.alternate_email,
            title: 'Username',
            subtitle: displayUsername,
            onTap: () => go(RoutePaths.settingsUsername),
          ),
          _Tile(
            icon: Icons.badge_outlined,
            title: 'Update profile details',
            onTap: () => go(RoutePaths.updateProfile), // ✅ uses new route
          ),
          _Tile(
            icon: Icons.mail_outlined,
            title: 'Change email',
            onTap: () => go(RoutePaths.settingsEmail),
          ),
          _Tile(
            icon: Icons.lock_reset_outlined,
            title: 'Change password',
            onTap: () => go(RoutePaths.settingsPassword),
          ),

          const SizedBox(height: 8),
          _SectionHeader('Preferences'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: ThemeMode.system, label: Text('System')),
                ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
              ],
              selected: {themeMode},
              onSelectionChanged: (s) =>
                  ref.read(themeModeProvider.notifier).setThemeMode(s.first),
            ),
          ),

          const SizedBox(height: 8),
          _SectionHeader('Devices & Notifications'),
          _Tile(
            icon: Icons.watch_outlined,
            title: 'Connected devices',
            onTap: () => go(RoutePaths.settingsDevices),
          ),
          _Tile(
            icon: Icons.notifications_none_outlined,
            title: 'Notifications',
            onTap: () => go(RoutePaths.settingsNotifs),
          ),

          const SizedBox(height: 8),
          _SectionHeader('Data & Privacy'),
          _Tile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy dashboard',
            onTap: () => go(RoutePaths.profilePrivacy),
          ),
          _Tile(
            icon: Icons.file_download_outlined,
            title: 'Export my data',
            onTap: () => go(RoutePaths.profileExport),
          ),
          _Tile(
            icon: Icons.delete_forever_outlined,
            title: 'Delete account',
            onTap: () => go(RoutePaths.profileDelete),
          ),

          const SizedBox(height: 8),
          _SectionHeader('About & Legal'),
          _Tile(
            icon: Icons.info_outline,
            title: 'About Aevara',
            onTap: () => go(RoutePaths.about),
          ),
          _Tile(
            icon: Icons.policy_outlined,
            title: 'Privacy policy',
            onTap: () => go(RoutePaths.aboutPrivacy),
          ),
          _Tile(
            icon: Icons.gavel_outlined,
            title: 'Terms of Service',
            onTap: () => go(RoutePaths.aboutTerms),
          ),
          _Tile(
            icon: Icons.description_outlined,
            title: 'Methods & transparency',
            onTap: () => go(RoutePaths.methodsDoc),
          ),

          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: FilledButton.tonalIcon(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).maybePop();
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
            ),
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
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  const _Tile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: (subtitle != null && subtitle!.isNotEmpty)
          ? Text(subtitle!)
          : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
