import 'package:flutter/material.dart';
import '../../widgets/layout/page_header.dart';
import '../../widgets/atoms/aev_status_dot.dart';

class DataHubPage extends StatelessWidget {
  const DataHubPage({super.key});

  Color _statusColor(String status) {
    switch(status){
      case 'ok': return Colors.green;
      case 'partial': return Colors.amber;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sources = [
      ('Apple Health', 'ok', 'synced 2h ago'),
      ('Google Fit', 'partial', 'synced 1d ago'),
      ('WHOOP', 'none', 'connect'),
    ];

    final snapshots = [
      ('Sleep', '7h 40m', 'Apple Health'),
      ('HRV', '52 ms', 'WHOOP'),
      ('Steps', '6,420', 'Garmin'),
      ('Healthy Days (30d)', '24', 'Aevara'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Data Hub')),
      body: ListView(
        children: [
          const PageHeader(title: 'Sources'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal:16),
            child: Wrap(
              spacing: 12, runSpacing: 12,
              children: [
                for (final s in sources)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AevStatusDot(color: _statusColor(s.$2)),
                          const SizedBox(width: 8),
                          Text(s.$1),
                          const SizedBox(width: 12),
                          Text(s.$3, style: Theme.of(context).textTheme.bodySmall),
                          const SizedBox(width: 12),
                          OutlinedButton(onPressed: (){
                            showModalBottomSheet(context: context, showDragHandle: true, builder: (c)=> _SourceDetails(name: s.$1));
                          }, child: const Text('Manage')),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const PageHeader(title: 'Today’s snapshots'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 12, runSpacing: 12,
              children: [
                for (final m in snapshots)
                  SizedBox(
                    width: 168,
                    child: Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: (){
                          showModalBottomSheet(context: context, isScrollControlled: true, showDragHandle: true,
                            builder: (c)=> _MetricDetails(metric: m.$1, value: m.$2, source: m.$3));
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(m.$1, style: Theme.of(context).textTheme.labelLarge),
                              const SizedBox(height: 8),
                              Text(m.$2, style: Theme.of(context).textTheme.headlineSmall),
                              const SizedBox(height: 6),
                              Text(m.$3, style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
              ],
            ),
          ),
          const SizedBox(height: 16),
          const PageHeader(title: 'Export'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Expanded(child: Text('Download CSV/JSON of your data (range & fields selectable later).')),
                    FilledButton(onPressed: (){
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export stub.')));
                    }, child: const Text('Export')),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SourceDetails extends StatelessWidget {
  final String name;
  const _SourceDetails({required this.name});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text('Scopes: read sleep, activity, heart-rate variability'),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [
              OutlinedButton(onPressed: (){}, child: const Text('Reconnect')),
              OutlinedButton(onPressed: (){}, child: const Text('Revoke')),
              OutlinedButton(onPressed: (){}, child: const Text('Sync now')),
            ]),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _MetricDetails extends StatelessWidget {
  final String metric;
  final String value;
  final String source;
  const _MetricDetails({required this.metric, required this.value, required this.source});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      builder: (_, controller)=> Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView(
          controller: controller,
          children: [
            Text(metric, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('Today: $value  •  Source: $source'),
            const SizedBox(height: 12),
            const Text('Why this value?'),
            const SizedBox(height: 4),
            const Text('Merged from available providers using Aevara priority rules (stub for now).'),
            const SizedBox(height: 12),
            const Text('History (14 days) – chart placeholder'),
            const SizedBox(height: 12),
            FilledButton(onPressed: ()=> Navigator.pop(context), child: const Text('Close')),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
