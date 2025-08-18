import 'package:flutter/material.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool dailyDigest = true;
  bool experimentsReminders = true;
  bool friendRequests = true;
  bool challengeUpdates = true;
  bool emailReports = false;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SwitchListTile(
              title: const Text('Daily snapshot digest'),
              value: dailyDigest,
              onChanged: (v) => setState(() => dailyDigest = v),
            ),
            SwitchListTile(
              title: const Text('Experiment reminders'),
              value: experimentsReminders,
              onChanged: (v) => setState(() => experimentsReminders = v),
            ),
            SwitchListTile(
              title: const Text('Friend requests'),
              value: friendRequests,
              onChanged: (v) => setState(() => friendRequests = v),
            ),
            SwitchListTile(
              title: const Text('Challenge updates'),
              value: challengeUpdates,
              onChanged: (v) => setState(() => challengeUpdates = v),
            ),
            SwitchListTile(
              title: const Text('Weekly email report'),
              value: emailReports,
              onChanged: (v) => setState(() => emailReports = v),
            ),
          ],
        ),
      );
}
