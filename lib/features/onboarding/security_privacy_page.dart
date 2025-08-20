import 'package:flutter/material.dart';
import '../../routing/route_paths.dart';
import '../auth/components/submit_buttons.dart';
import '../../core/widgets/dev_fab_navigator.dart';

class SecurityPrivacyPage extends StatelessWidget {
  const SecurityPrivacyPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: const DevFabNavigator(),
      appBar: AppBar(title: const Text('Security & Privacy')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('We protect your data. You can export or delete data anytime in Profile → Privacy Dashboard.'),
            const Spacer(),
            PrimarySubmitButton(label: 'Continue', onPressed: ()=>Navigator.pushNamed(context, RoutePaths.connect)),
          ],
        ),
      ),
    );
  }
}
