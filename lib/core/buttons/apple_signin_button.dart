<<<<<<< Updated upstream
﻿// ignore_for_file: avoid_renaming_method_parameters
=======
// ignore_for_file: avoid_renaming_method_parameters
>>>>>>> Stashed changes
import 'package:flutter/material.dart';

class AppleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  const AppleSignInButton(
      {super.key, this.onPressed, this.label = 'Continue with Apple'});
  @override
  Widget build(BuildContext c) => OutlinedButton.icon(
      onPressed: onPressed, icon: const Icon(Icons.apple), label: Text(label));
}
<<<<<<< Updated upstream

=======
>>>>>>> Stashed changes
