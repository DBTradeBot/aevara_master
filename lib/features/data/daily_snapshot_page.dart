import 'package:flutter/material.dart';

class DailySnapshotPage extends StatelessWidget {
  const DailySnapshotPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tiles = [
      ('Vitality Score', '82', Icons.favorite),
      ('Readiness', '76', Icons.local_fire_department),
      ('Sleep', '7h 45m', Icons.nightlight_round),
      ('Activity', '8,320 steps', Icons.directions_walk),
      ('HRV', '61 ms', Icons.show_chart),
      ('Resting HR', '54 bpm', Icons.favorite_border),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Snapshot')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final t in tiles) ...[
            Card(
              child: ListTile(
                leading: Icon(t.$3),
                title: Text(t.$1),
                subtitle: const Text('Today'),
                trailing: Text(t.$2,
                    style: Theme.of(context).textTheme.titleMedium),
                onTap: () => Navigator.pushNamed(
                  context,
                  '/data/metric',
                  arguments: {'metric': t.$1},
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
