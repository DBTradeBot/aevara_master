import 'package:flutter/material.dart';

/// Minimal app state stubs (no backend). Replace later with real providers/BLoC/etc.
class AppState extends ChangeNotifier {
  bool connected = false;
  void toggleConnected() {
    connected = !connected;
    notifyListeners();
  }
}

final appState = AppState();

/// Username availability: mock check (reject 'taken')
Future<bool> isUsernameAvailable(String name) async {
  await Future.delayed(const Duration(milliseconds: 300));
  return name.trim().toLowerCase() != 'taken';
}
