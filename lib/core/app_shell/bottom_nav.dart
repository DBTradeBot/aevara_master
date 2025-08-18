// ignore_for_file: avoid_renaming_method_parameters
import 'package:flutter/material.dart';
import '../../navigation/routes.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  const BottomNav({super.key, required this.currentIndex});
  void _go(BuildContext c, int i) {
    switch (i) {
      case 0:
        Navigator.pushReplacementNamed(c, Routes.home);
        break;
      case 1:
        Navigator.pushReplacementNamed(c, Routes.dataHub);
        break;
      case 2:
        Navigator.pushReplacementNamed(c, Routes.experiments);
        break;
      case 3:
        Navigator.pushReplacementNamed(c, Routes.community);
        break;
    }
  }

  @override
  Widget build(BuildContext c) => NavigationBar(
        selectedIndex: currentIndex,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.storage_outlined),
              selectedIcon: Icon(Icons.storage),
              label: 'Data'),
          NavigationDestination(
              icon: Icon(Icons.science_outlined),
              selectedIcon: Icon(Icons.science),
              label: 'Experiments'),
          NavigationDestination(
              icon: Icon(Icons.groups_outlined),
              selectedIcon: Icon(Icons.groups),
              label: 'Community'),
        ],
        onDestinationSelected: (i) => _go(c, i),
      );
}

