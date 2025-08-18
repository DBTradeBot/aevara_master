import 'package:flutter/material.dart';

enum SyncState { unsynced, partial, synced }

class SyncStatusIcon extends StatelessWidget {
  const SyncStatusIcon({
    super.key,
    required this.state,
    this.lastSync,
    this.onTap,
  });

  final SyncState state;
  final DateTime? lastSync;
  final VoidCallback? onTap;

  String _tooltip() {
    switch (state) {
      case SyncState.synced:
        final ts = lastSync != null ? ' at ${_fmtTime(lastSync!)}' : '';
        return 'Data synced$ts';
      case SyncState.partial:
        final ts = lastSync != null
            ? ' â€” last full sync ${_fmtTime(lastSync!)}'
            : '';
        return 'Partial data$ts';
      case SyncState.unsynced:
      default:
        return 'Not synced â€” tap to connect';
    }
  }

  static String _fmtTime(DateTime dt) {
    // Short human-ish time; keep simple for now
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Color _dotColor(BuildContext context) {
    switch (state) {
      case SyncState.synced:
        return const Color(0xFF27AE60); // green
      case SyncState.partial:
        return const Color(0xFFF2994A); // amber
      case SyncState.unsynced:
      default:
        return const Color(0xFF9AA3AF); // gray
    }
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _tooltip(),
      child: InkResponse(
        onTap: onTap,
        radius: 20,
        child: SizedBox(
          width: 20,
          height: 20,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // subtle circle outline to read on white bg
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0x1A000000)),
                ),
              ),
              // colored dot
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _dotColor(context),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
