import 'package:flutter/material.dart';

/// Returns the list of picked handles (e.g. ['@mia', '@sam']) or null if canceled.
Future<List<String>?> showChallengeInviteSheet(
    BuildContext context, {
      String? challengeTitle,
    }) {
  // Simple mock list — swap with your friends list later
  final friends = const [
    '@alex', '@mia', '@sam', '@li', '@ron', '@jordan', '@kira'
  ];
  final selected = <String>{};

  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: Colors.black12, borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            challengeTitle == null ? 'Invite friends' : 'Invite friends to “$challengeTitle”',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: friends.length,
              separatorBuilder: (_, __) => const Divider(height: 0),
              itemBuilder: (_, i) {
                final f = friends[i];
                final checked = selected.contains(f);
                return ListTile(
                  leading: CircleAvatar(child: Text(f.replaceAll('@', '').substring(0,1).toUpperCase())),
                  title: Text(f),
                  trailing: Checkbox(
                    value: checked,
                    onChanged: (v) {
                      if (v == true) {
                        selected.add(f);
                      } else {
                        selected.remove(f);
                      }
                    },
                  ),
                  onTap: () {
                    if (checked) {
                      selected.remove(f);
                    } else {
                      selected.add(f);
                    }
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: selected.isEmpty
                      ? null
                      : () => Navigator.pop(context, selected.toList()),
                  child: const Text('Send invites'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
