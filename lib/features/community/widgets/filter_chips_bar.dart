import 'package:flutter/material.dart';

class FilterChipsBar extends StatelessWidget {
  final List<String> options;
  final String selected;
  final void Function(String) onChanged;
  final String? label;
  const FilterChipsBar({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
<<<<<<< Updated upstream
        if (label != null)
          Text(label!, style: Theme.of(context).textTheme.labelLarge),
=======
if (label != null) Text(label!, style: Theme.of(context).textTheme.labelLarge),
>>>>>>> Stashed changes
        for (final o in options)
          ChoiceChip(
            label: Text(o),
            selected: selected == o,
            onSelected: (_) => onChanged(o),
          ),
      ],
    )
  }
}


