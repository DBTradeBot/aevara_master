// ignore_for_file: avoid_renaming_method_parameters
import 'package:flutter/material.dart';
import '../../navigation/routes.dart';

class TopAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const TopAppBar({super.key, required this.title});
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  @override
  Widget build(BuildContext c) => AppBar(
        title: Text(title),
        actions: [
          IconButton(
              onPressed: () => Navigator.pushNamed(c, Routes.search),
              icon: const Icon(Icons.search)),
          IconButton(
              onPressed: () => Navigator.pushNamed(c, Routes.inbox),
              icon: const Icon(Icons.notifications_outlined)),
          Builder(
              builder: (ctx) => IconButton(
                  onPressed: () => Scaffold.of(ctx).openEndDrawer(),
                  icon: const Icon(Icons.settings))),
        ],
      );
}
