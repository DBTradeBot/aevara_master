import 'package:flutter/material.dart';
import '../../widgets/atoms/aev_text_field.dart';
import '../../widgets/atoms/aev_button.dart';
import '../../state/stubs.dart';

class ProfileMePage extends StatefulWidget {
  const ProfileMePage({super.key});

  @override
  State<ProfileMePage> createState() => _ProfileMePageState();
}

class _ProfileMePageState extends State<ProfileMePage> {
  final _display = TextEditingController(text: 'Dan');
  final _bio = TextEditingController();
  final _username = TextEditingController(text: 'dan');
  bool? available;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 28, child: Icon(Icons.person_outline)),
              const SizedBox(width: 12),
              Expanded(child: AevTextField(controller: _display, label: 'Display name')),
            ],
          ),
          const SizedBox(height: 12),
          AevTextField(controller: _bio, label: 'Bio', hint: 'Tell people about you'),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: AevTextField(controller: _username, label: 'Username')),
            const SizedBox(width: 8),
            OutlinedButton(onPressed: () async {
              available = await isUsernameAvailable(_username.text);
              setState((){});
            }, child: const Text('Check')),
          ]),
          if (available != null) Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(available! ? 'Available âœ”' : 'Taken âœ–', style: TextStyle(color: available!? Colors.green : Colors.red)),
          ),
          const SizedBox(height: 24),
          Text('Demographics', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Wrap(spacing: 8, children: [
            Chip(label: Text('Gender: edit from Settings')),
            Chip(label: Text('Height/Weight: edit from Settings')),
          ]),
          const SizedBox(height: 24),
          AevButton.primary('Save', onPressed: (){
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved (stub).')));
          }),
        ],
      ),
    );
  }
}
