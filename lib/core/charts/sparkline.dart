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
      height: 30, child: Center(child: Text('Spark ${values.length}')));
}
<<<<<<< Updated upstream

=======
>>>>>>> Stashed changes
