<<<<<<< Updated upstream
﻿// ignore_for_file: avoid_renaming_method_parameters
=======
// ignore_for_file: avoid_renaming_method_parameters
>>>>>>> Stashed changes
import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const PrimaryButton({super.key, required this.label, this.onPressed});
  @override
  Widget build(BuildContext c) =>
      FilledButton(onPressed: onPressed, child: Text(label));
}
<<<<<<< Updated upstream

=======
>>>>>>> Stashed changes
