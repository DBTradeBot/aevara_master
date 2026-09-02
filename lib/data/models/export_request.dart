// lib/data/models/export_request.dart
// Model for user data exports (Firestore-backed).
// Tolerates snake_case (backend) and camelCase (client) keys.

import 'package:cloud_firestore/cloud_firestore.dart';

/// Export status values we use across app + functions.
class ExportStatus {
  static const queued = 'queued';     // user requested; job not started yet
  static const running = 'running';   // worker is generating files
  static const ready = 'ready';       // signed URL available
  static const error = 'error';       // failed; see errorMessage
  static const expired = 'expired';   // URL is no longer valid
  static const canceled = 'canceled';
}

/// A single export request document under users/{uid}/exports/{exportId}.
class ExportRequest {
  final String id;

  /// Optional owner (often inferred from path).
  final String? uid;

  /// Export status; see [ExportStatus].
  final String status;

  /// When the doc was created (UTC).
  final DateTime? createdAt;

  /// Last update time from the backend (UTC).
  final DateTime? updatedAt;

  /// If a signed URL is produced, when it expires (UTC).
  final DateTime? expiresAt;

  /// Temporary signed download URL (nullable until [status] == ready).
  final String? downloadUrl;

  /// Bytes of the final archive (if known).
  final int? bytes;

  /// 0–100 hint during processing.
  final int? progress;

  /// Archive format (e.g. "zip"); optional.
  final String? format;

  /// Free-form parameters (e.g. ranges, filters).
  final Map<String, dynamic>? params;

  /// Human-readable error, if any.
  final String? errorMessage;

  const ExportRequest({
    required this.id,
    required this.status,
    this.uid,
    this.createdAt,
    this.updatedAt,
    this.expiresAt,
    this.downloadUrl,
    this.bytes,
    this.progress,
    this.format,
    this.params,
    this.errorMessage,
  });

  /// Convenience: 0.0–1.0 progress fraction for UI.
  double get progressPct {
    final p = progress ?? 0;
    final clamped = p < 0 ? 0 : (p > 100 ? 100 : p);
    return clamped / 100.0;
  }

  bool get isTerminal =>
      status == ExportStatus.ready ||
          status == ExportStatus.error ||
          status == ExportStatus.expired ||
          status == ExportStatus.canceled;

  bool get isReady => status == ExportStatus.ready && downloadUrl != null;

  ExportRequest copyWith({
    String? id,
    String? uid,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expiresAt,
    String? downloadUrl,
    int? bytes,
    int? progress,
    String? format,
    Map<String, dynamic>? params,
    String? errorMessage,
  }) {
    return ExportRequest(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      bytes: bytes ?? this.bytes,
      progress: progress ?? this.progress,
      format: format ?? this.format,
      params: params ?? this.params,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Create from a typed Firestore document.
  factory ExportRequest.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return ExportRequest.fromMap(doc.id, data);
  }

  /// Create from an untyped Firestore document.
  factory ExportRequest.fromAnyDoc(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? const <String, dynamic>{};
    return ExportRequest.fromMap(doc.id, data);
  }

  /// Create from a plain map (accepts both snake_case and camelCase fields).
  factory ExportRequest.fromMap(String id, Map<String, dynamic> json) {
    DateTime? _dt(dynamic v) {
      if (v == null) return null;
      if (v is Timestamp) return v.toDate().toUtc();
      if (v is DateTime) return v.toUtc();
      if (v is String) {
        final d = DateTime.tryParse(v);
        return d?.toUtc();
      }
      return null;
    }

    int? _int(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is double) return v.round();
      if (v is String) return int.tryParse(v);
      return null;
    }

    String? _str(String a, String b) =>
        (json[a] ?? json[b]) == null ? null : (json[a] ?? json[b]).toString();

    final status = _str('status', 'state') ?? ExportStatus.queued;

    return ExportRequest(
      id: id,
      uid: _str('uid', 'userId'),
      status: status,
      createdAt: _dt(json['created_at_utc'] ?? json['createdAt']),
      updatedAt: _dt(json['updated_at_utc'] ?? json['updatedAt']),
      expiresAt: _dt(json['expires_at_utc'] ?? json['expiresAt']),
      downloadUrl: _str('download_url', 'downloadUrl'),
      bytes: _int(json['bytes']),
      progress: _int(json['progress']),
      format: _str('format', 'archiveFormat'),
      params: (json['params'] as Map<String, dynamic>?) ??
          (json['options'] as Map<String, dynamic>?),
      errorMessage: _str('error_message', 'errorMessage'),
    );
  }

  Map<String, dynamic> toJson() {
    Timestamp? _ts(DateTime? d) => d == null ? null : Timestamp.fromDate(d.toUtc());
    return <String, dynamic>{
      'uid': uid,
      'status': status,
      'created_at_utc': _ts(createdAt),
      'updated_at_utc': _ts(updatedAt),
      'expires_at_utc': _ts(expiresAt),
      'download_url': downloadUrl,
      'bytes': bytes,
      'progress': progress,
      'format': format,
      'params': params,
      'error_message': errorMessage,
    }..removeWhere((_, v) => v == null);
  }

  @override
  String toString() =>
      'ExportRequest(id=$id, status=$status, ready=$isReady, bytes=$bytes, progress=$progress)';

  @override
  int get hashCode =>
      Object.hash(id, status, downloadUrl, bytes, progress, expiresAt);

  @override
  bool operator ==(Object other) =>
      other is ExportRequest &&
          other.id == id &&
          other.status == status &&
          other.downloadUrl == downloadUrl &&
          other.bytes == bytes &&
          other.progress == progress &&
          other.expiresAt == expiresAt;
}
