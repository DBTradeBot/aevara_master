// lib/features/onboarding/connect_page.dart
import 'package:flutter/material.dart';
import '../../routing/route_paths.dart';

class ConnectPage extends StatefulWidget {
  const ConnectPage({super.key});

  @override
  State<ConnectPage> createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage> {
  final Set<String> _connected = {}; // simple local state for UI affordance

  void _toggle(String id) {
    setState(() {
      if (_connected.contains(id)) {
        _connected.remove(id);
      } else {
        _connected.add(id);
      }
    });
  }

  void _finish() {
    // For now we go straight to Dashboard; connections can be managed later.
    Navigator.of(context).pushNamedAndRemoveUntil(RoutePaths.home, (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = theme.textTheme;

    final options = <_Provider>[
      _Provider('apple', 'Apple Health', Icons.link_rounded),
      _Provider('fit', 'Google Fit', Icons.link_rounded),
      _Provider('garmin', 'Garmin', Icons.link_rounded),
      _Provider('oura', 'Oura', Icons.link_rounded),
      _Provider('whoop', 'WHOOP', Icons.link_rounded),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Connect a device')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            // Hero / intro card
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(.10),
                    theme.colorScheme.secondary.withOpacity(.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primary.withOpacity(.15),
                    child: Icon(Icons.devices_other_outlined,
                        color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bring your data with you', style: t.titleMedium),
                        const SizedBox(height: 6),
                        Text(
                          'Connect your wearables now to see trends faster. '
                              'You can always connect or disconnect later in Settings → Connections.',
                          style: t.bodyMedium!.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Grid of providers
            LayoutBuilder(
              builder: (context, c) {
                final cross = c.maxWidth > 600 ? 3 : 2;
                return GridView.builder(
                  itemCount: options.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cross,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.4,
                  ),
                  itemBuilder: (context, i) {
                    final p = options[i];
                    final selected = _connected.contains(p.id);
                    return _ProviderCard(
                      provider: p,
                      connected: selected,
                      onTap: () => _toggle(p.id),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            OutlinedButton(
              onPressed: _finish,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
              child: const Text('Skip for now'),
            ),
            const Spacer(),
            FilledButton(
              onPressed: _finish,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              ),
              child: Text(_connected.isEmpty ? 'Continue' : 'Continue (${_connected.length})'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Provider {
  final String id;
  final String name;
  final IconData icon;
  const _Provider(this.id, this.name, this.icon);
}

class _ProviderCard extends StatelessWidget {
  final _Provider provider;
  final bool connected;
  final VoidCallback onTap;
  const _ProviderCard({
    required this.provider,
    required this.connected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = BorderRadius.circular(16);
    final on = theme.colorScheme.primary;
    final off = theme.colorScheme.onSurface.withOpacity(.7);

    return InkWell(
      onTap: onTap,
      borderRadius: border,
      child: Ink(
        decoration: BoxDecoration(
          color: connected ? on.withOpacity(.10) : theme.colorScheme.surface,
          borderRadius: border,
          border: Border.all(
            color: connected ? on : theme.colorScheme.outlineVariant,
            width: connected ? 1.6 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              blurRadius: 10,
              offset: Offset(0, 2),
              color: Color(0x11000000),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: connected ? on.withOpacity(.15) : theme.colorScheme.surfaceVariant,
              child: Icon(provider.icon, color: connected ? on : off),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(provider.name,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: connected ? on : null)),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: connected
                  ? Row(
                key: const ValueKey('ok'),
                children: [
                  const Icon(Icons.check_circle, size: 18),
                  const SizedBox(width: 6),
                  Text('Connected',
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(color: on)),
                ],
              )
                  : const Icon(Icons.add_link),
            ),
          ],
        ),
      ),
    );
  }
}
