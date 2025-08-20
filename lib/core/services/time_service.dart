// lib/core/services/time_service.dart
// Local "today" helpers; formats YYYY-MM-DD using local time.

class TimeService {
  TimeService._();
  static final TimeService instance = TimeService._();

  /// e.g., 2025-08-19
  String todayKey({DateTime? now}) {
    final dt = now ?? DateTime.now();
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
