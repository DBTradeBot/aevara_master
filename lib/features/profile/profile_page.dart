import 'package:flutter/material.dart';
import '../../core/app_shell/app_shell.dart';
class ProfilePage extends StatelessWidget{ const ProfilePage({super.key});
  @override Widget build(BuildContext c)=>AppShell(currentIndex:4, title: 'Profile', body: const Center(child: Text('Profile placeholder — use settings overlay.')));
}
