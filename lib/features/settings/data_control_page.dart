import 'package:flutter/material.dart';

class DataControlPage extends StatelessWidget {
  const DataControlPage({super.key});

  Future<void> _confirm(BuildContext context, String title, String body) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Confirm')),
        ],
      ),
    );
    if (ok == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$title requested (stub)')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Revoke sync / Delete data')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.sync_disabled_outlined),
            title: const Text('Revoke device sync'),
            subtitle: const Text('Disconnect all providers'),
            onTap: () => _confirm(
              context,
              'Revoke sync',
              'This will disconnect all providers. You can reconnect later.',
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Delete all data'),
            subtitle: const Text('This action is irreversible'),
            onTap: () => _confirm(
              context,
              'Delete all data',
              'Are you sure? This cannot be undone.',
            ),
          ),
        ),
      ],
    ),
  );
}
