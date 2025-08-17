import 'package:flutter/material.dart';

class ExperimentsHomePage extends StatelessWidget {
  const ExperimentsHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = [
      ('Sleep Hygiene', '7d: caffeine cutoff, wind-down, lights'),
      ('Morning Light', '10â€“15 min outdoor light on wake'),
      ('Hydration', '2L/day, no late fluids'),
      ('No Alcohol', 'A/B weeks'),
      ('Late Exercise', 'Avoid <3h before sleep'),
      ('Digital Sunset', 'Screens off 1h before bed'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Experiments')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('My Experiments', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.flag),
              title: const Text('None active'),
              subtitle: const Text('Start one below'),
            ),
          ),
          const SizedBox(height: 16),
          Text('Browse', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final e in catalog) ...[
            Card(
              child: ListTile(
                leading: const Icon(Icons.science_outlined),
                title: Text(e.$1),
                subtitle: Text(e.$2),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(
                  context,
                  '/experiments/detail',
                  arguments: {'name': e.$1, 'desc': e.$2},
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
