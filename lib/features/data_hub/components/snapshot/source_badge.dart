<<<<<<< Updated upstream
﻿// ignore_for_file: avoid_renaming_method_parameters
=======
// ignore_for_file: avoid_renaming_method_parameters
>>>>>>> Stashed changes
import 'package:flutter/material.dart';

class SourceBadge extends StatelessWidget {
  final String source;
  const SourceBadge({super.key, required this.source});
  @override
  Widget build(BuildContext c) => Chip(
      label: Text(source),
      avatar: const Icon(Icons.verified, size: 16),
      visualDensity: VisualDensity.compact);
}

