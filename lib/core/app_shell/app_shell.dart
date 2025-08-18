// ignore_for_file: avoid_renaming_method_parameters
import 'package:flutter/material.dart';
import 'top_appbar.dart';
import 'bottom_nav.dart';
import '../settings_overlay/settings_overlay.dart';
import '../dev/dev_navigator_fab.dart';

class AppShell extends StatelessWidget {
  final int currentIndex;
  final String title;
  final Widget body;
  const AppShell(
      {super.key,
      required this.currentIndex,
      required this.title,
      required this.body});
  @override
  Widget build(BuildContext c) => Scaffold(
        appBar: TopAppBar(title: title),
        endDrawer: const Drawer(child: SettingsOverlay()),
        endDrawerEnableOpenDragGesture: true,
        body: SafeArea(child: body),
        bottomNavigationBar: BottomNav(currentIndex: currentIndex),
        floatingActionButton: DevNavigatorFab(),
      );
}

