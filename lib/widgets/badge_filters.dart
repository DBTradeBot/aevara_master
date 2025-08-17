
import 'package:flutter/material.dart';

const categories = [
  'All','Sleep','Steps','Heart','Mood','Nutrition','Mindfulness','Challenges','Special'
];

class TierFilterBar extends StatelessWidget {
  final String selectedTier;
  final ValueChanged<String> onChanged;
  const TierFilterBar({super.key, required this.selectedTier, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final tiers = ['All','Bronze','Silver','Gold','Platinum','Diamond'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: tiers.map((t) {
          final selected = t == selectedTier;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(t),
              selected: selected,
              onSelected: (_) => onChanged(t),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class CategoryChips extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const CategoryChips({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: categories.map((c) {
          final selectedC = c == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(c),
              selected: selectedC,
              onSelected: (_) => onChanged(c),
            ),
          );
        }).toList(),
      ),
    );
  }
}
