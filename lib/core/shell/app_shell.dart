import 'package:flutter/material.dart';
import '../../app_routes.dart';
import 'global_settings_panel.dart';
class AppShell extends StatelessWidget{
  final int currentIndex; final String title; final Widget body;
  const AppShell({super.key, required this.currentIndex, required this.title, required this.body});
  void _go(BuildContext c, int i){
    switch(i){
      case 0: Navigator.pushReplacementNamed(c, Routes.home); break;
      case 1: Navigator.pushReplacementNamed(c, Routes.dataHub); break;
      case 2: Navigator.pushReplacementNamed(c, Routes.experiments); break;
      case 3: Navigator.pushReplacementNamed(c, Routes.community); break;
      case 4: Navigator.pushReplacementNamed(c, Routes.profile); break;
    }
  }
  @override Widget build(BuildContext c)=>Scaffold(
    appBar: AppBar(title: Text(title), actions:[
      IconButton(onPressed: ()=>Navigator.pushNamed(c, Routes.search), icon: const Icon(Icons.search)),
      IconButton(onPressed: ()=>Navigator.pushNamed(c, Routes.inbox), icon: const Icon(Icons.notifications_outlined)),
      IconButton(onPressed: ()=>Scaffold.of(c).openEndDrawer(), icon: const Icon(Icons.settings)),
    ]),
    endDrawer: const GlobalSettingsPanel(), endDrawerEnableOpenDragGesture: true,
    body: SafeArea(child: body),
    bottomNavigationBar: NavigationBar(selectedIndex: currentIndex, destinations: const [
      NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
      NavigationDestination(icon: Icon(Icons.storage_outlined), selectedIcon: Icon(Icons.storage), label: 'Data'),
      NavigationDestination(icon: Icon(Icons.science_outlined), selectedIcon: Icon(Icons.science), label: 'Experiments'),
      NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'Community'),
      NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
    ], onDestinationSelected: (i)=>_go(c,i)),
  );
}
