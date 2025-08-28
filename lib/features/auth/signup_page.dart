import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'components/auth_email_field.dart';
import 'components/auth_password_field.dart';
import 'components/oauth_google_button.dart';
import 'components/auth_alt_links_row.dart';
import 'components/submit_buttons.dart';
import '../../routing/route_paths.dart';
import '../../core/widgets/dev_fab_navigator.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _doSignup() async {
    if (_pass.text != _confirm.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _email.text.trim(), password: _pass.text);
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      if (mounted) Navigator.pushReplacementNamed(context, RoutePaths.verify);
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      floatingActionButton: const DevFabNavigator(),
      appBar: AppBar(title: const Text('Create an account')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  AuthEmailField(controller: _email),
                  const SizedBox(height: 12),
                  AuthPasswordField(controller: _pass),
                  const SizedBox(height: 12),
                  AuthPasswordField(
                      controller: _confirm, label: 'Confirm Password'),
                  const SizedBox(height: 16),
                  PrimarySubmitButton(
                      label: 'Create Account',
                      onPressed: _doSignup,
                      loading: _loading),
                  const SizedBox(height: 12),
                  Center(child: Text('OR', style: theme.textTheme.labelMedium)),
                  const SizedBox(height: 12),
                  OauthGoogleButton(onPressed: () {}),
                  const SizedBox(height: 12),
                  const AuthAltLinksRow(isSignin: false),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.error)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
