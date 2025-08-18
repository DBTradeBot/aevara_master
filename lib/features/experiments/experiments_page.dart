import 'package:flutter/material.dart';
import '../../widgets/layout/page_header.dart';

class ExperimentsPage extends StatelessWidget {
  const ExperimentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final experiments = [
      ('5-min Breathing', 'Recovery', '7 days', ['HRV', 'Healthy Days']),
      ('+30 min Sleep', 'Sleep', '14 days', ['Sleep', 'HRV']),
      ('+10% Steps', 'Activity', '14 days', ['Steps', 'Healthy Days']),
      ('Zone 2 3x/week', 'Cardio', '21 days', ['VOâ‚‚max', 'HRV']),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Experiments')),
      body: ListView(
        children: [
          const PageHeader(title: 'Catalog'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final e in experiments)
                  SizedBox(
                    width: 220,
                    child: Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => _ExperimentDetail(
                                    title: e.$1,
                                    category: e.$2,
                                    duration: e.$3,
                                    tracks: e.$4))),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(e.$1,
                                  style:
                                      Theme.of(context).textTheme.labelLarge),
                              const SizedBox(height: 4),
                              Text(e.$2,
                                  style: Theme.of(context).textTheme.bodySmall),
                              const SizedBox(height: 12),
                              Text(e.$3),
                              const SizedBox(height: 8),
                              Wrap(spacing: 6, children: [
                                for (final t in e.$4) Chip(label: Text(t))
                              ]),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ExperimentDetail extends StatelessWidget {
  final String title;
  final String category;
  final String duration;
  final List<String> tracks;
  const _ExperimentDetail(
      {required this.title,
      required this.category,
      required this.duration,
      required this.tracks});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category: $category'),
            const SizedBox(height: 6),
            Text('Default duration: $duration'),
            const SizedBox(height: 12),
            const Text('What youâ€™ll do'),
            const Text('â€¢ Daily practice with reminders (stub).'),
            const SizedBox(height: 12),
            const Text('Metrics weâ€™ll track'),
            Wrap(
                spacing: 8,
                children: [for (final t in tracks) Chip(label: Text(t))]),
            const Spacer(),
            FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Experiment started (stub).')));
                },
                child: const Text('Start Experiment')),
          ],
        ),
      ),
    );
  }
}
