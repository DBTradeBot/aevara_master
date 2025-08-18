<<<<<<< Updated upstream
﻿// ignore_for_file: avoid_renaming_method_parameters
=======
// ignore_for_file: avoid_renaming_method_parameters
>>>>>>> Stashed changes
import 'package:flutter/material.dart';

class BadgeCard extends StatelessWidget {
  final String title;
  final String detail;
  final VoidCallback? onTap;
  const BadgeCard(
      {super.key, required this.title, required this.detail, this.onTap});
  @override
  Widget build(BuildContext c) => Card(
      child: ListTile(
          leading: const Icon(Icons.emoji_events_outlined),
          title: Text(title),
          subtitle: Text(detail),
          onTap: onTap));
}
<<<<<<< Updated upstream

=======
>>>>>>> Stashed changes
