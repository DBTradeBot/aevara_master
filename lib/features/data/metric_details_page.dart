import 'package:flutter/material.dart';

class MetricDetailsPage extends StatefulWidget {
  const MetricDetailsPage({super.key});

  @override
  State<MetricDetailsPage> createState() => _MetricDetailsPageState();
}

class _MetricDetailsPageState extends State<MetricDetailsPage> {
  String range = '7d';

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final metric = args?['metric'] as String? ?? 'Metric Details';

    return Scaffold(
      appBar: AppBar(title: Text(metric)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Range chips
          Wrap(
            spacing: 8,
            children: ['7d', '14d', '30d', '90d']
                .map((r) => ChoiceChip(
              label: Text(r),
              selected: range == r,
              onSelected: (_) => setState(() => range = r),
            ))
                .toList(),
          ),
          const SizedBox(height: 12),

          // Chart placeholder
          Card(
            child: SizedBox(
              height: 220,
              child: Center(
                child: Text('Chart ($range) — stubbed',
                    style: Theme.of(context).textTheme.bodyMedium),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Drivers / Insights
          Card(
            child: ListTile(
              leading: const Icon(Icons.lightbulb_outline),
              title: const Text('What moved this metric?'),
              subtitle: const Text(
                  'Sleep schedule consistency • Alcohol flag • Late workouts'),
              onTap: () {},
            ),
          ),
          const SizedBox(height: 12),

          // Sources
          Card(
            child: ListTile(
              leading: const Icon(Icons.storage_outlined),
              title: const Text('Data sources'),
              subtitle: const Text('WHOOP, Oura, Apple Health (synced)'),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}
