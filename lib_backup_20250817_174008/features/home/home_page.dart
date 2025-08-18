// ignore_for_file: avoid_renaming_method_parameters
import 'package:flutter/material.dart';
import '../../core/shell/app_shell.dart';
import '../../core/widgets/ring_progress.dart';
import '../../core/widgets/section_header.dart';
import '../../app_routes.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext c) => AppShell(
      currentIndex: 0,
      title: 'Home',
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Row(children: [
          Expanded(
              child: Card(
                  child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Welcome back'),
                            Text('Coach tip: small steps daily',
                                style: Theme.of(c).textTheme.bodySmall)
                          ])))),
          const SizedBox(width: 12),
          const RingProgress(value: .62, label: 'Weekly Goal')
        ]),
        const SizedBox(height: 16),
        const SectionHeader(title: 'Quick stats'),
        const Row(children: [
          Expanded(
              child: Card(
                  child: ListTile(
                      title: Text('Sleep'),
                      subtitle: Text('7h 42m'),
                      trailing: Text('+0.3h')))),
          SizedBox(width: 8),
          Expanded(
              child: Card(
                  child: ListTile(
                      title: Text('HRV'),
                      subtitle: Text('64 ms'),
                      trailing: Text('+4')))),
          SizedBox(width: 8),
          Expanded(
              child: Card(
                  child: ListTile(
                      title: Text('Steps'),
                      subtitle: Text('8,410'),
                      trailing: Text('-2%')))),
        ]),
        const SizedBox(height: 16),
        SectionHeader(
            title: 'Shortcuts',
            actionLabel: 'Data Hub',
            onAction: () => Navigator.pushNamed(c, Routes.dataHub)),
        Wrap(spacing: 8, runSpacing: 8, children: [
          FilledButton(
              onPressed: () => Navigator.pushNamed(c, Routes.experiments),
              child: const Text('Experiments')),
          OutlinedButton(
              onPressed: () => Navigator.pushNamed(c, Routes.challenges),
              child: const Text('Challenges')),
          OutlinedButton(
              onPressed: () => Navigator.pushNamed(c, Routes.leaderboards),
              child: const Text('Leaderboards')),
          OutlinedButton(
              onPressed: () => Navigator.pushNamed(c, Routes.badges),
              child: const Text('Badges')),
        ])
      ]));
}
