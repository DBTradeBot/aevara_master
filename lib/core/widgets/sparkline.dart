<<<<<<< Updated upstream
﻿// ignore_for_file: avoid_renaming_method_parameters
=======
// ignore_for_file: avoid_renaming_method_parameters
>>>>>>> Stashed changes
import 'package:flutter/material.dart';

class Sparkline extends StatelessWidget {
  final List<double> values;
  const Sparkline({super.key, required this.values});
  @override
  Widget build(BuildContext c) => SizedBox(
      height: 32,
      child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: values
              .map((v) => Expanded(
                  child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.5),
                      child: Container(height: (v.clamp(0, 1)) * 32))))
              .toList()));
}

