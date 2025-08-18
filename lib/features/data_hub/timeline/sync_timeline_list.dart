<<<<<<< Updated upstream
﻿// ignore_for_file: avoid_renaming_method_parameters
=======
// ignore_for_file: avoid_renaming_method_parameters
>>>>>>> Stashed changes
import 'package:flutter/material.dart';

class SyncTimelineList extends StatelessWidget {
  const SyncTimelineList({super.key});
  @override
  Widget build(BuildContext c) => const Column(children: [
        ListTile(
            leading: Icon(Icons.download_done),
            title: Text('Imported 7 sleep sessions'),
            subtitle: Text('Oura')),
        ListTile(
            leading: Icon(Icons.merge_type),
            title: Text('Merged steps'),
            subtitle: Text('Apple Watch')),
        ListTile(
            leading: Icon(Icons.error_outline, color: Colors.orange),
            title: Text('Overlap resolved (sleep)'),
            subtitle: Text('Oura vs Apple'),
            trailing: Chip(
                label: Text('Info'), visualDensity: VisualDensity.compact)),
      ]);
}

