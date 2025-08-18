import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('About')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Aevara'),
              subtitle: Text('Version 1.0.0 (UI only)'),
            ),
            ListTile(
              leading: Icon(Icons.description_outlined),
              title: Text('Model & scoring'),
              subtitle: Text('Drop your model docs link here.'),
            ),
            ListTile(
              leading: Icon(Icons.contact_support_outlined),
              title: Text('Support'),
              subtitle: Text('support@aevara.app'),
            ),
          ],
        ),
      );
}
