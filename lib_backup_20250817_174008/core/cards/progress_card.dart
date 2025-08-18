// ignore_for_file: avoid_renaming_method_parameters
import 'package:flutter/material.dart';

class ProgressCard extends StatelessWidget {
  final String label;
  final double progress;
  const ProgressCard({super.key, required this.label, required this.progress});
  @override
  Widget build(BuildContext c) => Card(
      child: ListTile(
          title: Text(label),
          subtitle: LinearProgressIndicator(value: progress)));
}
