import 'package:flutter/material.dart';

class OauthGoogleButton extends StatelessWidget {
  final VoidCallback onPressed;
  const OauthGoogleButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.g_mobiledata),
      label: const Text('Continue with Google'),
      onPressed: onPressed,
    );
  }
}
