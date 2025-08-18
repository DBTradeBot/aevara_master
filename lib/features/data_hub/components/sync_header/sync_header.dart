<<<<<<< Updated upstream
﻿// ignore_for_file: avoid_renaming_method_parameters
=======
// ignore_for_file: avoid_renaming_method_parameters
>>>>>>> Stashed changes
import 'package:flutter/material.dart';

class SyncHeader extends StatelessWidget {
  const SyncHeader({super.key});
  @override
  Widget build(BuildContext c) => Row(children: [
        const Icon(Icons.sync),
        const SizedBox(width: 8),
        const Expanded(child: Text('Last sync: 2h ago')),
        FilledButton.tonal(onPressed: () {}, child: const Text('Sync now'))
      ]);
}

