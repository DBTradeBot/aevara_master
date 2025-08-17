import 'package:flutter/material.dart';
import '../../core/app_shell/app_shell.dart';
class ProfilePage extends StatelessWidget{ const ProfilePage({super.key});
  @override Widget build(BuildContext c)=>const AppShell(currentIndex:4, title: 'Profile', body: Center(child: Text('Profile placeholder â€” use settings overlay.')));
}
