import 'package:flutter/material.dart';
import '../../data/mock_community_data.dart';
import '../../widgets/club_card.dart';

class ClubsPage extends StatelessWidget {
  const ClubsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clubs')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: demoClubs.length,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ClubCard(
            club: demoClubs[i],
            // width: null -> full width in vertical list
            onTap: () {},
          ),
        ),
      ),
    );
  }
}
