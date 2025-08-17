import 'package:flutter/material.dart'; import '../../core/shell/app_shell.dart'; import '../../core/widgets/section_header.dart'; import '../../core/widgets/sparkline.dart'; import '../../app_routes.dart';
class DataHubPage extends StatelessWidget{ const DataHubPage({super.key});
  Widget _provider(String name, String status)=>Card(child: ListTile(leading: const Icon(Icons.watch), title: Text(name), subtitle: Text(status), trailing: const Icon(Icons.chevron_right)));
  Widget _snapshot(BuildContext c, String name, String value){
    final rnd = List<double>.generate(16, (i)=> (i%7)/6.0);
    return Card(child: InkWell(onTap: ()=>Navigator.pushNamed(c, Routes.metricDetail, arguments: name), child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
      Text(name, style: Theme.of(c).textTheme.titleMedium), const SizedBox(height:4), Text(value, style: Theme.of(c).textTheme.bodyLarge), const SizedBox(height:8), Sparkline(values: rnd),
    ]))));
  }
  @override Widget build(BuildContext c)=>AppShell(currentIndex:1, title: 'Data Hub', body: ListView(padding: const EdgeInsets.all(16), children:[
    const SectionHeader(title:'Sources', actionLabel: 'Manage'),
    _provider('Apple Health', 'Connected'), _provider('Fitbit', 'Connected'), _provider('Garmin', 'Not connected'), _provider('WHOOP', 'Not connected'),
    const SizedBox(height:12), const SectionHeader(title:'Today\'s snapshot'),
    _snapshot(c,'Sleep','7h 42m'), _snapshot(c,'HRV','64 ms'), _snapshot(c,'Steps','8,410'),
  ]));
}
