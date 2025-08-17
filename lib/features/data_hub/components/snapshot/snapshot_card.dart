import 'package:flutter/material.dart';
import 'source_badge.dart'; import 'freshness_chip.dart'; import 'mini_sparkline.dart';
class SnapshotCard extends StatelessWidget{
  final String title; final String bigValue; final String unit; final String source; final String freshness; final VoidCallback onTap;
  const SnapshotCard({super.key, required this.title, required this.bigValue, required this.unit, required this.source, required this.freshness, required this.onTap});
  @override Widget build(BuildContext c)=>Card(child: InkWell(onTap:onTap, child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
    Text(title, style: Theme.of(c).textTheme.titleMedium),
    const SizedBox(height:4),
    LayoutBuilder(builder: (_, box){
      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: box.maxWidth),
        child: FittedBox(
          alignment: Alignment.centerLeft, fit: BoxFit.scaleDown,
          child: Row(children:[
            Text(bigValue, style: Theme.of(c).textTheme.headlineSmall),
            if(unit.isNotEmpty) const SizedBox(width:4),
            if(unit.isNotEmpty) Text(unit),
          ]),
        ),
      );
    }),
    const SizedBox(height:6),
    Row(children:[SourceBadge(source: source), const SizedBox(width:6), FreshnessChip(freshness:freshness)]),
    const SizedBox(height:8),
    const MiniSparkline(values: [0.2,0.4,0.6,0.5,0.7,0.8,0.6])
  ]))));
}
