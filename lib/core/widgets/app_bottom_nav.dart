import 'package:flutter/material.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.storage_rounded), label: 'Data'),
        BottomNavigationBarItem(icon: Icon(Icons.insights_rounded), label: 'Insights'),
        BottomNavigationBarItem(icon: Icon(Icons.science_rounded), label: 'Experiments'),
        BottomNavigationBarItem(icon: Icon(Icons.groups_rounded), label: 'Community'),
      ],
    );
  }
}
