// lib/core/notifications/notification_banner.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/app_notification.dart';

typedef NotifCallback = Future<void> Function();

class NotificationBanner extends ConsumerStatefulWidget {
  const NotificationBanner({
    super.key,
    required this.notification,
    required this.onDismiss,   // called when user swipes or press Dismiss
    required this.onOpen,      // called when user taps CTA (if any)
    required this.onMarkRead,  // called when expand/read
    this.maxBodyLinesCollapsed = 2,
  });

  final AppNotification notification;
  final NotifCallback onDismiss;
  final NotifCallback onOpen;
  final NotifCallback onMarkRead;
  final int maxBodyLinesCollapsed;

  @override
  ConsumerState<NotificationBanner> createState() => _NotificationBannerState();
}

class _NotificationBannerState extends ConsumerState<NotificationBanner> {
  bool _expanded = false;

  IconData _iconFor(AppNotifCategory c) {
    switch (c) {
      case AppNotifCategory.system:
        return Icons.settings_suggest_outlined;
      case AppNotifCategory.coaching:
        return Icons.psychology_outlined;
      case AppNotifCategory.experiments:
        return Icons.science_outlined;
      case AppNotifCategory.community:
        return Icons.people_alt_outlined;
      case AppNotifCategory.account:
        return Icons.manage_accounts_outlined;
    }
  }

  Color _chipColor(BuildContext context, AppNotifSeverity s) {
    switch (s) {
      case AppNotifSeverity.info:
        return const Color(0xFF3B91A3);
      case AppNotifSeverity.success:
        return const Color(0xFF24A699);
      case AppNotifSeverity.warn:
        return const Color(0xFFF6B56B);
      case AppNotifSeverity.crit:
        return const Color(0xFFBF4A4A);
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.notification;
    final color = _chipColor(context, n.severity);

    final card = Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      color: Theme.of(context).colorScheme.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final next = !_expanded;
          setState(() => _expanded = next);
          if (next && !n.isRead && n.archivedAt == null) {
            await widget.onMarkRead();
          }
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon + unread dot
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                    child: Icon(_iconFor(n.category), size: 18),
                  ),
                  if (!n.isRead && n.archivedAt == null)
                    const Positioned(
                      top: -2,
                      right: -2,
                      child: CircleAvatar(
                        radius: 4.5,
                        backgroundColor: Color(0xFFBF4A4A),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + severity chip
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            n.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: color.withOpacity(0.4)),
                          ),
                          child: Text(
                            n.severity.name.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if ((n.body ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      AnimatedCrossFade(
                        crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 180),
                        firstChild: Text(
                          n.body!,
                          maxLines: widget.maxBodyLinesCollapsed,
                          overflow: TextOverflow.ellipsis,
                        ),
                        secondChild: Text(n.body!),
                      ),
                    ],
                    const SizedBox(height: 8),
                    // CTA row
                    Row(
                      children: [
                        if (n.route != null && n.route!.isNotEmpty)
                          FilledButton.tonalIcon(
                            icon: const Icon(Icons.open_in_new, size: 18),
                            label: const Text('Open'),
                            onPressed: widget.onOpen,
                          ),
                        const Spacer(),
                        TextButton.icon(
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Dismiss'),
                          onPressed: widget.onDismiss,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Dismissible(
      key: ValueKey('overlay_notif_${n.id}'),
      direction: DismissDirection.horizontal,
      onDismissed: (_) async => widget.onDismiss(),
      background: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade700,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const Icon(Icons.archive_outlined, color: Colors.white),
      ),
      secondaryBackground: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade700,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const Icon(Icons.archive_outlined, color: Colors.white),
      ),
      child: card,
    );
  }
}
