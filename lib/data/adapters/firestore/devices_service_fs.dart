import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/devices_service.dart';
import '../../../core/widgets/tiles/sync_status_dot.dart';

/// Firestore-backed adapter.
/// Reads: integrations/{provider}/users/{uid}
/// Required schema per doc:
///   connected: bool
///   last_status: 'ok' | 'error' | ...
///   last_sync_utc: ISO string (UTC)
class DevicesServiceFs implements DevicesService {
  DevicesServiceFs({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const List<String> _providers = <String>[
    'apple', 'fitbit', 'oura', 'garmin', 'whoop', 'googlefit',
  ];

  @override
  Future<Map<String, SyncStatus>> fetchStatuses(String uid) async {
    if (uid.isEmpty) return <String, SyncStatus>{};

    final out = <String, SyncStatus>{};

    try {
      final futures = _providers
          .map((p) => _db.doc('integrations/$p/users/$uid').get())
          .toList();
      final snaps = await Future.wait(futures);

      for (var i = 0; i < snaps.length; i++) {
        final provider = _providers[i];
        final snap = snaps[i];

        if (!snap.exists) {
          out[provider] = SyncStatus.none; // never set up
          continue;
        }

        final d = snap.data() ?? const {};
        final bool connected = d['connected'] == true;
        final String status = (d['last_status'] ?? '').toString().toLowerCase();
        final String iso = (d['last_sync_utc'] ?? '').toString();

        SyncStatus s;
        if (!connected) {
          s = SyncStatus.disconnected;
        } else if (status != 'ok') {
          s = SyncStatus.stale; // linked but errored
        } else if (iso.isEmpty) {
          s = SyncStatus.stale; // linked but no data yet
        } else {
          final dt = DateTime.tryParse(iso);
          if (dt == null) {
            s = SyncStatus.stale;
          } else {
            final ageH = DateTime.now().toUtc().difference(dt.toUtc()).inHours;
            s = (ageH <= 36) ? SyncStatus.connected : SyncStatus.stale;
          }
        }

        out[provider] = s;
      }
    } on FirebaseException {
      // Fail closed (treat as none) on permission or other FS errors
      for (final p in _providers) {
        out[p] = SyncStatus.none;
      }
    } catch (_) {
      for (final p in _providers) {
        out[p] = SyncStatus.none;
      }
    }

    return out;
  }

  // ---- These two are REQUIRED by your abstract DevicesService ----

  @override
  SyncStatus reduceTopLevel(Map<String, SyncStatus> byProvider) {
    if (byProvider.isEmpty) return SyncStatus.none;
    final vals = byProvider.values;
    if (vals.contains(SyncStatus.connected)) return SyncStatus.connected;
    if (vals.contains(SyncStatus.stale)) return SyncStatus.stale;
    if (vals.contains(SyncStatus.disconnected)) return SyncStatus.disconnected;
    return SyncStatus.none;
  }

  @override
  String tooltipFor(SyncStatus status, Map<String, SyncStatus> byProvider) {
    final providers = byProvider.entries
        .map((e) => '${e.key}: ${switch (e.value) {
      SyncStatus.connected => "connected",
      SyncStatus.stale => "stale",
      SyncStatus.disconnected => "disconnected",
      SyncStatus.none => "not set up",
    }}')
        .join(' • ');

    final base = switch (status) {
      SyncStatus.connected    => 'Connected — data is up to date',
      SyncStatus.stale        => 'Stale — some data may be out of date',
      SyncStatus.disconnected => 'Disconnected — no recent sync',
      SyncStatus.none         => 'Not connected — connect a device',
    };

    return providers.isEmpty ? base : '$base\n$providers';
  }
}
