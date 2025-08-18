import 'package:flutter/material.dart';

class DevicesPage extends StatefulWidget {
  const DevicesPage({super.key});

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  final _map = <String, bool>{
    'Apple Health': true,
    'Google Fit': false,
    'Fitbit': true,
    'WHOOP': true,
    'Garmin': false,
    'Oura': true,
    'Polar': false,
  };

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Connected devices')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final entry in _map.entries) ...[
              SwitchListTile(
                title: Text(entry.key),
                value: entry.value,
                onChanged: (v) => setState(() => _map[entry.key] = v),
                secondary: const Icon(Icons.watch_outlined),
                subtitle: Text(entry.value ? 'Connected' : 'Disconnected'),
              ),
              const Divider(height: 1),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Device settings saved (stub)')),
              ),
              child: const Text('Save changes'),
            ),
          ],
        ),
      );
}
