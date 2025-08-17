import 'package:flutter/material.dart';

class ParticipantAvatarsRow extends StatelessWidget {
  final List<String> names;
  const ParticipantAvatarsRow({super.key, required this.names});

  @override
  Widget build(BuildContext context) {
    final shown = names.take(5).toList();
    final extra = names.length - shown.length;

    return Row(
      children: [
        ...shown.map((n) {
          final t = _initials(n);
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: CircleAvatar(
              radius: 12,
              child: Text(t, style: const TextStyle(fontSize: 11)),
            ),
          );
        }),
        if (extra > 0)
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text('+$extra', style: Theme.of(context).textTheme.labelSmall),
          ),
      ],
    );
  }

  String _initials(String handleOrName) {
    // handle like “@alex” -> A, “Alex Kim” -> AK
    final s = handleOrName.replaceAll('@', '').trim();
    if (s.isEmpty) return '?';
    final parts = s.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }
}
