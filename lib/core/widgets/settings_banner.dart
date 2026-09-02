// lib/core/widgets/settings_banner.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../routing/route_paths.dart';
import '../../state/user_providers.dart';
import '../../state/theme_providers.dart';
import '../../state/notifications_providers.dart';

class SettingsBanner extends ConsumerStatefulWidget {
  const SettingsBanner({super.key, required this.onReturnToShell});

  /// Called after a pushed settings page pops, so we reopen the banner.
  final VoidCallback onReturnToShell;

  @override
  ConsumerState<SettingsBanner> createState() => _SettingsBannerState();
}

class _SettingsBannerState extends ConsumerState<SettingsBanner> {
  bool _profileExpanded = false;
  bool _prefsExpanded = false;

  String _displayName({required dynamic profile, required User? authUser}) {
    final n1 = (profile?.firstName ?? '').toString().trim();
    final n2 = (profile?.lastName ?? '').toString().trim();
    final d = [n1, n2].where((s) => s.isNotEmpty).join(' ');
    if (d.isNotEmpty) return d;
    return authUser?.email ?? 'Account';
  }

  String _displayHandle(dynamic profile) {
    final u = (profile?.username ?? '').toString().trim();
    return u.isEmpty ? 'Username not set' : '@$u';
  }

  /// Safe avatar resolver for map or typed profile objects; fallback to FirebaseAuth
  String? _photoUrl(dynamic profile, User? authUser) {
    if (profile is Map<String, dynamic>) {
      final candidates = <String?>[
        profile['photo_url'] as String?,
        profile['photoUrl'] as String?,
        profile['photoURL'] as String?,
        profile['avatarUrl'] as String?,
      ];
      for (final c in candidates) {
        if (c != null && c.isNotEmpty) return c;
      }
    } else if (profile != null) {
      try {
        final v = (profile as dynamic).photoUrl as String?;
        if (v != null && v.isNotEmpty) return v;
      } catch (_) {}
      try {
        final v = (profile as dynamic).photoURL as String?;
        if (v != null && v.isNotEmpty) return v;
      } catch (_) {}
      try {
        final v = (profile as dynamic).avatarUrl as String?;
        if (v != null && v.isNotEmpty) return v;
      } catch (_) {}
    }
    return authUser?.photoURL;
  }

  void _goNamed(BuildContext context, String route) {
    Navigator.of(context).pop(); // close drawer/sheet first
    Navigator.of(context).pushNamed(route).then((_) => widget.onReturnToShell());
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final profile = profileAsync.asData?.value;

    final themeMode = ref.watch(themeModeProvider);
    final unread = ref.watch(unreadCountProvider).asData?.value ?? 0;

    final authUser = FirebaseAuth.instance.currentUser;
    final text = Theme.of(context).textTheme;

    final name = _displayName(profile: profile, authUser: authUser);
    final handle = _displayHandle(profile);
    final avatar = _photoUrl(profile, authUser);

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          // CONTENT
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                // Top bar
                Row(
                  children: [
                    Text('Settings', style: text.headlineSmall),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Close',
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ---------- PROFILE (EXPANDABLE) ----------
                _ExpandableProfileCard(
                  name: name,
                  handle: handle,
                  photoUrl: avatar,
                  expanded: _profileExpanded,
                  onToggle: () => setState(() => _profileExpanded = !_profileExpanded),
                  onProfileSettings: () => _goNamed(context, RoutePaths.updateProfile),
                  onChangeEmail: () => _goNamed(context, RoutePaths.settingsEmail),
                  onChangePassword: () => _goNamed(context, RoutePaths.settingsPassword),
                ),

                const SizedBox(height: 16),

                // ---------- APPEARANCE + NOTIFICATIONS (EXPANDABLE) ----------
                _ExpandablePrefsCard(
                  expanded: _prefsExpanded,
                  unread: unread,
                  themeMode: themeMode,
                  onToggle: () => setState(() => _prefsExpanded = !_prefsExpanded),
                  onThemeChanged: (m) =>
                      ref.read(themeModeProvider.notifier).setThemeMode(m),
                  onOpenNotifications: () => _goNamed(context, RoutePaths.settingsNotifs),
                ),

                const SizedBox(height: 16),

                // ---------- APPS & CONNECTIONS ----------
                _SectionCard(
                  title: 'Apps & Connections',
                  children: [
                    _Tile(
                      icon: Icons.hub_outlined,
                      title: 'Connected apps',
                      subtitle: 'Manage device connections',
                      // ⬇️ Route fixed here:
                      onTap: () => _goNamed(context, RoutePaths.settingsDevices),
                    ),
                    const _SectionFooter(
                      text: 'Change which apps can read or write your data.',
                    ),
                  ],
                ),

                // ---------- PRIVACY & DATA ----------
                _SectionCard(
                  title: 'Privacy & Data',
                  children: [
                    _Tile(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Data controls', // renamed from Privacy dashboard
                      onTap: () => _goNamed(context, RoutePaths.profilePrivacy),
                    ),
                    _Tile(
                      icon: Icons.file_download_outlined,
                      title: 'Export my data',
                      onTap: () => _goNamed(context, RoutePaths.profileExport),
                    ),
                    _Tile(
                      icon: Icons.description_outlined,
                      title: 'Methods & transparency',
                      onTap: () => _goNamed(context, RoutePaths.methodsDoc),
                    ),
                    _Tile(
                      icon: Icons.delete_forever_outlined,
                      title: 'Delete Account', // moved underneath Methods & transparency
                      onTap: () => _goNamed(context, RoutePaths.profileDelete),
                    ),
                  ],
                ),

                // ---------- ABOUT & LEGAL ----------
                _SectionCard(
                  title: 'About & Legal',
                  children: [
                    _Tile(
                      icon: Icons.info_outline,
                      title: 'About Aevara',
                      onTap: () => _goNamed(context, RoutePaths.about),
                    ),
                    _Tile(
                      icon: Icons.policy_outlined,
                      title: 'Privacy policy',
                      onTap: () => _goNamed(context, RoutePaths.aboutPrivacy),
                    ),
                    _Tile(
                      icon: Icons.gavel_outlined,
                      title: 'Terms of Service',
                      onTap: () => _goNamed(context, RoutePaths.aboutTerms),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ---------- STANDALONE SIGN OUT (BOTTOM) ----------
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (mounted) Navigator.of(context).maybePop();
                },
                icon: const Icon(Icons.logout),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Sign out'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ======================= Helpers & Widgets ======================= */

class _ExpandableProfileCard extends StatelessWidget {
  const _ExpandableProfileCard({
    required this.name,
    required this.handle,
    required this.photoUrl,
    required this.expanded,
    required this.onToggle,
    required this.onProfileSettings,
    required this.onChangeEmail,
    required this.onChangePassword,
  });

  final String name;
  final String handle;
  final String? photoUrl;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onProfileSettings;
  final VoidCallback onChangeEmail;
  final VoidCallback onChangePassword;

  String _initials(String s) {
    final parts = s.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'A';
    if (parts.length == 1) return parts.first.characters.take(1).toString().toUpperCase();
    return (parts.first.characters.take(1).toString() +
        parts.last.characters.take(1).toString())
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tx = Theme.of(context).textTheme;

    final avatarProvider =
    (photoUrl != null && photoUrl!.isNotEmpty) ? NetworkImage(photoUrl!) : null;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Header row
                Row(
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: cs.primary.withOpacity(0.12),
                      backgroundImage: avatarProvider,
                      child: avatarProvider == null
                          ? Text(
                        _initials(name),
                        style: tx.titleMedium?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    // Name + handle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: tx.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            handle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                            style: tx.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0.0, // chevron down when expanded
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Icons.keyboard_arrow_down),
                    ),
                  ],
                ),

                // Expandable content
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Column(
                    children: [
                      const SizedBox(height: 8),
                      const Divider(height: 1),
                      _ActionRow(
                        icon: Icons.person_outline,
                        label: 'Profile settings',
                        onTap: onProfileSettings,
                      ),
                      _ActionRow(
                        icon: Icons.mail_outlined,
                        label: 'Change email',
                        onTap: onChangeEmail,
                      ),
                      _ActionRow(
                        icon: Icons.lock_reset_outlined,
                        label: 'Change password',
                        onTap: onChangePassword,
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                  crossFadeState:
                  expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 220),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpandablePrefsCard extends StatelessWidget {
  const _ExpandablePrefsCard({
    required this.expanded,
    required this.onToggle,
    required this.unread,
    required this.themeMode,
    required this.onThemeChanged,
    required this.onOpenNotifications,
  });

  final bool expanded;
  final VoidCallback onToggle;
  final int unread;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;
  final VoidCallback onOpenNotifications;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tx = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Header
                Row(
                  children: [
                    Icon(Icons.tune, color: cs.onSurfaceVariant),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Appearance & Notifications', style: tx.titleMedium),
                    ),
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Icons.keyboard_arrow_down),
                    ),
                  ],
                ),

                // Expanded content
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                        child: SegmentedButton<ThemeMode>(
                          showSelectedIcon: false,
                          segments: const [
                            ButtonSegment(value: ThemeMode.system, label: Text('System')),
                            ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                            ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                          ],
                          selected: {themeMode},
                          onSelectionChanged: (s) => onThemeChanged(s.first),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.notifications_none_outlined),
                        title: const Text('App notifications'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (unread > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFBF4A4A),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '$unread',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                        onTap: onOpenNotifications,
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                  crossFadeState:
                  expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 220),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cs.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(title, style: text.titleSmall),
          ),
          const Divider(height: 1),
          // Rows
          ...children,
        ],
      ),
    );
  }
}

class _SectionFooter extends StatelessWidget {
  final String text;
  const _SectionFooter({required this.text});
  @override
  Widget build(BuildContext context) {
    final tx = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Text(
        text,
        style: tx.bodySmall?.copyWith(color: cs.onSurfaceVariant),
      ),
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
    final tx = Theme.of(context).textTheme;
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: (subtitle != null && subtitle!.isNotEmpty)
          ? Text(
        subtitle!,
        style: tx.bodySmall,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        softWrap: false,
      )
          : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _NotifTile extends StatelessWidget {
  const _NotifTile({
    required this.title,
    required this.unread,
    required this.onTap,
  });

  final String title;
  final int unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final chip = (unread > 0)
        ? Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFBF4A4A), // muted red
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$unread',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    )
        : null;

    return ListTile(
      leading: const Icon(Icons.notifications_none_outlined),
      title: Text(
        title,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        softWrap: false,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (chip != null) chip,
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: onTap,
    );
  }
}
