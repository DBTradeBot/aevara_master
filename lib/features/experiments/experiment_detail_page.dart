import 'package:flutter/material.dart';

class ExperimentDetailPage extends StatefulWidget {
  const ExperimentDetailPage({super.key});

  @override
  State<ExperimentDetailPage> createState() => _ExperimentDetailPageState();
}

class _ExperimentDetailPageState extends State<ExperimentDetailPage> {
  String mode = 'Solo';
  int days = 7;
  bool caffeineCutoff = true;
  bool windDown = true;
  bool dimLights = true;

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    final name = args['name'] as String? ?? 'Experiment';
    final desc = args['desc'] as String? ?? 'Description';

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(desc),
          const SizedBox(height: 12),

          // Mode
          Text('Mode', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'Solo', label: Text('Solo')),
              ButtonSegment(value: 'Group', label: Text('Group')),
            ],
            selected: {mode},
            onSelectionChanged: (s) => setState(() => mode = s.first),
          ),
          const SizedBox(height: 16),

          // Duration
          Text('Duration', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            value: days,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: const [7, 14, 21, 28]
                .map((d) => DropdownMenuItem(value: d, child: Text('$d days')))
                .toList(),
            onChanged: (v) => setState(() => days = v ?? 7),
          ),
          const SizedBox(height: 16),

          // Checklist (example)
          Text('Checklist', style: Theme.of(context).textTheme.titleMedium),
          CheckboxListTile(
            value: caffeineCutoff,
            onChanged: (v) => setState(() => caffeineCutoff = v ?? false),
            title: const Text('Caffeine cutoff 8h before bed'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          CheckboxListTile(
            value: windDown,
            onChanged: (v) => setState(() => windDown = v ?? false),
            title: const Text('20â€“30 min wind-down routine'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          CheckboxListTile(
            value: dimLights,
            onChanged: (v) => setState(() => dimLights = v ?? false),
            title: const Text('Dim lights 1â€“2h before bed'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 16),

          // Start
          FilledButton.icon(
            icon: const Icon(Icons.flag),
            label: Text('Start ${mode.toLowerCase()} experiment'),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$name started for $days days')),
              );
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
