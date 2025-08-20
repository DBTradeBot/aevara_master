// lib/features/auth/components/auth_alt_links_row.dart
import 'package:flutter/material.dart';
import '../../../routing/route_paths.dart';

class AuthAltLinksRow extends StatelessWidget {
  final bool isSignin;
  const AuthAltLinksRow({super.key, required this.isSignin});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      children: [
        TextButton(
          onPressed: () =>
              Navigator.of(context).pushNamed(isSignin ? RoutePaths.signup : RoutePaths.signin),
          child: Text(isSignin ? 'Create account' : 'Have an account? Sign in'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pushNamed(RoutePaths.forgot),
          child: const Text('Forgot password'),
        ),
      ],
    );
  }
}
