import 'package:flutter/material.dart';
import 'metric_detail/metric_details_sheet.dart';
class MetricDetailsDemoPage extends StatelessWidget{ const MetricDetailsDemoPage({super.key});
  @override Widget build(BuildContext c)=>Scaffold(appBar: AppBar(title: const Text('Metric Details (Demo)')), body: Center(
    child: FilledButton(onPressed: (){ showModalBottomSheet(context:c, isScrollControlled:true, builder:(_)=>const MetricDetailsSheet(metric: 'Sleep')); }, child: const Text('Open details sheet')),
  ));
}
