// lib/core/utils/validators.dart
class Validators {
  static String? requiredField(String? v, {String label = 'This field'}) {
    if (v == null || v.trim().isEmpty) return '$label is required';
    return null;
  }

  static final _handleRe = RegExp(r'^[a-z0-9_.]{3,20}$');

  static bool usernameFormatOk(String raw) {
    final s = raw.trim().replaceFirst(RegExp(r'^@'), '').toLowerCase();
    return _handleRe.hasMatch(s);
  }

  static String normalizeHandle(String raw) =>
      raw.trim().replaceFirst(RegExp(r'^@'), '');
}
