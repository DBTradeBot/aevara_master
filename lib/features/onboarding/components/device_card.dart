import 'package:flutter/material.dart';

/// A small, glanceable device tile used both in onboarding & settings.
/// This version is status-enum agnostic (no hard-coded enum constants).
class DeviceCard extends StatelessWidget {
  const DeviceCard({
    super.key,
    required this.title,
    required this.providerId,
    required this.asset,
    required this.accentColor,
    this.status,
    this.comingSoon = false,
    this.localStore = false,
    this.onConnect,
    this.onManage,
    this.busy = false, // added to match your call-site
  });

  final String title;
  final String providerId;
  final String asset; // path to image asset (e.g., assets/providers/fitbit.png)
  final Color accentColor;

  /// Whatever your app passes (enum/string). We won't rely on the exact type.
  final Object? status;

  /// Shows a "Coming soon" tag and disables interactive actions.
  final bool comingSoon;

  /// For phone-local stores like Apple Health / Google Fit (changes help text).
  final bool localStore;

  /// Called when user taps primary action to connect/launch OAuth/etc.
  final Future<void> Function()? onConnect;

  /// Called when user taps manage (refresh/disconnect).
  final Future<void> Function()? onManage;

  /// Show an overlay progress indicator while launching OAuth / syncing.
  final bool busy;

  // ────────────────────────────────────────────────────────────────────────────
  // Helpers
  // ────────────────────────────────────────────────────────────────────────────

  bool get _isConnected {
    final s = (status?.toString() ?? '').toLowerCase();
    // Accept a variety of enum/string names without hard-coding an enum type.
    return s.contains('ok') ||
        s.contains('connected') ||
        s.contains('ready') ||
        s.contains('success');
  }

  bool get _isSyncing {
    final s = (status?.toString() ?? '').toLowerCase();
    return s.contains('sync') ||
        s.contains('fetch') ||
        s.contains('refresh') ||
        s.contains('inprogress') ||
        s.contains('loading');
  }

  bool get _isError {
    final s = (status?.toString() ?? '').toLowerCase();
    return s.contains('error') ||
        s.contains('fail') ||
        s.contains('denied') ||
        s.contains('unauthorized');
  }

  String get _statusLabel {
    if (comingSoon) return 'Coming soon';
    if (busy) return 'Opening…';
    if (_isSyncing) return 'Syncing…';
    if (_isConnected) return 'Connected';
    if (_isError) return 'Needs attention';
    return 'Not connected';
  }

  Color _statusColor(ThemeData theme) {
    final cs = theme.colorScheme;
    if (comingSoon) return cs.outline;
    if (busy || _isSyncing) return cs.primary;
    if (_isConnected) return Colors.green;
    if (_isError) return cs.error;
    return cs.outline;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final border = BorderRadius.circular(16);

    final disabled = comingSoon || busy;

    // Buttons: primary action is Connect or Manage depending on state
    final primaryLabel = _isConnected ? 'Manage' : 'Connect';
    final primaryHandler = _isConnected ? onManage : onConnect;

    final statusColor = _statusColor(theme);
    final statusStyle = theme.textTheme.labelMedium?.copyWith(
      color: statusColor,
      fontWeight: FontWeight.w600,
    );

    return Stack(
      children: [
        InkWell(
          onTap: disabled ? null : () => primaryHandler?.call(),
          borderRadius: border,
          child: Ink(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: border,
              border: Border.all(color: cs.outlineVariant),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 8,
                  offset: Offset(0, 2),
                  color: Color(0x11000000),
                ),
              ],
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header row: logo + name + status chip
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Device logo
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: accentColor.withOpacity(.10),
                        image: DecorationImage(
                          image: AssetImage(asset),
                          fit: BoxFit.contain,
                          opacity: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Title expands to take remaining space first
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Status chip shrinks if needed (prevents tiny overflows)
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: statusColor.withOpacity(.45)),
                          ),
                          child: Text(_statusLabel, style: statusStyle),
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Footer actions
                Row(
                  children: [
                    if (localStore) ...[
                      Icon(Icons.phone_iphone, size: 16, color: cs.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Reads from phone',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ] else ...[
                      Expanded(
                        child: Text(
                          _isConnected
                              ? 'Last sync shown in Devices'
                              : 'Sleep • Recovery • Activity',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    // Make the button shrink if the row is tight
                    Flexible(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 36),
                        child: FilledButton(
                          onPressed: disabled ? null : () => primaryHandler?.call(),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 36), // allow horizontal shrink
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(primaryLabel),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Busy overlay & spinner
        if (busy)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: cs.surface.withOpacity(.55),
                borderRadius: border,
              ),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}
