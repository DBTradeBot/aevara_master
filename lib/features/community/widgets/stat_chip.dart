import 'package:flutter/material.dart';

class StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const StatChip({super.key, required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}
