import 'package:flutter/material.dart';

class ParticipantAvatarsRow extends StatelessWidget {
  final Iterable<String> names;
  final int maxVisible;

  const ParticipantAvatarsRow({
    super.key,
    required this.names,
    this.maxVisible = 5,
  });

  @override
  Widget build(BuildContext context) {
    final list = names.toList();
    if (list.isEmpty) {
      return Text(
        'Be the first to join',
        style: Theme.of(context).textTheme.labelSmall,
      );
    }

    final visible = list.take(maxVisible).toList();
    final overflow = list.length - visible.length;

    return Row(
      children: [
        ...visible.map((n) => _Avatar(name: n)),
if (overflow > 0) { ...[
          const SizedBox(width: 6),
          CircleAvatar(
            radius: 12,
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Text(
              '+$overflow',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ],
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _label(list),
            style: Theme.of(context).textTheme.labelSmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ); }
  }

  String _label(List<String> list) {
if (list.length == 1) { return '${list.first} is in'; }
if (list.length == 2) { return '${list[0]}, ${list[1]} are in'; }
    return '${list[0]}, ${list[1]} + ${list.length - 2} more are in';
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  const _Avatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final initials = _initials(name);
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: CircleAvatar(
        radius: 12,
        backgroundColor: cs.secondaryContainer,
        child: Text(
          initials,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  String _initials(String n) {
    final parts = n.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return (parts[0].isEmpty ? '' : parts[0][0]) +
          (parts[1].isEmpty ? '' : parts[1][0]);
    }
    return n.isEmpty ? '?' : n[0].toUpperCase();
  }
}

