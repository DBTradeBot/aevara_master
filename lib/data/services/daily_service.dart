// Abstract interface for reading/writing the daily doc.
// ✅ Canonical path: users/{uid}/days/{YYYY-MM-DD}

abstract class DailyService {
  /// Returns today's document data or null if none (adapter may create a stub).
  Future<Map<String, dynamic>?> getToday(String uid);

  /// Merge-patches today's document; adapter stamps updated_at server time.
  Future<void> setToday(String uid, Map<String, dynamic> patch);
}
