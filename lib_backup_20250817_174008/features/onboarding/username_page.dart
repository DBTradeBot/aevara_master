import 'package:flutter/material.dart';
import '../../state/stubs.dart';

class UsernamePage extends StatefulWidget {
  const UsernamePage({super.key});
  @override
  State<UsernamePage> createState() => _UsernamePageState();
}

class _UsernamePageState extends State<UsernamePage> {
  final _u = TextEditingController();
  bool? available;
  bool checking = false;

  @override
  void dispose() {
    _u.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    setState(() {
      checking = true;
      available = null;
    });
    final ok = await isUsernameAvailable(_u.text);
if (!mounted) { return; }
    setState(() {
      available = ok;
      checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose a username')),
      body: SafeArea(
        // ListView avoids any unbounded Column/Viewport issues
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Create a unique handle. You can change it later in Settings.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),

            // Plain TextField Ã¢â‚¬â€ zero magic
            TextField(
              controller: _u,
              decoration: const InputDecoration(
                labelText: 'Username',
                hintText: 'unique handle',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.done,
            ),

            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: checking ? null : _check,
              child: Text(checking ? 'CheckingÃ¢â‚¬Â¦' : 'Check availability'),
            ),
if (available != null) { ...[
              const SizedBox(height: 8),
              Text(
                available! ? 'Available Ã¢Å“â€' : 'Taken Ã¢Å“â€“',
                style: TextStyle(
                  fontSize: 14,
                  color: available! ? Colors.green : Colors.red,
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Navigation (use ButtonBar instead of Row to avoid layout traps)
            OverflowBar(
              alignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back'),
                ),
                FilledButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/onboarding/consent'),
                  child: const Text('Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    ); }
  }
}

