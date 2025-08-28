// lib/widgets/tiles/sync_status_dot.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../features/home/sheets/connect_providers_sheet.dart';

/// Freshness/status values for the sync dot.
enum SyncDotStatus { fresh, stale, error, notConnected }

/// Unified sync dot used across the app.
/// Tapping the dot opens the ConnectProviders bottom sheet.
/// The (i) legend sheet is separate (InfoSyncStatusSheet) and should NOT open here.
class SyncStatusDot extends StatelessWidget {
  const SyncStatusDot({
    super.key,
    required this.status,
    this.size = 10,
    this.semanticLabel,
  });

  final SyncDotStatus status;
  final double size;
  final String? semanticLabel;

  Color _color(ColorScheme s) {
    switch (status) {
      case SyncDotStatus.fresh:
        return const Color(0xFF24A699); // success
      case SyncDotStatus.stale:
        return const Color(0xFFF6B56B); // warning
      case SyncDotStatus.error:
        return const Color(0xFFBF4A4A); // error
      case SyncDotStatus.notConnected:
        return s.outlineVariant; // neutral gray
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;

    return Semantics(
      label: semanticLabel ?? 'Sync status',
      button: true,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () async {
          await HapticFeedback.selectionClick();
          await ConnectProvidersSheet.show(context);
        },
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: _color(s),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
