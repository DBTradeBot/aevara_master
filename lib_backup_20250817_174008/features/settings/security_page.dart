// ignore_for_file: avoid_renaming_method_parameters
import 'package:flutter/material.dart';

class SecurityPage extends StatelessWidget {
  const SecurityPage({super.key});
  @override
  Widget build(BuildContext c) => Scaffold(
      appBar: AppBar(title: const Text('Security')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        FilledButton(
            onPressed: () {}, child: const Text('Set up 2FA (placeholder)')),
        const ListTile(
            title: Text('Sessions'),
            subtitle: Text('Sign out of other devices (placeholder)')),
      ]));
}
