// lib/features/settings/notifications_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/notifications_providers.dart';
import '../../data/models/app_notification.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  // All, Unread, System, Coaching, Experiments, Community, Account, Archived
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(notificationsListProvider);
    final controller = ref.read(notificationsControllerProvider.notifier);
    final unread = ref.watch(unreadCountProvider).asData?.value ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            tooltip: 'Mark all read',
            icon: const Icon(Icons.mark_email_read_outlined),
            onPressed: unread > 0
                ? () async {
              final marked = unread;
              await controller.markAllRead();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Marked $marked notification${marked == 1 ? '' : 's'} as read'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
                : null,
          ),
          IconButton(
            tooltip: 'Clear ephemeral',
            icon: const Icon(Icons.auto_delete_outlined),
            onPressed: () async {
              final n = await controller.clearEphemeral();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(n == 0
                      ? 'No ephemeral notifications to clear'
                      : 'Cleared $n ephemeral notification${n == 1 ? '' : 's'}'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _Filters(
            current: _filter,
            onChanged: (f) => setState(() => _filter = f),
          ),
          Expanded(
            child: listAsync.when(
              data: (list) {
                final filtered = _applyFilter(list, _filter);
                if (filtered.isEmpty) {
                  return const _EmptyState();
                }
                final grouped = _groupByDate(filtered);
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: grouped.length,
                  itemBuilder: (ctx, i) {
                    final entry = grouped.entries.elementAt(i);
                    final sectionTitle = entry.key;
                    final items = entry.value;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                          child: Text(
                            sectionTitle,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        ...items.map((n) => _NotifTileItem(n: n)),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Failed to load notifications:\n$e'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<AppNotification> _applyFilter(List<AppNotification> list, String f) {
    final now = DateTime.now();
    final active = list.where((n) => (n.expiresAt == null || n.expiresAt!.isAfter(now)));
    final notArchived = active.where((n) => n.archivedAt == null);
    final archived = active.where((n) => n.archivedAt != null);

    switch (f) {
      case 'Unread':
        return notArchived.where((n) => !n.isRead).toList();
      case 'System':
        return notArchived.where((n) => n.category == AppNotifCategory.system).toList();
      case 'Coaching':
        return notArchived.where((n) => n.category == AppNotifCategory.coaching).toList();
      case 'Experiments':
        return notArchived.where((n) => n.category == AppNotifCategory.experiments).toList();
      case 'Community':
        return notArchived.where((n) => n.category == AppNotifCategory.community).toList();
      case 'Account':
        return notArchived.where((n) => n.category == AppNotifCategory.account).toList();
      case 'Archived':
        return archived.toList();
      default:
        return notArchived.toList();
    }
  }

  Map<String, List<AppNotification>> _groupByDate(List<AppNotification> list) {
    String labelFor(DateTime dt) {
      final now = DateTime.now();
      final d0 = DateTime(now.year, now.month, now.day);
      final d1 = DateTime(dt.year, dt.month, dt.day);
      final delta = d0.difference(d1).inDays;
      if (delta == 0) return 'Today';
      if (delta == 1) return 'Yesterday';
      if (delta <= 7) return 'This week';
      return 'Earlier';
    }

    final Map<String, List<AppNotification>> m = {
      'Today': [],
      'Yesterday': [],
      'This week': [],
      'Earlier': [],
    };
    for (final n in list) {
      m[labelFor(n.createdAt)]!.add(n);
    }
    return m..removeWhere((k, v) => v.isEmpty);
  }
}

class _Filters extends StatelessWidget {
  const _Filters({required this.current, required this.onChanged});
  final String current;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = const [
      'All',
      'Unread',
      'System',
      'Coaching',
      'Experiments',
      'Community',
      'Account',
      'Archived', // 👈 new history tab
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          for (final it in items)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                selected: it == current,
                label: Text(it),
                onSelected: (_) => onChanged(it),
              ),
            )
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.notifications_off_outlined, size: 48),
            const SizedBox(height: 12),
            Text(
              "You're all caught up",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              "We’ll post calibration updates, coaching tips, experiment events, and more here.",
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _NotifTileItem extends ConsumerStatefulWidget {
  const _NotifTileItem({required this.n, super.key});
  final AppNotification n;

  @override
  ConsumerState<_NotifTileItem> createState() => _NotifTileItemState();
}

class _NotifTileItemState extends ConsumerState<_NotifTileItem> {
  bool _expanded = false;

  IconData _iconFor(AppNotification n) {
    switch (n.category) {
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
        return const Color(0xFF3B91A3); // Info
      case AppNotifSeverity.success:
        return const Color(0xFF24A699); // Success
      case AppNotifSeverity.warn:
        return const Color(0xFFF6B56B); // Warning
      case AppNotifSeverity.crit:
        return const Color(0xFFBF4A4A); // Error
    }
  }

  String _friendlyTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.n;
    final ctl = ref.read(notificationsControllerProvider.notifier);
    final color = _chipColor(context, n.severity);

    final baseTile = ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
            child: Icon(_iconFor(n), size: 20),
          ),
          if (!n.isRead && n.archivedAt == null)
            const Positioned(
              top: -2,
              right: -2,
              child: CircleAvatar(
                radius: 5,
                backgroundColor: Color(0xFFBF4A4A),
              ),
            ),
        ],
      ),
      title: Text(n.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: (n.body != null && n.body!.isNotEmpty)
          ? Text(n.body!, maxLines: _expanded ? 10 : 2, overflow: TextOverflow.ellipsis)
          : null,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Text(
          n.severity.name.toUpperCase(),
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
        ),
      ),
      onTap: () async {
        // Tap expands/collapses and marks read when expanding
        final next = !_expanded;
        setState(() => _expanded = next);
        if (next && !n.isRead && n.archivedAt == null) {
          await ctl.markRead(n.id);
        }
      },
    );

    final expandedArea = AnimatedCrossFade(
      crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 200),
      firstChild: const SizedBox.shrink(),
      secondChild: Padding(
        padding: const EdgeInsets.fromLTRB(56, 0, 12, 12), // align under text
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Metadata row
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: Theme.of(context).hintColor),
                const SizedBox(width: 6),
                Text(
                  '${_friendlyTime(n.createdAt)} • ${n.createdAt}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
                ),
                if (n.archivedAt != null) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.archive_outlined, size: 14, color: Theme.of(context).hintColor),
                  const SizedBox(width: 4),
                  Text(
                    'Archived',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            if ((n.body ?? '').isNotEmpty)
              Text(
                n.body!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            const SizedBox(height: 12),
            // Action row
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (n.archivedAt == null) ...[
                  OutlinedButton.icon(
                    onPressed: () async {
                      if (n.isRead) {
                        await ctl.markUnread(n.id);
                      } else {
                        await ctl.markRead(n.id);
                      }
                    },
                    icon: Icon(n.isRead ? Icons.mark_email_unread_outlined : Icons.mark_email_read_outlined),
                    label: Text(n.isRead ? 'Mark unread' : 'Mark read'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await ctl.archive(n.id);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Dismissed'),
                          behavior: SnackBarBehavior.floating,
                          action: SnackBarAction(
                            label: 'UNDO',
                            onPressed: () => ctl.unarchive(n.id),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.archive_outlined),
                    label: const Text('Dismiss'),
                  ),
                ] else ...[
                  OutlinedButton.icon(
                    onPressed: () => ctl.unarchive(n.id),
                    icon: const Icon(Icons.unarchive_outlined),
                    label: const Text('Restore'),
                  ),
                ],
                if (n.route != null && n.route!.isNotEmpty)
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushNamed(n.route!);
                    },
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );

    // Any swipe direction archives + removes from the active (All) list.
    // In Archived filter, swiping does nothing (keeps semantics simple).
    final canSwipe = n.archivedAt == null;

    final content = Column(
      children: [
        baseTile,
        expandedArea,
        const Divider(height: 0),
      ],
    );

    if (!canSwipe) return content;

    return Dismissible(
      key: ValueKey('notif_${n.id}'),
      direction: DismissDirection.horizontal,
      background: Container(
        color: Colors.grey.shade700,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const Icon(Icons.archive_outlined, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: Colors.grey.shade700,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const Icon(Icons.archive_outlined, color: Colors.white),
      ),
      confirmDismiss: (dir) async {
        await ctl.archive(n.id);
        if (!mounted) return true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Dismissed'),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'UNDO',
              onPressed: () => ctl.unarchive(n.id),
            ),
          ),
        );
        return true; // remove from the current (active) list
      },
      child: content,
    );
  }
}
