<<<<<<< Updated upstream
﻿// ignore_for_file: avoid_renaming_method_parameters
=======
// ignore_for_file: avoid_renaming_method_parameters
>>>>>>> Stashed changes
import 'package:flutter/material.dart';

class Avatar extends StatelessWidget {
  final double size;
  final String? url;
  const Avatar({super.key, this.size = 40, this.url});
  @override
  Widget build(BuildContext c) => CircleAvatar(
      radius: size / 2,
      backgroundImage: url != null ? NetworkImage(url!) : null,
      child: url == null ? const Icon(Icons.person) : null);
}
<<<<<<< Updated upstream

=======
>>>>>>> Stashed changes
