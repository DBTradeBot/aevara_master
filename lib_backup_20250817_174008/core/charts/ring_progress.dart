// ignore_for_file: avoid_renaming_method_parameters
import 'package:flutter/material.dart';

class RingProgress extends StatelessWidget {
  final double value;
  const RingProgress({super.key, required this.value});
  @override
  Widget build(BuildContext c) => SizedBox(
      height: 80,
      width: 80,
      child: Stack(alignment: Alignment.center, children: [
        CircularProgressIndicator(value: value),
        Text('${(value * 100).round()}%')
      ]));
}
