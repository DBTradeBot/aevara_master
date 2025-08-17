import 'package:flutter/material.dart';
class SyncTimelineList extends StatelessWidget{
  const SyncTimelineList({super.key});
  @override Widget build(BuildContext c)=>Column(children:[
    const ListTile(leading: Icon(Icons.download_done), title: Text('Imported 7 sleep sessions'), subtitle: Text('Oura')),
    const ListTile(leading: Icon(Icons.merge_type), title: Text('Merged steps'), subtitle: Text('Apple Watch')),
    ListTile(leading: const Icon(Icons.error_outline, color: Colors.orange), title: const Text('Overlap resolved (sleep)'), subtitle: const Text('Oura vs Apple'), trailing: Chip(label: const Text('Info'), visualDensity: VisualDensity.compact)),
  ]);
}
