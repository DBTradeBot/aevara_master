// lib/core/widgets/dev_fab_navigator.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../routing/route_paths.dart';
import '../navigation/app_navigator.dart';

/// Small dev-only floating menu to jump around the app.
/// Routes via the global [appNavigatorKey] so it works from MaterialApp.builder.
class DevFabNavigator extends StatefulWidget {
  const DevFabNavigator({super.key});

  @override
  State<DevFabNavigator> createState() => _DevFabNavigatorState();
}

class _DevFabNavigatorState extends State<DevFabNavigator> {
  bool _open = false;
  void _toggle() => setState(() => _open = !_open);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_open)
          _MenuCard(
            onClose: _toggle,
            items: const [
              _Item('Home (push)', Icons.home_outlined, _MenuAction.goHome),
              _Item('Home (reset stack)', Icons.cleaning_services_outlined, _MenuAction.resetHome),
              _Divider(),
              _Item('Signin', Icons.login, _MenuAction.signin),
              _Item('Signup', Icons.person_add_alt, _MenuAction.signup),
              _Item('Verify Email', Icons.verified_outlined, _MenuAction.verify),
              _Divider(),
              _Item('Demographics', Icons.badge_outlined, _MenuAction.demographics),
              _Item('Identity', Icons.alternate_email, _MenuAction.identity),
              _Item('Connect', Icons.link_outlined, _MenuAction.connect),
            ],
          ),
        const SizedBox(height: 8),
        FloatingActionButton(
          mini: true,
          onPressed: _toggle,
          child: Icon(_open ? Icons.close : Icons.bug_report),
        ),
      ],
    );
  }
}

enum _MenuAction {
  goHome,
  resetHome,
  signin,
  signup,
  verify,
  demographics,
  identity,
  connect,
}

class _MenuCard extends StatelessWidget {
  final List<Object /* _Item | _Divider */ > items;
  final VoidCallback onClose;
  const _MenuCard({required this.items, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface.withOpacity(.9);
    return Card(
      elevation: 6,
      color: surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final it in items)
                it is _Divider
                    ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Divider(height: 1),
                )
                    : _MenuTile(item: it as _Item, onClose: onClose, color: onSurface),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final _Item item;
  final VoidCallback onClose;
  final Color color;
  const _MenuTile({required this.item, required this.onClose, required this.color});

  void _handle() {
    if (kReleaseMode) return;
    switch (item.action) {
      case _MenuAction.goHome:
        nav?.pushNamed(RoutePaths.home);
        break;
      case _MenuAction.resetHome:
        gotoHomeAndClear(RoutePaths.home);
        break;
      case _MenuAction.signin:
        nav?.pushReplacementNamed(RoutePaths.signin);
        break;
      case _MenuAction.signup:
        nav?.pushReplacementNamed(RoutePaths.signup);
        break;
      case _MenuAction.verify:
        nav?.pushNamed(RoutePaths.verify);
        break;
      case _MenuAction.demographics:
        nav?.pushNamed(RoutePaths.demographics);
        break;
      case _MenuAction.identity:
        nav?.pushNamed(RoutePaths.identity);
        break;
      case _MenuAction.connect:
        nav?.pushNamed(RoutePaths.connect);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: Icon(item.icon, size: 18, color: color),
      title: Text(item.label, style: TextStyle(fontSize: 13.5, color: color)),
      onTap: () {
        onClose();
        _handle();
      },
    );
  }
}

class _Item {
  final String label;
  final IconData icon;
  final _MenuAction action;
  const _Item(this.label, this.icon, this.action);
}

class _Divider {
  const _Divider();
}
