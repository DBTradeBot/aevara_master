import 'package:flutter/material.dart';

/// Data export request UI.
/// NOTE: This page currently shows guidance and a stub button.
/// Hook your ExportService here when ready.
class ExportPage extends StatefulWidget {
  const ExportPage({super.key});

  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
  bool _requesting = false;
  String? _status;

  Future<void> _requestExport() async {
    setState(() {
      _requesting = true;
      _status = null;
    });
    try {
      // TODO: Wire your ExportService here (e.g., ExportServiceFs.requestExport(uid))
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() => _status = 'We’ll email you a link when your export is ready.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export requested')),
      );
    } catch (e) {
      setState(() => _status = 'Error: $e');
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Export my data')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('What you’ll receive', style: text.titleMedium),
            const SizedBox(height: 8),
            Text(
              '• JSON/CSV of your daily metrics\n'
                  '• Experiment logs and results\n'
                  '• Device sync history\n'
                  '• Account metadata\n',
              style: text.bodyMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'We generate exports on the server and email you a download link. '
                  'Depending on size, this can take a few minutes.',
              style: text.bodySmall,
            ),
            if (_status != null) ...[
              const SizedBox(height: 16),
              Text(_status!, style: text.bodySmall),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: FilledButton(
          onPressed: _requesting ? null : _requestExport,
          child: _requesting
              ? const SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Text('Request export'),
          ),
        ),
      ),
    );
  }
}
