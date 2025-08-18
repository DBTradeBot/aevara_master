<<<<<<< Updated upstream
﻿// ignore_for_file: avoid_renaming_method_parameters
=======
// ignore_for_file: avoid_renaming_method_parameters
>>>>>>> Stashed changes
import 'package:flutter/material.dart';

class DividerText extends StatelessWidget {
  final String text;
  const DividerText(this.text, {super.key});
  @override
  Widget build(BuildContext c) => Row(children: [
        const Expanded(child: Divider()),
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(text)),
        const Expanded(child: Divider())
      ]);
}
<<<<<<< Updated upstream

=======
>>>>>>> Stashed changes
