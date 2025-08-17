import 'package:flutter/material.dart';

// Data tab: simple hub that links to your data subpages
import '../data/daily_snapshot_page.dart';
import '../data/metric_details_page.dart';

// Experiments tab (you already have these)
import '../experiments/experiments_home_page.dart';

// NEW Community hub on the Community tab
import '../community/community_home_page.dart';

// Settings detail pages (routes already exist in main.dart)
class DashboardPlaceholder extends StatefulWidget {
  const DashboardPlaceholder({super.key, this.initialIndex = 0});
  final int initialIndex;

  @override
  State<DashboardPlaceholder> createState() => _DashboardPlaceholderState();
}

class _DashboardPlaceholderState extends State<DashboardPlaceholder> {
  late int _index = widget.initialIndex;

  final _navItems = const <BottomNavigationBarItem>[
    BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), label: 'Data'),
    BottomNavigationBarItem(icon: Icon(Icons.science_outlined), label: 'Experiments'),
    BottomNavigationBarItem(icon: Icon(Icons.groups_outlined), label: 'Community'),
  ];

  void _openSettings() => Scaffold.of(context).openEndDrawer();

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const _DataHubCards(),                // Data tab container
      const ExperimentsHomePage(),          // Experiments
      const CommunityHomePage(),            // ✅ New Community Hub here
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard (Placeholder)'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: _openSettings,
          ),
        ],
      ),

      endDrawer: const _SettingsDrawer(),

      body: SafeArea(
        child: IndexedStack(index: _index, children: pages),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: _navItems,
      ),

      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 48.0), // keep above nav
        child: FloatingActionButton.extended(
          heroTag: 'devfab',
          icon: const Icon(Icons.bug_report_outlined),
          label: const Text('Dev'),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              showDragHandle: true,
              builder: (ctx) => SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const ListTile(
                        leading: Icon(Icons.info_outline),
                        title: Text('This is a placeholder shell'),
                        subtitle: Text('Swap this with your real dashboard when ready.'),
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        leading: const Icon(Icons.logout),
                        title: const Text('Go to Sign In'),
                        onTap: () => Navigator.pushReplacementNamed(context, '/auth/signin'),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }
}

/// ----------------------------
/// Data Tab (cards → details)
/// ----------------------------
class _DataHubCards extends StatelessWidget {
  const _DataHubCards();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            leading: const Icon(Icons.today_outlined),
            title: const Text('Daily Snapshot'),
            subtitle: const Text('Vitals, readiness, sleep, activity'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DailySnapshotPage()),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            leading: const Icon(Icons.analytics_outlined),
            title: const Text('Metric Details'),
            subtitle: const Text('Trends, drivers, sources'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MetricDetailsPage()),
            ),
          ),
        ),
      ],
    );
  }
}

/// ----------------------------
/// Settings Drawer (global)
/// ----------------------------
class _SettingsDrawer extends StatelessWidget {
  const _SettingsDrawer();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: cs.primaryContainer,
                  child: const Text('😎', style: TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Your Account', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text('@username', style: TextStyle(color: Colors.black54)),
                  ],
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),

            _sec('Account'),
            _tile(context, Icons.person_outline, 'Profile', '/settings/profile'),
            _tile(context, Icons.lock_outline, 'Password', '/settings/password'),

            const SizedBox(height: 8),
            _sec('Devices & Data'),
            _tile(context, Icons.watch_outlined, 'Connected devices', '/settings/devices'),
            _tile(context, Icons.delete_sweep_outlined, 'Revoke sync / Delete data', '/settings/data-control'),

            const SizedBox(height: 8),
            _sec('Notifications'),
            _tile(context, Icons.notifications_none, 'Push & email settings', '/settings/notifications'),

            const SizedBox(height: 8),
            _sec('Privacy & Consent'),
            _tile(context, Icons.verified_user_outlined, 'Privacy policy', '/settings/about'), // adjust if you split policy
            _tile(context, Icons.article_outlined, 'Terms of service', '/settings/about'),   // adjust if you split terms
            _tile(context, Icons.rule_folder_outlined, 'Consents', '/settings/consents'),

            const SizedBox(height: 8),
            _sec('About'),
            _tile(context, Icons.info_outline, 'App version & build', '/settings/about'),

            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.logout),
              label: const Text('Sign out (stub)'),
              onPressed: () => Navigator.pushReplacementNamed(context, '/auth/signin'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _sec(String label) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
    child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54, letterSpacing: .6)),
  );

  Widget _tile(BuildContext context, IconData icon, String title, String route) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, route);
        },
      ),
    );
  }
}
