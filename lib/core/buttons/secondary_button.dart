<<<<<<< Updated upstream
﻿// ignore_for_file: avoid_renaming_method_parameters
=======
// ignore_for_file: avoid_renaming_method_parameters
>>>>>>> Stashed changes
import 'package:flutter/material.dart';

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const SecondaryButton({super.key, required this.label, this.onPressed});
  @override
  Widget build(BuildContext c) =>
      OutlinedButton(onPressed: onPressed, child: Text(label));
}
<<<<<<< Updated upstream

=======
>>>>>>> Stashed changes
