// lib/shell/app_shell.dart
//
// AppShell — tabs + AppBar + Settings banner.
// Avatar sits in AppBar.leading (left of "Home") with symmetric padding
// so the dropdown anchor is inset from the screen edge.
// Toggle logic works with overlay handle that is marked closed on any dismiss.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Feature entry pages
import '../features/home/dashboard_page.dart';
import '../features/data_hub/data_hub_page.dart';
import '../features/insights/insights_page.dart';
import '../features/experiments/experiments_page.dart';
import '../features/community/community_page.dart';

// Shared widgets
import '../core/widgets/app_bottom_nav.dart';
import '../core/widgets/settings_banner.dart';
import '../core/widgets/avatar/coach_avatar.dart';
import '../core/widgets/avatar/coach_insights_overlay.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, this.initialTab = 0});
  final int initialTab; // 0..4

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  late int _index;

  final _pages = const <Widget>[
    DashboardPage(),
    DataHubPage(),
    InsightsPage(),
    ExperimentsPage(),
    CommunityPage(),
  ];

  final _titles = const <String>[
    'Home',
    'Data',
    'Insights',
    'Experiments',
    'Community',
  ];

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Coach overlay anchoring/handle
  final LayerLink _coachLink = LayerLink();
  CoachInsightsOverlayHandle? _coachHandle;

  @override
  void initState() {
    super.initState();
    _index = widget.initialTab.clamp(0, _pages.length - 1);
  }

  @override
  void dispose() {
    _coachHandle?.close();
    super.dispose();
  }

  void _openSettings() => _scaffoldKey.currentState?.openEndDrawer();

  double _drawerWidth(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final isTablet = size.shortestSide >= 600;
    final percent = isTablet ? 0.45 : 0.72;
    final cap = isTablet ? 420.0 : 360.0;
    return math.min(w * percent, cap);
  }

  void _reopenSettingsAfterPop() {
    Future.microtask(() => _scaffoldKey.currentState?.openEndDrawer());
  }

  Future<void> _toggleCoachOverlay() async {
    // If we still hold a handle but it's been marked closed, drop it.
    if (_coachHandle != null && _coachHandle!.isOpen == false) {
      _coachHandle = null;
    }

    if (_coachHandle?.isOpen == true) {
      await _coachHandle!.close(); // marks closed immediately
      _coachHandle = null;
      return;
    }

    // Open a new overlay — NOTE: no builder passed so default chat UI shows
    _coachHandle = await showCoachInsightsOverlay(
      context: context,
      link: _coachLink,
      // builder: (ctx, close) => _CoachInsightsPanel(onClose: close), // removed
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        // Give the leading avatar a wider hit target and horizontal inset
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0), // inset from screen edge
          child: CompositedTransformTarget(
            link: _coachLink,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _toggleCoachOverlay,
              child: Semantics(
                button: true,
                label: 'Open coach insights',
                child: Center(
                  child: CoachAvatar(
                    size: 40,
                    padding: 0,
                    showHalo: false,
                    hideLayerNames: const ['Aura 2'],
                    semanticLabel: 'Coach avatar',
                  ),
                ),
              ),
            ),
          ),
        ),
        title: Text(_titles[_index]),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
      endDrawer: Drawer(
        width: _drawerWidth(context),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            bottomLeft: Radius.circular(24),
          ),
          child: Material(
            child: SettingsBanner(
              onReturnToShell: _reopenSettingsAfterPop,
            ),
          ),
        ),
      ),
      endDrawerEnableOpenDragGesture: true,
      drawerScrimColor: Colors.black.withOpacity(0.30),
    );
  }
}

// (Optional) Keep this around if you want to pass a custom builder later.
// class _CoachInsightsPanel extends StatelessWidget {
//   const _CoachInsightsPanel({required this.onClose});
//   final VoidCallback onClose;
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Text('Coach insights',
//                 style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
//             const Spacer(),
//             IconButton(
//               tooltip: 'Close',
//               onPressed: onClose,
//               icon: const Icon(Icons.close_rounded),
//             ),
//           ],
//         ),
//         const SizedBox(height: 8),
//         const Text('Custom content goes here…'),
//       ],
//     );
//   }
// }
