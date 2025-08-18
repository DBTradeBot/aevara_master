import 'dart:convert';

/// Fixes mojibake like 'ðŸ˜Š' by interpreting the current string's bytes
/// as Latin-1 and decoding them as UTF-8. Non-garbled text passes through.
String fixMojibake(String s) {
  try {
    final bytes = latin1.encode(s);
    return utf8.decode(bytes, allowMalformed: true);
  } catch (_) {
    return s;
  }
}
