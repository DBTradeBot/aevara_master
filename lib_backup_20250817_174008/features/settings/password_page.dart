import 'package:flutter/material.dart';

class PasswordPage extends StatefulWidget {
  const PasswordPage({super.key});

  @override
  State<PasswordPage> createState() => _PasswordPageState();
}

class _PasswordPageState extends State<PasswordPage> {
  final _old = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool showOld = false, showNew = false, showConfirm = false;

  @override
  void dispose() {
    _old.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Change Password')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _old,
              obscureText: !showOld,
              decoration: InputDecoration(
                labelText: 'Current password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(showOld ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => showOld = !showOld),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _new,
              obscureText: !showNew,
              decoration: InputDecoration(
                labelText: 'New password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(showNew ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => showNew = !showNew),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirm,
              obscureText: !showConfirm,
              decoration: InputDecoration(
                labelText: 'Confirm new password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                      showConfirm ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => showConfirm = !showConfirm),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                if (_new.text != _confirm.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Passwords do not match')),
                  );
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password changed (stub)')),
                );
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
}
