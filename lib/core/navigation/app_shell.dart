import 'package:flutter/foundation.dart'; import 'package:flutter/material.dart'; import 'app_bottom_nav.dart'; import 'app_side_drawer.dart'; import 'dev/dev_fab.dart';
class AppShell extends StatelessWidget{ final Widget child; final int currentIndex; const AppShell({super.key, required this.child, this.currentIndex=0});
  @override Widget build(BuildContext c)=>Scaffold(drawer: const AppSideDrawer(), body: SafeArea(child: child), bottomNavigationBar: AppBottomNav(index: currentIndex), floatingActionButton: kDebugMode ? const DevFab() : null);
}
