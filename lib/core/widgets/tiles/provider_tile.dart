import 'package:flutter/material.dart';
import '../../../theme/icons.dart';
import '../../../core/widgets/tiles/sync_status_dot.dart';

class ProviderTile extends StatelessWidget {
  const ProviderTile({
    super.key,
    required this.title,
    required this.providerId,
    this.subtitle,
    this.asset,
    this.accentColor,
    this.status = SyncStatus.none,
    this.onTap,
  });

  final String title;
  final String providerId;
  final String? subtitle;
  final String? asset;
  final Color? accentColor;
  final SyncStatus status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AevaraBrandIcons.colorFor(providerId);
    final icon = AevaraBrandIcons.fallbackIconFor(providerId);
    final imgPath = asset ?? AevaraBrandIcons.assetFor(providerId);

    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            imgPath,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Icon(icon, color: color),
          ),
        ),
      ),
      title: Text(title),
      subtitle: (subtitle != null && subtitle!.isNotEmpty) ? Text(subtitle!) : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SyncStatusDot(status: status, size: 12),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}
