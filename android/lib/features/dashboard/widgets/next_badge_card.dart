import 'package:flutter/material.dart';

class NextBadgeCard extends StatelessWidget {
  const NextBadgeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("Your next milestone", style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            LinearProgressIndicator(value: 0.7),
            SizedBox(height: 8),
            Text("70% complete – keep it up!"),
          ],
        ),
      ),
    );
  }
}
