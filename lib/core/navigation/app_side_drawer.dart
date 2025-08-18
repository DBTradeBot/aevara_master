<<<<<<< Updated upstream
﻿// ignore_for_file: avoid_renaming_method_parameters
=======
// ignore_for_file: avoid_renaming_method_parameters
>>>>>>> Stashed changes
import 'package:aevara_app/core/navigation/routes.dart';
import 'package:flutter/material.dart';

class AppSideDrawer extends StatelessWidget {
  const AppSideDrawer({super.key});
  @override
  Widget build(BuildContext c) => Drawer(
          child: SafeArea(
              child: ListView(children: [
        const UserAccountsDrawerHeader(
            accountName: Text('Aevara User'),
            accountEmail: Text('@username'),
            currentAccountPicture: CircleAvatar(child: Icon(Icons.person))),
        ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () => Navigator.pushNamed(c, AevaraRoutes.settingsPanel)),
        ListTile(
            leading: const Icon(Icons.devices),
            title: const Text('Devices'),
            onTap: () => Navigator.pushNamed(c, AevaraRoutes.devices)),
        ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy & Data'),
            onTap: () => Navigator.pushNamed(c, AevaraRoutes.privacyDash)),
        const Divider(),
        ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            onTap: () => Navigator.pushNamed(c, AevaraRoutes.about)),
        ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms'),
            onTap: () => Navigator.pushNamed(c, AevaraRoutes.terms)),
        ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            onTap: () => Navigator.pushNamed(c, AevaraRoutes.privacy)),
        const Divider(),
        ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            onTap: () => Navigator.pushNamedAndRemoveUntil(
                c, AevaraRoutes.signIn, (_) => false)),
      ])));
}

