// lib/core/widgets/toast.dart
import 'package:flutter/material.dart';

class AppToast {
  static void show(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(message),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  static void success(BuildContext context, String message) =>
      show(context, message);
  static void error(BuildContext context, String message) =>
      show(context, message);
}
