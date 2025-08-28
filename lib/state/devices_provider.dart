import 'package:aevara/data/contracts/firestore_contracts_v1.dart' as Fx;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/widgets/tiles/sync_status_dot.dart';
import '../data/services/devices_service.dart';
import '../data/adapters/firestore/devices_service_fs.dart';
import 'user_providers.dart'; // currentUserIdProvider

final devicesServiceProvider = Provider<DevicesService>((ref) {
  return DevicesServiceFs(db: FirebaseFirestore.instance);
});

final deviceStatusProvider = FutureProvider<Map<String, SyncStatus>>((ref) async {
  final uid = ref.watch(currentUserIdProvider);
  final svc = ref.watch(devicesServiceProvider);
  if (uid == null || uid.isEmpty) return <String, SyncStatus>{};
  return svc.fetchStatuses(uid);
});

/// => AsyncValue<SyncStatus>
final topLevelSyncStatusProvider = Provider<AsyncValue<SyncStatus>>((ref) {
  final svc = ref.watch(devicesServiceProvider);
  final mapA = ref.watch(deviceStatusProvider);
  return mapA.whenData((map) => svc.reduceTopLevel(map));
});

/// => AsyncValue<String>
final topLevelSyncTooltipProvider = Provider<AsyncValue<String>>((ref) {
  final svc = ref.watch(devicesServiceProvider);
  final mapA = ref.watch(deviceStatusProvider);
  final statusA = ref.watch(topLevelSyncStatusProvider);
  return statusA.whenData((s) {
    final map = mapA.value ?? const <String, SyncStatus>{};
    return svc.tooltipFor(s, map);
  });
});


