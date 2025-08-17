import 'package:flutter/material.dart';

class DevMenuPage extends StatelessWidget {
  const DevMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final navs = [
      ('Sign In', '/auth/signin'),
      ('Onboarding Intro', '/onboarding/intro'),
      ('Identity', '/onboarding/identity'),
      ('Demographics', '/onboarding/demographics'),
      ('Username', '/onboarding/username'),
      ('Consent', '/onboarding/consent'),
      ('Connect', '/onboarding/connect'),
      ('Ready', '/onboarding/ready'),
      ('Home Placeholder', '/app/home'),
      ('Data Hub', '/app/data-hub'),
      ('Experiments', '/experiments'),
      ('Community', '/community'),
      ('My Profile', '/profile/me'),
      ('Settings', '/settings'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Dev Menu')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: navs.length,
        separatorBuilder: (_, __)=> const SizedBox(height: 8),
        itemBuilder: (_, i){
          final n = navs[i];
          return Card(child: ListTile(title: Text(n.$1), trailing: const Icon(Icons.chevron_right),
            onTap: ()=> Navigator.pushNamed(context, n.$2)));
        },
      ),
    );
  }
}
