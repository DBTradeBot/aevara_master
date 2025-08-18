import 'package:flutter/material.dart';
import '../data/mock_community_data.dart';

class RecentEventTile extends StatelessWidget {
  final RecentEvent event;
  const RecentEventTile({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final rel = _relative(event.when);
    return ListTile(
      leading: Text(event.emoji, style: const TextStyle(fontSize: 20)),
      title: Text(event.text, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(rel),
    );
  }

  String _relative(DateTime when) {
    final now = DateTime.now();
    final diff = now.difference(when);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
