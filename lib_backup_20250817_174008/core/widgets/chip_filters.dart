// ignore_for_file: avoid_renaming_method_parameters
import 'package:flutter/material.dart';

class ChipFilters extends StatefulWidget {
  final List<String> labels;
  final ValueChanged<Set<String>>? onChanged;
  const ChipFilters({super.key, required this.labels, this.onChanged});
  @override
  State<ChipFilters> createState() => _ChipFiltersState();
}

class _ChipFiltersState extends State<ChipFilters> {
  final Set<String> selected = {};
  @override
  Widget build(BuildContext c) => Wrap(
      spacing: 8,
      children: widget.labels.map((l) {
        final sel = selected.contains(l);
        return FilterChip(
            label: Text(l),
            selected: sel,
            onSelected: (b) {
              setState(() => b ? selected.add(l) : selected.remove(l));
              widget.onChanged?.call(selected);
            });
      }).toList());
}
