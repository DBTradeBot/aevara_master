// Minimal RemoteConfig stub using in-memory defaults.
// You can swap to Firebase Remote Config later without changing callers.

class RemoteConfigService {
  RemoteConfigService._();
  static final RemoteConfigService instance = RemoteConfigService._();

  final Map<String, dynamic> _defaults = <String, dynamic>{
    // Example flags:
    'devices_page_enabled': true,
    'fitbit_connect_enabled': true,
  };

  Future<void> init() async {
    // no-op for stub
  }

  T get<T>(String key, {required T defaultValue}) {
    final v = _defaults[key];
    if (v == null) return defaultValue;
    if (v is T) return v;
    return defaultValue;
  }

  // Allow overriding in debug/dev sessions:
  void set<T>(String key, T value) {
    _defaults[key] = value;
  }
}
