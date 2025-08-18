// ignore_for_file: avoid_renaming_method_parameters
import 'package:flutter/material.dart';

class PickerRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const PickerRow(
      {super.key,
      required this.label,
      required this.value,
      required this.onTap});
  @override
  Widget build(BuildContext c) => ListTile(
      title: Text(label),
      subtitle: Text(value),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap);
}

