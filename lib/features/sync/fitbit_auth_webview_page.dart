// lib/features/sync/fitbit_auth_webview_page.dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// In-app Fitbit OAuth flow:
/// - Loads Fitbit authorize URL inside WebView.
/// - Detects redirect to your Firebase Hosting callback (HTTPS).
/// - Lets the redirect actually load (no prevent), then closes.
/// Requires: webview_flutter ^4.x in pubspec.
class FitbitAuthWebViewPage extends StatefulWidget {
  const FitbitAuthWebViewPage({
    super.key,
    required this.authorizeUrl,
    required this.redirectPrefix,
    required this.onAuthorized,
  });

  final Uri authorizeUrl;
  /// e.g. "https://vitalis-a8577.web.app/fitbit/callback"
  final String redirectPrefix;
  final Future<void> Function() onAuthorized;

  @override
  State<FitbitAuthWebViewPage> createState() => _FitbitAuthWebViewPageState();
}

class _FitbitAuthWebViewPageState extends State<FitbitAuthWebViewPage> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _finished = false;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          // ✅ Do NOT prevent the callback. Let the Hosting page load.
          onNavigationRequest: (req) => NavigationDecision.navigate,
          onUrlChange: (change) {
            final url = change.url ?? '';
            if (url.startsWith(widget.redirectPrefix)) {
              _handleAuthorized(); // will pop after running onAuthorized
            }
          },
          onPageStarted: (_) => setState(() => _loading = true),
          onPageFinished: (_) => setState(() => _loading = false),
          onWebResourceError: (err) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Web error: ${err.description}')),
            );
          },
        ),
      )
      ..loadRequest(widget.authorizeUrl);
  }

  Future<void> _handleAuthorized() async {
    if (_finished) return;
    _finished = true;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fitbit authorized — finishing up…')),
      );
    }
    try {
      await widget.onAuthorized();
    } catch (_) {
      // best-effort; Firestore listeners will still update UI
    }
    if (mounted) Navigator.of(context).pop(); // close the WebView screen
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Fitbit'),
        actions: [
          IconButton(
            tooltip: 'Reload',
            onPressed: () => _controller.reload(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(color: cs.primary),
            ),
        ],
      ),
    );
  }
}
