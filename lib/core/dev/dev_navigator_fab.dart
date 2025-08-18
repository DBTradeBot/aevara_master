// ignore_for_file: avoid_renaming_method_parameters
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../navigation/routes.dart';
import '../../controllers/theme_controller.dart';

const _devToolsOn =
    bool.fromEnvironment('AEVARA_DEV_TOOLS', defaultValue: true);

class DevNavigatorFab extends StatelessWidget {
  DevNavigatorFab({super.key});
  final List<Map<String, String>> _routes = [
    {'name': 'Sign In', 'route': Routes.signIn},
    {'name': 'Sign Up', 'route': Routes.signUp},
    {'name': 'Forgot', 'route': Routes.forgot},
    {'name': 'Onboarding Ã¢â‚¬Â¢ Basics', 'route': Routes.obBasics},
    {'name': 'Onboarding Ã¢â‚¬Â¢ Goals', 'route': Routes.obGoals},
    {'name': 'Onboarding Ã¢â‚¬Â¢ Avatar', 'route': Routes.obAvatar},
    {'name': 'Onboarding Ã¢â‚¬Â¢ Ready', 'route': Routes.obReady},
    {'name': 'Home', 'route': Routes.home},
    {'name': 'Data Hub', 'route': Routes.dataHub},
    {'name': 'Experiments', 'route': Routes.experiments},
    {'name': 'Community', 'route': Routes.community},
    {'name': 'Metric Details Demo', 'route': Routes.metricDetails},
    {'name': 'Wellbeing Prompt Demo', 'route': Routes.wellbeingPrompt},
    {'name': 'Sync Timeline', 'route': Routes.syncTimeline},
    {'name': 'Feed', 'route': Routes.feed},
    {'name': 'Friends', 'route': Routes.friends},
    {'name': 'Groups', 'route': Routes.groups},
    {'name': 'Badges', 'route': Routes.badges},
    {'name': 'Leaderboards', 'route': Routes.leaderboards},
    {'name': 'Challenges', 'route': Routes.challenges},
    {'name': 'Account', 'route': Routes.account},
    {'name': 'Devices', 'route': Routes.devices},
    {'name': 'Notifications', 'route': Routes.notifications},
    {'name': 'Privacy', 'route': Routes.privacy},
    {'name': 'Security', 'route': Routes.security},
    {'name': 'About', 'route': Routes.about},
    {'name': 'Help', 'route': Routes.help},
    {'name': 'Terms', 'route': Routes.terms},
    {'name': 'Policy', 'route': Routes.policy},
    {'name': 'Search', 'route': Routes.search},
    {'name': 'Inbox', 'route': Routes.inbox},
  ];
  @override
  Widget build(BuildContext c) {
    if (kReleaseMode || !_devToolsOn) return const SizedBox.shrink();
    return FloatingActionButton(
        onPressed: () => _open(c), child: const Icon(Icons.bug_report));
  }

  void _open(BuildContext c) {
    showModalBottomSheet(
        context: c,
        isScrollControlled: true,
        builder: (_) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: _DevNavigatorSheet(routes: _routes)));
  }
}

class _DevNavigatorSheet extends StatefulWidget {
  final List<Map<String, String>> routes;
  const _DevNavigatorSheet({required this.routes});
  @override
  State<_DevNavigatorSheet> createState() => _DevNavigatorSheetState();
}

class _DevNavigatorSheetState extends State<_DevNavigatorSheet> {
  String q = '';
  @override
  Widget build(BuildContext c) {
    final filtered = widget.routes
        .where((m) => m['name']!.toLowerCase().contains(q.toLowerCase()))
        .toList();
    return SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
      Row(children: [
        const Icon(Icons.bug_report),
        const SizedBox(width: 8),
        const Expanded(
            child: Text('Dev Navigator',
                style: TextStyle(fontWeight: FontWeight.w700))),
        IconButton(
            onPressed: () => Navigator.pop(c), icon: const Icon(Icons.close))
      ]),
      const SizedBox(height: 8),
      TextField(
          decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search), hintText: 'Search routesÃ¢â‚¬Â¦'),
          onChanged: (v) => setState(() => q = v)),
      const SizedBox(height: 12),
      Row(children: [
        FilledButton.tonal(
            onPressed: () => ThemeController.mode.value = ThemeMode.light,
            child: const Text('Light')),
        const SizedBox(width: 8),
        FilledButton.tonal(
            onPressed: () => ThemeController.mode.value = ThemeMode.dark,
            child: const Text('Dark')),
        const SizedBox(width: 8),
        FilledButton.tonal(
            onPressed: () => ThemeController.mode.value = ThemeMode.system,
            child: const Text('System')),
      ]),
      const SizedBox(height: 12),
      Flexible(
          child: ListView.builder(
              shrinkWrap: true,
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final r = filtered[i];
                return ListTile(
                    title: Text(r['name']!),
                    subtitle: Text(r['route']!),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, r['route']!);
                    });
              }))
    ]));
  }
}

