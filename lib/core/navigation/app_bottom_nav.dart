<<<<<<< Updated upstream
﻿// ignore_for_file: avoid_renaming_method_parameters
=======
// ignore_for_file: avoid_renaming_method_parameters
>>>>>>> Stashed changes
import 'package:flutter/material.dart';
import '../../app_routes.dart';

class AppBottomNav extends StatelessWidget {
  final int index;
  const AppBottomNav({super.key, required this.index});
  void _go(BuildContext c, String r) {
<<<<<<< Updated upstream
    if (ModalRoute.of(c)?.settings.name == r) return;
    Navigator.of(c).pushReplacementNamed(r);
=======
    if (ModalRoute.of(c)?.settings.name == r)
      return Navigator.of(c).pushReplacementNamed(r);
>>>>>>> Stashed changes
  }

  @override
  Widget build(BuildContext c) => NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) {
            switch (i) {
              case 0:
                _go(c, Routes.home);
                break;
              case 1:
                _go(c, Routes.dataHub);
                break;
              case 2:
                _go(c, Routes.experiments);
                break;
              case 3:
                _go(c, Routes.community);
                break;
              case 4:
                _go(c, Routes.profile);
            }
          },
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
            NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile'),
          ]);
}

