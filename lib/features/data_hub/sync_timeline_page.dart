<<<<<<< Updated upstream
﻿// ignore_for_file: avoid_renaming_method_parameters
=======
// ignore_for_file: avoid_renaming_method_parameters
>>>>>>> Stashed changes
import 'package:flutter/material.dart';
import 'timeline/sync_timeline_list.dart';

class SyncTimelinePage extends StatelessWidget {
  const SyncTimelinePage({super.key});
  @override
  Widget build(BuildContext c) => Scaffold(
      appBar: AppBar(title: const Text('Sync Timeline')),
      body: const Padding(
          padding: EdgeInsets.all(16), child: SyncTimelineList()));
}

