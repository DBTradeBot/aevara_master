// ignore_for_file: avoid_renaming_method_parameters
import 'package:flutter/material.dart';

class ToggleRow extends StatefulWidget {
  final String label;
  final bool initial;
  final ValueChanged<bool>? onChanged;
  const ToggleRow(
      {super.key, required this.label, this.initial = false, this.onChanged});
  @override
  State<ToggleRow> createState() => _ToggleRowState();
}

class _ToggleRowState extends State<ToggleRow> {
  late bool v;
  @override
  void initState() {
    v = widget.initial;
    super.initState();
  }

  @override
  Widget build(BuildContext c) => ListTile(
      title: Text(widget.label),
      trailing: Switch(
          value: v,
          onChanged: (b) {
            setState(() => v = b);
            widget.onChanged?.call(b);
          }));
}

