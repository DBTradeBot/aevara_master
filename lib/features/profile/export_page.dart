import 'package:flutter/material.dart'; import '../../core/inputs/picker_row.dart'; import '../../core/inputs/toggle_row.dart'; import '../../core/utils/snack.dart';
class ExportPage extends StatelessWidget{ const ExportPage({super.key});
  @override Widget build(BuildContext c)=>Scaffold(appBar: AppBar(title: const Text('Export My Data')), body: ListView(children:[
    PickerRow(label:'Date range', value:'Last 30 days', onTap: (){}),
    const ToggleRow(label:'Include metrics'),
    const ToggleRow(label:'Include experiments'),
    const ToggleRow(label:'Include community data'),
    Padding(padding: const EdgeInsets.all(16), child: FilledButton(onPressed: (){snack(c,'Export requested (placeholder)');}, child: const Text('Prepare export'))),
  ]));
}
