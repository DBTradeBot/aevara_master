import 'package:flutter/material.dart';

class PrimarySubmitButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool loading;
  const PrimarySubmitButton({super.key, required this.label, required this.onPressed, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : Text(label),
    );
  }
}
