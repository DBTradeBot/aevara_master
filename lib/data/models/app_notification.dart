// lib/data/models/app_notification.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum AppNotifType {
  calibrationBannerDismissed,
  calibrationComplete,
  computeError,
  deviceAuthIssue,
  coachingNudge,
  experimentStarted,
  experimentCheckpoint,
  experimentCompleted,
  communityFriendRequest,
  communityChallengeInvite,
  badgeEarned,
  accountExportReady,
  policyUpdate,
}

enum AppNotifCategory { system, coaching, experiments, community, account }
enum AppNotifSeverity { info, success, warn, crit }

AppNotifType notifTypeFromString(String s) {
  switch (s) {
    case 'calibration_banner_dismissed':
      return AppNotifType.calibrationBannerDismissed;
    case 'calibration_complete':
      return AppNotifType.calibrationComplete;
    case 'compute_error':
      return AppNotifType.computeError;
    case 'device_auth_issue':
      return AppNotifType.deviceAuthIssue;
    case 'coaching_nudge':
      return AppNotifType.coachingNudge;
    case 'experiment_started':
      return AppNotifType.experimentStarted;
    case 'experiment_checkpoint':
      return AppNotifType.experimentCheckpoint;
    case 'experiment_completed':
      return AppNotifType.experimentCompleted;
    case 'community_friend_request':
      return AppNotifType.communityFriendRequest;
    case 'community_challenge_invite':
      return AppNotifType.communityChallengeInvite;
    case 'badge_earned':
      return AppNotifType.badgeEarned;
    case 'account_export_ready':
      return AppNotifType.accountExportReady;
    case 'policy_update':
      return AppNotifType.policyUpdate;
    default:
      return AppNotifType.coachingNudge;
  }
}

String notifTypeToString(AppNotifType t) {
  switch (t) {
    case AppNotifType.calibrationBannerDismissed:
      return 'calibration_banner_dismissed';
    case AppNotifType.calibrationComplete:
      return 'calibration_complete';
    case AppNotifType.computeError:
      return 'compute_error';
    case AppNotifType.deviceAuthIssue:
      return 'device_auth_issue';
    case AppNotifType.coachingNudge:
      return 'coaching_nudge';
    case AppNotifType.experimentStarted:
      return 'experiment_started';
    case AppNotifType.experimentCheckpoint:
      return 'experiment_checkpoint';
    case AppNotifType.experimentCompleted:
      return 'experiment_completed';
    case AppNotifType.communityFriendRequest:
      return 'community_friend_request';
    case AppNotifType.communityChallengeInvite:
      return 'community_challenge_invite';
    case AppNotifType.badgeEarned:
      return 'badge_earned';
    case AppNotifType.accountExportReady:
      return 'account_export_ready';
    case AppNotifType.policyUpdate:
      return 'policy_update';
  }
}

AppNotifCategory notifCategoryFromString(String s) {
  switch (s) {
    case 'system':
      return AppNotifCategory.system;
    case 'coaching':
      return AppNotifCategory.coaching;
    case 'experiments':
      return AppNotifCategory.experiments;
    case 'community':
      return AppNotifCategory.community;
    case 'account':
      return AppNotifCategory.account;
    default:
      return AppNotifCategory.system;
  }
}

String notifCategoryToString(AppNotifCategory c) {
  switch (c) {
    case AppNotifCategory.system:
      return 'system';
    case AppNotifCategory.coaching:
      return 'coaching';
    case AppNotifCategory.experiments:
      return 'experiments';
    case AppNotifCategory.community:
      return 'community';
    case AppNotifCategory.account:
      return 'account';
  }
}

AppNotifSeverity notifSeverityFromString(String s) {
  switch (s) {
    case 'info':
      return AppNotifSeverity.info;
    case 'success':
      return AppNotifSeverity.success;
    case 'warn':
      return AppNotifSeverity.warn;
    case 'crit':
      return AppNotifSeverity.crit;
    default:
      return AppNotifSeverity.info;
  }
}

String notifSeverityToString(AppNotifSeverity s) {
  switch (s) {
    case AppNotifSeverity.info:
      return 'info';
    case AppNotifSeverity.success:
      return 'success';
    case AppNotifSeverity.warn:
      return 'warn';
    case AppNotifSeverity.crit:
      return 'crit';
  }
}

class AppNotification {
  final String id;
  final AppNotifType type;
  final AppNotifCategory category;
  final AppNotifSeverity severity;

  final String title;
  final String? body;
  final String? icon; // material icon name or emoji
  final String? route;
  final Map<String, dynamic>? routeArgs;
  final String source; // "app" | "backend" | "device"

  final DateTime createdAt;
  final DateTime? readAt;
  final DateTime? archivedAt;
  final DateTime? stickyUntil;
  final DateTime? expiresAt;

  bool get isRead => readAt != null;
  bool get isArchived => archivedAt != null;
  bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());
  bool get isSticky =>
      stickyUntil != null && stickyUntil!.isAfter(DateTime.now());

  AppNotification({
    required this.id,
    required this.type,
    required this.category,
    required this.severity,
    required this.title,
    this.body,
    this.icon,
    this.route,
    this.routeArgs,
    required this.source,
    required this.createdAt,
    this.readAt,
    this.archivedAt,
    this.stickyUntil,
    this.expiresAt,
  });

  factory AppNotification.fromFirestore(
      String id, Map<String, dynamic> data) {
    final ts = (data['created_at'] as Timestamp?) ?? Timestamp.now();
    final readTs = data['read_at'] as Timestamp?;
    final archTs = data['archived_at'] as Timestamp?;
    final stickyTs = data['sticky_until'] as Timestamp?;
    final expTs = data['expires_at'] as Timestamp?;
    return AppNotification(
      id: id,
      type: notifTypeFromString((data['type'] ?? 'coaching_nudge') as String),
      category: notifCategoryFromString((data['category'] ?? 'system') as String),
      severity: notifSeverityFromString((data['severity'] ?? 'info') as String),
      title: (data['title'] ?? '') as String,
      body: data['body'] as String?,
      icon: data['icon'] as String?,
      route: data['route'] as String?,
      routeArgs: (data['route_args'] as Map?)?.cast<String, dynamic>(),
      source: (data['source'] ?? 'app') as String,
      createdAt: ts.toDate(),
      readAt: readTs?.toDate(),
      archivedAt: archTs?.toDate(),
      stickyUntil: stickyTs?.toDate(),
      expiresAt: expTs?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    Timestamp? _ts(DateTime? d) => d == null ? null : Timestamp.fromDate(d);
    return {
      'type': notifTypeToString(type),
      'category': notifCategoryToString(category),
      'severity': notifSeverityToString(severity),
      'title': title,
      if (body != null) 'body': body,
      if (icon != null) 'icon': icon,
      if (route != null) 'route': route,
      if (routeArgs != null) 'route_args': routeArgs,
      'source': source,
      'created_at': Timestamp.fromDate(createdAt),
      'read_at': _ts(readAt),
      'archived_at': _ts(archivedAt),
      'sticky_until': _ts(stickyUntil),
      'expires_at': _ts(expiresAt),
    };
  }
}
