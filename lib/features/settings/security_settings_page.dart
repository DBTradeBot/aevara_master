import 'package:flutter/material.dart'; import '../../core/utils/snack.dart';
class SecuritySettingsPage extends StatelessWidget{ const SecuritySettingsPage({super.key});
  @override Widget build(BuildContext c)=>Scaffold(appBar: AppBar(title: const Text('Security')), body: ListView(padding: const EdgeInsets.all(16), children:[
    const ListTile(title: Text('Two-Factor Authentication')),
    FilledButton(onPressed: (){snack(c,'2FA setup (placeholder)');}, child: const Text('Set up 2FA')),
    const SizedBox(height:12),
    const ListTile(title: Text('Sessions & Devices')),
    ListTile(title: const Text('iPhone 15 • San Francisco'), trailing: TextButton(onPressed: (){}, child: const Text('Sign out'))),
    ListTile(title: const Text('Web • Chrome'), trailing: TextButton(onPressed: (){}, child: const Text('Sign out'))),
    const SizedBox(height:12),
    FilledButton(onPressed: (){snack(c,'Signed out other sessions (placeholder)');}, child: const Text('Sign out of other sessions')),
  ]));
}
