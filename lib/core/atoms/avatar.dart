<<<<<<< Updated upstream
﻿// ignore_for_file: avoid_renaming_method_parameters
=======
// ignore_for_file: avoid_renaming_method_parameters
>>>>>>> Stashed changes
import 'package:flutter/material.dart';

class Avatar extends StatelessWidget {
  final double size;
  const Avatar({super.key, this.size = 40});
  @override
  Widget build(BuildContext c) =>
      CircleAvatar(radius: size / 2, child: const Icon(Icons.person));
}
<<<<<<< Updated upstream

=======
>>>>>>> Stashed changes
