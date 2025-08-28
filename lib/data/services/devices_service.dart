import '../../core/widgets/tiles/sync_status_dot.dart';

/// Service contract for reading per-provider sync state and deriving a
/// top-level status + user-facing tooltip.
abstract class DevicesService {
  /// Returns a map of provider->SyncStatus for the given user.
  Future<Map<String, SyncStatus>> fetchStatuses(String uid);

  /// Priority rule: connected > stale > disconnected > none.
  SyncStatus reduceTopLevel(Map<String, SyncStatus> byProvider) {
    if (byProvider.isEmpty) return SyncStatus.none;
    if (byProvider.values.any((s) => s == SyncStatus.connected)) return SyncStatus.connected;
    if (byProvider.values.any((s) => s == SyncStatus.stale)) return SyncStatus.stale;
    if (byProvider.values.any((s) => s == SyncStatus.disconnected)) return SyncStatus.disconnected;
    return SyncStatus.none;
  }

  /// Human tooltip for the top-left dot.
  String tooltipFor(SyncStatus status, Map<String, SyncStatus> byProvider) {
    final providers = byProvider.entries.map((e) => '${e.key}: ${_label(e.value)}').join(' • ');
    final base = switch (status) {
      SyncStatus.connected    => 'Connected — data is up to date',
      SyncStatus.stale        => 'Stale — some data may be out of date',
      SyncStatus.disconnected => 'Disconnected — no recent sync',
      SyncStatus.none         => 'Not connected — connect a device',
    };
    return providers.isEmpty ? base : '$base\n$providers';
  }

  String _label(SyncStatus s) => switch (s) {
    SyncStatus.connected => 'connected',
    SyncStatus.stale => 'stale',
    SyncStatus.disconnected => 'disconnected',
    SyncStatus.none => 'not set up',
  };
}
