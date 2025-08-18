// ignore_for_file: avoid_renaming_method_parameters
import 'package:flutter/material.dart';

class FeedItemTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onCheer;
  const FeedItemTile(
      {super.key, required this.title, required this.subtitle, this.onCheer});
  @override
  Widget build(BuildContext c) => ListTile(
      leading: const Icon(Icons.bolt_outlined),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: IconButton(
          icon: const Icon(Icons.favorite_border), onPressed: onCheer));
}

