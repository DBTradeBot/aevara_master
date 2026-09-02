// lib/features/profile/export_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/export_request.dart';
import '../../data/services/export_service.dart';

enum _RangeKind { all, last30, custom }

class ExportPage extends StatefulWidget {
  const ExportPage({super.key});

  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
  // Streams & status
  Stream<List<ExportRequest>>? _stream;
  String? _status;
  String? _requestingFormat; // 'ndjson' or 'csv'

  // Range UI state
  _RangeKind _rangeKind = _RangeKind.all;
  DateTime? _minDate; // earliest allowed
  DateTime? _start;   // for custom
  DateTime? _end;     // for custom
  bool _includeRaw = false;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _stream = exportService.watchMyExports(_uid);
    _loadBounds();
  }

  Future<void> _loadBounds() async {
    // Try earliest day doc id (users/{uid}/days/{YYYY-MM-DD}), else auth creationTime
    DateTime? minDate;
    try {
      final q = await _db
          .collection('users/$_uid/days')
          .orderBy('__name__', descending: false)
          .limit(1)
          .get();

      if (q.docs.isNotEmpty) {
        final id = q.docs.first.id; // expect 'YYYY-MM-DD'
        final parts = id.split('-');
        if (parts.length == 3) {
          final y = int.tryParse(parts[0]);
          final m = int.tryParse(parts[1]);
          final d = int.tryParse(parts[2]);
          if (y != null && m != null && d != null) {
            minDate = DateTime(y, m, d);
          }
        }
      }
    } catch (_) {
      // ignore; fallback to auth creation
    }

    final created = FirebaseAuth.instance.currentUser?.metadata.creationTime;
    minDate ??= created?.toLocal() ?? DateTime.now().subtract(const Duration(days: 365 * 5));
    // default custom range to last 30 days (bounded by [minDate, today])
    final today = DateTime.now();
    final last30 = today.subtract(const Duration(days: 30));
    final start = last30.isBefore(minDate) ? minDate : last30;
    setState(() {
      _minDate = DateTime(minDate!.year, minDate.month, minDate.day);
      _start = DateTime(start!.year, start.month, start.day);
      _end = DateTime(today.year, today.month, today.day);
    });
  }

  // -------- Helpers --------
  String _fmtDate(DateTime d) {
    // YYYY-MM-DD (zero-padded)
    String two(int n) => n < 10 ? '0$n' : '$n';
    return '${d.year}-${two(d.month)}-${two(d.day)}';
    // NOTE: We format in local time; backend compares doc IDs lexicographically (YYYY-MM-DD).
  }

  Map<String, dynamic> _selectedDateRangeParam() {
    switch (_rangeKind) {
      case _RangeKind.all:
        return {'kind': 'all'};
      case _RangeKind.last30:
        return {'kind': 'last_30'};
      case _RangeKind.custom:
        final s = _start;
        final e = _end;
        if (s != null && e != null) {
          return {
            'kind': 'custom',
            'start': _fmtDate(s),
            'end': _fmtDate(e),
          };
        }
        return {'kind': 'all'};
    }
  }

  Future<void> _pickStartDate() async {
    if (_minDate == null) return;
    final today = DateTime.now();
    final chosen = await showDatePicker(
      context: context,
      initialDate: _start ?? _minDate!,
      firstDate: _minDate!,
      lastDate: _end ?? DateTime(today.year, today.month, today.day),
    );
    if (chosen != null) {
      // Clamp to not exceed end
      final end = _end ?? chosen;
      final adj = chosen.isAfter(end) ? end : chosen;
      setState(() => _start = DateTime(adj.year, adj.month, adj.day));
    }
  }

  Future<void> _pickEndDate() async {
    if (_minDate == null) return;
    final today = DateTime.now();
    final chosen = await showDatePicker(
      context: context,
      initialDate: _end ?? today,
      firstDate: _start ?? _minDate!,
      lastDate: DateTime(today.year, today.month, today.day),
    );
    if (chosen != null) {
      // Clamp to not precede start
      final start = _start ?? chosen;
      final adj = chosen.isBefore(start) ? start : chosen;
      setState(() => _end = DateTime(adj.year, adj.month, adj.day));
    }
  }

  Future<void> _requestExport({required List<String> formats}) async {
    final fmt = formats.join(',');
    setState(() {
      _requestingFormat = formats.length == 1 ? formats.first : fmt;
      _status = null;
    });
    try {
      final params = <String, dynamic>{
        'formats': formats,
        'dateRange': _selectedDateRangeParam(),
        if (_includeRaw) 'includeRaw': true,
      };
      await exportService.requestExport(_uid, params: params);

      if (!mounted) return;
      setState(() {
        _status = 'Export requested — watch below for the download link.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export requested ($fmt)')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Error requesting export: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _requestingFormat = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Export my data')),
      body: SafeArea(
        child: StreamBuilder<List<ExportRequest>>(
          stream: _stream,
          builder: (context, snap) {
            final items = snap.data ?? const <ExportRequest>[];

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Range selection
                Text('Date range', style: text.titleMedium),
                const SizedBox(height: 8),
                SegmentedButton<_RangeKind>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: _RangeKind.all, label: Text('All time')),
                    ButtonSegment(value: _RangeKind.last30, label: Text('Last 30')),
                    ButtonSegment(value: _RangeKind.custom, label: Text('Custom')),
                  ],
                  selected: {_rangeKind},
                  onSelectionChanged: (s) {
                    setState(() => _rangeKind = s.first);
                  },
                ),
                const SizedBox(height: 8),

                if (_rangeKind == _RangeKind.all && _minDate != null)
                  _InfoBanner(
                    icon: Icons.info_outline,
                    color: cs.surfaceVariant,
                    text:
                    'Exporting all data since ${_fmtDate(_minDate!)}. For very large accounts this may take longer.',
                  ),

                if (_rangeKind == _RangeKind.custom) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today_outlined),
                          onPressed: _pickStartDate,
                          label: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              _start == null ? 'Start date' : _fmtDate(_start!),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today_outlined),
                          onPressed: _pickEndDate,
                          label: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              _end == null ? 'End date' : _fmtDate(_end!),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_minDate != null)
                    Text(
                      'Available from ${_fmtDate(_minDate!)} to ${_fmtDate(DateTime.now())}',
                      style: text.bodySmall,
                    ),
                ],

                const SizedBox(height: 16),

                SwitchListTile(
                  value: _includeRaw,
                  onChanged: (v) => setState(() => _includeRaw = v),
                  title: const Text('Include raw vendor data'),
                  subtitle: const Text('Adds sync_days.ndjson to the ZIP'),
                ),

                const SizedBox(height: 16),

                // Primary actions — straight buttons for JSON or CSV
                _ActionButtons(
                  requestingFormat: _requestingFormat,
                  onJson: () => _requestExport(formats: const ['ndjson']),
                  onCsv: () => _requestExport(formats: const ['csv']),
                ),

                if (_status != null) ...[
                  const SizedBox(height: 12),
                  Text(_status!, style: text.bodySmall),
                ],

                const SizedBox(height: 28),
                if (items.isNotEmpty) ...[
                  Text('Your recent exports', style: text.titleMedium),
                  const SizedBox(height: 8),
                  ...items.map((e) => _ExportTile(req: e)),
                  const SizedBox(height: 8),
                ] else ...[
                  Text('No exports yet.', style: text.bodySmall),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.requestingFormat,
    required this.onJson,
    required this.onCsv,
  });

  final String? requestingFormat;
  final VoidCallback onJson;
  final VoidCallback onCsv;

  bool get _isJsonBusy => requestingFormat == 'ndjson';
  bool get _isCsvBusy => requestingFormat == 'csv';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // JSON button
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            icon: const Icon(Icons.data_object),
            onPressed: _isJsonBusy ? null : onJson,
            label: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: _isJsonBusy
                  ? const _BusyInline()
                  : const Text('Export JSON (.ndjson)'),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // CSV button
        SizedBox(
          width: double.infinity,
          child: FilledButton.tonalIcon(
            icon: const Icon(Icons.table_chart_outlined),
            onPressed: _isCsvBusy ? null : onCsv,
            label: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: _isCsvBusy
                  ? const _BusyInline()
                  : const Text('Export CSV (.csv)'),
            ),
          ),
        ),
      ],
    );
  }
}

class _BusyInline extends StatelessWidget {
  const _BusyInline();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 20,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          ),
          SizedBox(width: 10),
          Text('Requesting…'),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _ExportTile extends StatelessWidget {
  final ExportRequest req;
  const _ExportTile({required this.req});

  @override
  Widget build(BuildContext context) {
    final status = req.status;
    final created = req.createdAt?.toLocal();
    final expires = req.expiresAt?.toLocal();
    final subtitle = [
      if (created != null) 'Requested ${created.toString()}',
      if (expires != null && req.isReady) 'Expires ${expires.toString()}',
      if (req.bytes != null) '${req.bytes} bytes',
      if (status == ExportStatus.running) 'Progress ${(req.progress ?? 0)}%',
      if (status == ExportStatus.error && (req.errorMessage ?? '').isNotEmpty)
        'Error: ${req.errorMessage}',
    ].join('  •  ');

    return Card(
      child: ListTile(
        title: Text('Export ${req.id}'),
        subtitle: Text(subtitle),
        trailing: req.isReady
            ? IconButton(
          icon: const Icon(Icons.download),
          onPressed: () async {
            final url = req.downloadUrl!;
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cannot open download link')),
              );
            }
          },
        )
            : (status == ExportStatus.running
            ? SizedBox(
          width: 56,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LinearProgressIndicator(value: req.progressPct),
              const SizedBox(height: 6),
              Text(
                '${req.progress ?? 0}%',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        )
            : Text(
          status,
          style: Theme.of(context).textTheme.labelMedium,
        )),
      ),
    );
  }
}
