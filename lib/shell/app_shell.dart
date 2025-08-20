// lib/shell/app_shell.dart
// Global app shell with bottom navigation selecting between 5 top tabs.
// The pages are the empty placeholders you already have.
// This file accepts `initialTab` so routing can open the correct tab.

import 'package:flutter/material.dart';

// Feature entry pages (empty for now)
import '../features/home/dashboard_page.dart';
import '../features/data_hub/data_hub_page.dart';
import '../features/insights/insights_page.dart';
import '../features/experiments/experiments_page.dart';
import '../features/community/community_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.initialTab = 0});

  /// 0: Home, 1: Data, 2: Insights, 3: Experiments, 4: Community
  final int initialTab;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _index;

  final _pages = const <Widget>[
    DashboardPage(),      // /app/home
    DataHubPage(),        // /app/data-hub
    InsightsPage(),       // /insights
    ExperimentsPage(),    // /experiments
    CommunityPage(),      // /community
  ];

  @override
  void initState() {
    super.initState();
    _index = widget.initialTab.clamp(0, _pages.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.storage_outlined), selectedIcon: Icon(Icons.storage), label: 'Data'),
          NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: 'Insights'),
          NavigationDestination(icon: Icon(Icons.science_outlined), selectedIcon: Icon(Icons.science), label: 'Experiments'),
          NavigationDestination(icon: Icon(Icons.group_outlined), selectedIcon: Icon(Icons.group), label: 'Community'),
        ],
      ),
    );
  }
}
