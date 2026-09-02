import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/tiles/sync_status_dot.dart';
import '../../../theme/icons.dart';

/// Compact, list-friendly tile to show a provider, status, and a primary CTA.
///
/// Use in Settings → Devices; for bigger grid cards, see DeviceCard.
class ProviderTile extends StatelessWidget {
  final String providerId;     // e.g., "fitbit"
  final String title;          // e.g., "Fitbit"
  final SyncStatus status;
  final DateTime? lastSyncUtc;
  final bool comingSoon;
  final bool localStore;
  final VoidCallback? onConnect;
  final VoidCallback? onManage;

  const ProviderTile({
    super.key,
    required this.providerId,
    required this.title,
    required this.status,
    this.lastSyncUtc,
    this.comingSoon = false,
    this.localStore = false,
    this.onConnect,
    this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = _subtitle();
    final isConnected = status == SyncStatus.connected || status == SyncStatus.stale;
    final primaryLabel = comingSoon
        ? 'Coming soon'
        : (isConnected ? 'Manage' : (localStore ? 'Enable' : 'Connect'));

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: _leadingLogo(),
        title: Row(
          children: [
            Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
            SyncStatusDot(status: status, size: 10),
          ],
        ),
        subtitle: subtitle == null ? null : Text(subtitle),
        trailing: TextButton(
          onPressed: comingSoon ? null : (isConnected ? onManage : onConnect),
          child: Text(primaryLabel),
        ),
        onTap: comingSoon ? null : (isConnected ? onManage : onConnect),
      ),
    );
  }

  Widget _leadingLogo() {
    final asset = AevaraBrandIcons.assetFor(providerId);
    final color = AevaraBrandIcons.colorFor(providerId);
    return CircleAvatar(
      backgroundColor: color.withOpacity(0.12),
      child: ClipOval(
        child: Image.asset(
          asset,
          width: 22,
          height: 22,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) {
            return Icon(AevaraBrandIcons.fallbackIconFor(providerId), color: color, size: 20);
          },
        ),
      ),
    );
  }

  String? _subtitle() {
    if (comingSoon) return 'Not yet available';
    if (status == SyncStatus.none) return 'Not connected';
    if (status == SyncStatus.disconnected) return 'Disconnected';
    if (lastSyncUtc == null) return 'Connected';
    final ago = DateTime.now().toUtc().difference(lastSyncUtc!);
    final fmt = DateFormat('MMM d, h:mm a').format(lastSyncUtc!.toLocal());
    if (ago.inHours < 24) return 'Last synced $fmt';
    return 'Last sync $fmt';
  }
}
