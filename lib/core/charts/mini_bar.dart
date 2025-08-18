<<<<<<< Updated upstream
﻿// ignore_for_file: avoid_renaming_method_parameters
=======
// ignore_for_file: avoid_renaming_method_parameters
>>>>>>> Stashed changes
import 'package:flutter/material.dart';

class MiniBar extends StatelessWidget {
  final List<double> values;
  const MiniBar({super.key, required this.values});
  @override
  Widget build(BuildContext c) => SizedBox(
      height: 40,
      child: Row(
          children: values
              .map((v) => Expanded(
                  child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: Container(
                          height: (v.clamp(0, 1)) * 40,
                          color: Colors.blueGrey))))
              .toList()));
}
<<<<<<< Updated upstream

=======
>>>>>>> Stashed changes
