import 'package:flutter/material.dart';

/// Returns a list of selected friend names when closed with "Invite".
Future<List<String>?> showChallengeInviteSheet(
    BuildContext context, {
      required String challengeTitle,
    }) {
  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => _InviteSheet(challengeTitle: challengeTitle),
  );
}

class _InviteSheet extends StatefulWidget {
  final String challengeTitle;
  const _InviteSheet({required this.challengeTitle});

  @override
  State<_InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends State<_InviteSheet> {
  final List<String> _friends = const [
    'Alex Kim', 'Sam Lee', 'Jordan P.', 'Casey R.', 'Taylor S.',
    'Morgan A.', 'Riley T.', 'Jamie C.', 'Quinn H.', 'Avery N.'
  ];
  final Set<String> _selected = {};
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final filtered = _friends
        .where((n) => n.toLowerCase().contains(_q.toLowerCase()))
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
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
          Text('Invite friends to', style: Theme.of(context).textTheme.labelLarge),
          Text(widget.challengeTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search friends',
            ),
            onChanged: (v) => setState(() => _q = v),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final n = filtered[i];
                final sel = _selected.contains(n);
                return CheckboxListTile(
                  value: sel,
                  onChanged: (_) =>
                      setState(() => sel ? _selected.remove(n) : _selected.add(n)),
                  title: Text(n),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: _selected.isEmpty
                      ? null
                      : () => Navigator.pop(context, _selected.toList()),
                  child: const Text('Invite'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
