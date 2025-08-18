import 'package:aevara_app/core/navigation/routes.dart';
import 'package:flutter/material.dart';
import '../../core/tiles/setting_tile.dart';

class SettingsPanelSheetPage extends StatelessWidget {
  const SettingsPanelSheetPage({super.key});
  void _open(BuildContext context) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (_) {
          return DraggableScrollableSheet(
              initialChildSize: .9,
              minChildSize: .5,
              maxChildSize: .95,
              expand: false,
              builder: (ctx, ctrl) {
                return ListView(
                    controller: ctrl,
                    padding: const EdgeInsets.all(8),
                    children: [
                      const SizedBox(height: 8),
                      const Center(
                          child: SizedBox(
                              width: 48, child: Divider(thickness: 4))),
                      const Padding(
                          padding: EdgeInsets.all(8),
                          child: Text('Account',
                              style: TextStyle(fontWeight: FontWeight.w600))),
                      SettingTile(
                          title: 'Profile, Email & Password',
                          onTap: () => Navigator.pushNamed(
                              ctx, AevaraRoutes.accountSettings)),
                      const Padding(
                          padding: EdgeInsets.all(8),
                          child: Text('Devices',
                              style: TextStyle(fontWeight: FontWeight.w600))),
                      SettingTile(
                          title: 'Connected Devices',
                          onTap: () =>
                              Navigator.pushNamed(ctx, AevaraRoutes.devices)),
                      const Padding(
                          padding: EdgeInsets.all(8),
                          child: Text('Notifications',
                              style: TextStyle(fontWeight: FontWeight.w600))),
                      SettingTile(
                          title: 'Notification Preferences',
                          onTap: () => Navigator.pushNamed(
                              ctx, AevaraRoutes.notifications)),
                      const Padding(
                          padding: EdgeInsets.all(8),
                          child: Text('Privacy & Data',
                              style: TextStyle(fontWeight: FontWeight.w600))),
                      SettingTile(
                          title: 'Privacy Dashboard',
                          onTap: () => Navigator.pushNamed(
                              ctx, AevaraRoutes.privacyDash)),
                      SettingTile(
                          title: 'Export My Data',
                          onTap: () =>
                              Navigator.pushNamed(ctx, AevaraRoutes.export)),
                      SettingTile(
                          title: 'Delete My Account',
                          onTap: () => Navigator.pushNamed(
                              ctx, AevaraRoutes.deleteAccount)),
                      const Padding(
                          padding: EdgeInsets.all(8),
                          child: Text('Security',
                              style: TextStyle(fontWeight: FontWeight.w600))),
                      SettingTile(
                          title: '2FA & Sessions',
                          onTap: () => Navigator.pushNamed(
                              ctx, AevaraRoutes.securitySettings)),
                      const Padding(
                          padding: EdgeInsets.all(8),
                          child: Text('About',
                              style: TextStyle(fontWeight: FontWeight.w600))),
                      SettingTile(
                          title: 'About Aevara',
                          onTap: () => Navigator.pushNamed(
                              ctx, AevaraRoutes.aboutSettings)),
                      SettingTile(
                          title: 'Help & Support',
                          onTap: () =>
                              Navigator.pushNamed(ctx, AevaraRoutes.help)),
                      SettingTile(
                          title: 'Terms of Service',
                          onTap: () =>
                              Navigator.pushNamed(ctx, AevaraRoutes.terms)),
                      SettingTile(
                          title: 'Privacy Policy',
                          onTap: () =>
                              Navigator.pushNamed(ctx, AevaraRoutes.privacy)),
                      const SizedBox(height: 16),
                    ]);
              });
        });
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _open(context);
    });
    return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: const Center(
            child: Text('Closing this will return to previous screen.')));
  }
}
