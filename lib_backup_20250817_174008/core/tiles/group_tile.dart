// ignore_for_file: avoid_renaming_method_parameters
import 'package:flutter/material.dart';

class GroupTile extends StatelessWidget {
  final String name;
  final String members;
  final VoidCallback? onTap;
  const GroupTile(
      {super.key, required this.name, required this.members, this.onTap});
  @override
  Widget build(BuildContext c) => ListTile(
      leading: const Icon(Icons.group),
      title: Text(name),
      subtitle: Text(members),
      onTap: onTap);
}
