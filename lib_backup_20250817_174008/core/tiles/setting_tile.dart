// ignore_for_file: avoid_renaming_method_parameters
import 'package:flutter/material.dart';

class SettingTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  const SettingTile(
      {super.key, required this.title, this.subtitle, this.onTap});
  @override
  Widget build(BuildContext c) => ListTile(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap);
}
