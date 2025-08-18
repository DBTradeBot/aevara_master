<<<<<<< Updated upstream
﻿// ignore_for_file: avoid_renaming_method_parameters
=======
// ignore_for_file: avoid_renaming_method_parameters
>>>>>>> Stashed changes
import 'package:flutter/material.dart';

class TrendLine extends StatelessWidget {
  final List<double> values;
  const TrendLine({super.key, required this.values});
  @override
  Widget build(BuildContext c) => SizedBox(
      height: 80, child: Center(child: Text('Trend (${values.length})')));
}
<<<<<<< Updated upstream

=======
>>>>>>> Stashed changes
