// lib/features/profile/export_detail_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/export_request.dart';
import '../../data/services/export_service.dart';

class ExportDetailPage extends StatefulWidget {
  final String exportId;
  const ExportDetailPage({super.key, required this.exportId});

  @override
  State<ExportDetailPage> createState() => _ExportDetailPageState();
}

class _ExportDetailPageState extends State<ExportDetailPage> {
  ExportRequest? _req;
  bool _loading = true;
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await exportService.getExport(_uid, widget.exportId);
    if (!mounted) return;
    setState(() {
      _req = r;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = _req;
    return Scaffold(
      appBar: AppBar(title: Text('Export ${widget.exportId}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (r == null
          ? const Center(child: Text('Export not found'))
          : _buildBody(context, r)),
    );
  }

  Widget _buildBody(BuildContext context, ExportRequest r) {
    final text = Theme.of(context).textTheme;
    final created = r.createdAt?.toLocal();
    final updated = r.updatedAt?.toLocal();
    final expires = r.expiresAt?.toLocal();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Status: ${r.status}', style: text.titleMedium),
        const SizedBox(height: 8),
        if (r.status == ExportStatus.running) ...[
          LinearProgressIndicator(value: r.progressPct),
          const SizedBox(height: 6),
          Text('Progress: ${r.progress ?? 0}%', style: text.labelMedium),
        ],
        const SizedBox(height: 12),
        if (created != null) Text('Requested: $created'),
        if (updated != null) Text('Last update: $updated'),
        if (r.isReady && expires != null) Text('Link expires: $expires'),
        if (r.bytes != null) Text('Size: ${r.bytes} bytes'),
        if (r.errorMessage != null && r.errorMessage!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Error: ${r.errorMessage}', style: text.bodySmall?.copyWith(color: Colors.red)),
          ),
        const SizedBox(height: 20),
        if (r.isReady && r.downloadUrl != null)
          FilledButton.icon(
            icon: const Icon(Icons.download),
            label: const Text('Download export'),
            onPressed: () async {
              final uri = Uri.parse(r.downloadUrl!);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Cannot open link')));
              }
            },
          ),
      ],
    );
  }
}
