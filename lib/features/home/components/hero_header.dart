// lib/features/home/components/hero_header.dart
import 'package:flutter/material.dart';
import '../../../widgets/tiles/sync_status_dot.dart';
import '../sheets/info_sync_status.dart';

class HeroHeader extends StatelessWidget {
  const HeroHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // TODO: Wire this to a Riverpod provider that computes overall freshness.
    const overallStatus = SyncDotStatus.notConnected;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: greeting
          Text('Afternoon, friend 👋', style: theme.textTheme.titleLarge),

          // Right: sync dot + (i)
          Row(
            children: [
              SyncStatusDot(
                status: overallStatus,
                size: 12,
                semanticLabel: 'Sync status',
              ),
              const SizedBox(width: 6),
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => InfoSyncStatusSheet.show(context),
                child: Icon(
                  Icons.info_outline,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
