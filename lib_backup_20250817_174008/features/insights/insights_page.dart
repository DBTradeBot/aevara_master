// ignore_for_file: avoid_renaming_method_parameters
import 'package:flutter/material.dart';
import '../../core/navigation/app_shell.dart';
import '../../core/charts/trend_line.dart';

class InsightsPage extends StatelessWidget {
  const InsightsPage({super.key});
  @override
  Widget build(BuildContext c) => AppShell(
      currentIndex: 0,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        Text('Insights', style: Theme.of(c).textTheme.headlineMedium),
        const SizedBox(height: 8),
        const TrendLine(values: [.2, .3, .35, .4, .38, .5, .6, .62, .65, .7]),
        const SizedBox(height: 8),
        const Text(
            'Why did this change? Drivers: Sleep Ã¢â€ â€˜, Steps Ã¢â€ â€™, HRV Ã¢â€ â€˜'),
        const SizedBox(height: 8),
        FilledButton(
            onPressed: () {
              Navigator.pushNamed(c, '/insights/why_change');
            },
            child: const Text('See Drivers')),
        TextButton(
            onPressed: () {
              Navigator.pushNamed(c, '/info/methods_doc');
            },
            child: const Text('Methods & Transparency')),
      ]));
}
