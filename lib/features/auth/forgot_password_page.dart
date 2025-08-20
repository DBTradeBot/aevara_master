import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/widgets/dev_fab_navigator.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});
  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _email = TextEditingController();
  String? _info;

  Future<void> _send() async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: _email.text.trim());
      setState(() => _info = 'Email sent. Check your inbox.');
    } catch (e) {
      setState(() => _info = 'Failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: const DevFabNavigator(),
      appBar: AppBar(title: const Text('Forgot Password')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text("We'll send you an email with a link to reset your password."),
            const SizedBox(height: 12),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Your email address...'),
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: _send, child: const Text('Send Link')),
            const Spacer(),
            if (_info != null) Text(_info!),
          ],
        ),
      ),
    );
  }
}
