import 'package:flutter/material.dart';
class MetricDetailsSheet extends StatelessWidget{
  final String metric;
  const MetricDetailsSheet({super.key, required this.metric});
  @override Widget build(BuildContext c){
    return Padding(padding: const EdgeInsets.all(16), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children:[
      Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: Theme.of(c).colorScheme.outlineVariant, borderRadius: BorderRadius.circular(8)))),
      const SizedBox(height:12),
      Text(metric, style: Theme.of(c).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height:8),
      SegmentedButton<int>(segments: const [ButtonSegment(value:7, label: Text('7d')), ButtonSegment(value:30, label: Text('30d')), ButtonSegment(value:90, label: Text('90d'))], selected: const {30}, onSelectionChanged: (_)=>{}),
      const SizedBox(height:12),
      Container(height: 120, alignment: Alignment.center, decoration: BoxDecoration(border: Border.all(color: Theme.of(c).dividerColor), borderRadius: BorderRadius.circular(12)), child: const Text('Chart placeholder')),
      const SizedBox(height:12),
      const ListTile(title: Text('Insights'), subtitle: Text('Consistency improving; keep bedtime before 11pm.')),
      const SizedBox(height:8),
      const Text('Source comparison', style: TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height:6),
      Table(columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(), 2: FlexColumnWidth(2)}, children:[
        const TableRow(children:[Padding(padding: EdgeInsets.all(6), child: Text('Provider', style: TextStyle(fontWeight: FontWeight.w600))), Padding(padding: EdgeInsets.all(6), child: Text('Value', style: TextStyle(fontWeight: FontWeight.w600))), Padding(padding: EdgeInsets.all(6), child: Text('Timestamp', style: TextStyle(fontWeight: FontWeight.w600)))]),
        ...['Oura','Apple','Fitbit'].map((p)=>TableRow(children:[
          Padding(padding: const EdgeInsets.all(6), child: Text(p)),
          const Padding(padding: EdgeInsets.all(6), child: Text('--')),
          const Padding(padding: EdgeInsets.all(6), child: Text('Today 07:10')),
        ])).toList()
      ]),
      const SizedBox(height:8),
      const ExpansionTile(title: Text('Why this value?'), children:[ListTile(title: Text('Priority rule: Oura > Apple > Fitbit'))]),
      const SizedBox(height:8),
      const ListTile(title: Text('Per-day sources (14d)'), subtitle: Text('UI placeholder')),
      const SizedBox(height:12),
    ]));
  }
}
