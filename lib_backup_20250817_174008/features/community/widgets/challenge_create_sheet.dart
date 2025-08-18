import 'package:flutter/material.dart';

/// Bottom sheet to create a new challenge (mock/local only).
/// Returns a Map with: { title, category, days, friendsOnly }
Future<Map<String, Object>?> showChallengeCreateSheet(BuildContext context) {
  return showModalBottomSheet<Map<String, Object>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => const _CreateSheet(),
  );
}

class _CreateSheet extends StatefulWidget {
  const _CreateSheet();

  @override
  State<_CreateSheet> createState() => _CreateSheetState();
}

class _CreateSheetState extends State<_CreateSheet> {
  final _title = TextEditingController();
  String _category = 'Steps';
  int _days = 7;
  bool _friendsOnly = true;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets;
    return Padding(
      padding: EdgeInsets.only(bottom: insets.bottom),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('Create challenge',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextField(
                controller: _title,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g., 10k steps daily',
                ),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _category,
                items: const [
                  DropdownMenuItem(value: 'Steps', child: Text('Steps')),
                  DropdownMenuItem(value: 'Sleep', child: Text('Sleep')),
                  DropdownMenuItem(value: 'HRV', child: Text('HRV')),
                  DropdownMenuItem(
                      value: 'Mindfulness', child: Text('Mindfulness')),
                ],
                onChanged: (v) => setState(() => _category = v ?? 'Steps'),
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _days.toDouble(),
                      min: 3,
                      max: 30,
                      divisions: 27,
                      label: '$_days days',
                      onChanged: (v) => setState(() => _days = v.round()),
                    ),
                  ),
                  SizedBox(
                    width: 64,
                    child: Text('$_days d', textAlign: TextAlign.end),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                value: _friendsOnly,
                onChanged: (v) => setState(() => _friendsOnly = v),
                title: const Text('Friends only'),
                contentPadding: EdgeInsets.zero,
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
                      onPressed: () {
                        final t = _title.text.trim();
                        if (t.isEmpty) {
                          return;
                        }
                        Navigator.pop<Map<String, Object>>(context, {
                          'title': t,
                          'category': _category,
                          'days': _days,
                          'friendsOnly': _friendsOnly,
                        });
                      },
                      child: const Text('Create'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
