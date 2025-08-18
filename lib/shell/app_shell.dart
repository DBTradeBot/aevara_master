import 'package:flutter/material.dart';
import '../routing/route_paths.dart';
import '../core/widgets/app_bottom_nav.dart';
import '../features/home/dashboard_page.dart';
import '../features/data_hub/data_hub_page.dart';
import '../features/insights/insights_page.dart';
import '../features/experiments/experiments_page.dart';
import '../features/community/community_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  final _pages = const <Widget>[
    DashboardPage(),
    DataHubPage(),
    InsightsPage(),
    ExperimentsPage(),
    CommunityPage(),
  ];

  final _titles = const <String>[
    'Home',
    'Data Hub',
    'Insights',
    'Experiments',
    'Community',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
      body: _pages[_index],
      bottomNavigationBar: AppBottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
