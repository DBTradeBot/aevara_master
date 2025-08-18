// ignore_for_file: avoid_renaming_method_parameters
import 'package:flutter/material.dart';
import 'profile_banner.dart';
import 'quick_links_list.dart';

class SettingsOverlay extends StatelessWidget {
  const SettingsOverlay({super.key});
  @override
  Widget build(BuildContext c) {
    final w = MediaQuery.of(c).size.width;
    final sheetW = w < 600 ? w * 0.75 : 520.0;
    return SizedBox(
        width: sheetW,
        child: SafeArea(
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(children: [
                const SizedBox(height: 6),
                Center(
                    child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                            color: Theme.of(c).colorScheme.outlineVariant,
                            borderRadius: BorderRadius.circular(8)))),
                const SizedBox(height: 12),
                const ProfileBanner(),
                const SizedBox(height: 12),
                const Divider(),
                const QuickLinksList(),
                const Divider(),
                ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Sign out'),
                    onTap: () => Navigator.pop(c)),
              ])),
        ));
  }
}

