<<<<<<< Updated upstream
﻿// ignore_for_file: avoid_renaming_method_parameters
=======
// ignore_for_file: avoid_renaming_method_parameters
>>>>>>> Stashed changes
import 'package:flutter/material.dart';
import '../atoms/avatar.dart';

class HeroHeaderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  const HeroHeaderCard(
      {super.key, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext c) => Card(
      child: ListTile(
          leading: const Avatar(),
          title: Text(title),
          subtitle: Text(subtitle)));
}
<<<<<<< Updated upstream

=======
>>>>>>> Stashed changes
