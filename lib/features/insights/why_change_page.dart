// ignore_for_file: avoid_renaming_method_parameters
import 'package:flutter/material.dart';
import '../../core/navigation/app_shell.dart';

class WhyChangePage extends StatelessWidget {
  const WhyChangePage({super.key});
  @override
  Widget build(BuildContext c) => AppShell(
      currentIndex: 0,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        Text('Drivers', style: Theme.of(c).textTheme.titleLarge),
        const ListTile(
            title: Text('Sleep'),
            subtitle: Text('Ã¢â€ â€˜ +0.3 hours vs prior week')),
        const ListTile(
            title: Text('HRV'), subtitle: Text('Ã¢â€ â€˜ +4 ms vs prior week')),
        const ListTile(
            title: Text('Steps'), subtitle: Text('Ã¢â€ â€™ flat vs prior week')),
      ]));
}

