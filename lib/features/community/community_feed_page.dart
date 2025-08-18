<<<<<<< Updated upstream
﻿// ignore_for_file: avoid_renaming_method_parameters
=======
// ignore_for_file: avoid_renaming_method_parameters
>>>>>>> Stashed changes
import 'package:flutter/material.dart';
import '../../core/tiles/feed_item_tile.dart';
import '../../core/utils/snack.dart';

class CommunityFeedPage extends StatefulWidget {
  const CommunityFeedPage({super.key});
  @override
  State<CommunityFeedPage> createState() => _CommunityFeedPageState();
<<<<<<< Updated upstream
=======
}

class _CommunityFeedPageState extends State<CommunityFeedPage> {
  int cheers = 0;
  @override
  Widget build(BuildContext c) => Scaffold(
      appBar: AppBar(title: const Text('Community Feed')),
      body: ListView(children: [
        FeedItemTile(
            title: '@alex earned a Sleep Streak badge',
            subtitle: '7 nights in a row',
            onCheer: () {
              setState(() => cheers++);
              snack(c, 'Cheered! ($cheers)');
            }),
        const Divider(),
        FeedItemTile(
            title: '@sam joined 10% Steps challenge',
            subtitle: 'Let\'s go!',
            onCheer: () {
              setState(() => cheers++);
              snack(c, 'Cheered! ($cheers)');
            }),
        const Divider(),
        FeedItemTile(
            title: '@jules completed +30 min Sleep experiment',
            subtitle: 'Great job',
            onCheer: () {
              setState(() => cheers++);
              snack(c, 'Cheered! ($cheers)');
            }),
      ]));
>>>>>>> Stashed changes
}

class _CommunityFeedPageState extends State<CommunityFeedPage> {
  int cheers = 0;
  @override
  Widget build(BuildContext c) => Scaffold(
      appBar: AppBar(title: const Text('Community Feed')),
      body: ListView(children: [
        FeedItemTile(
            title: '@alex earned a Sleep Streak badge',
            subtitle: '7 nights in a row',
            onCheer: () {
              setState(() => cheers++);
              snack(c, 'Cheered! ($cheers)');
            }),
        const Divider(),
        FeedItemTile(
            title: '@sam joined 10% Steps challenge',
            subtitle: 'Let\'s go!',
            onCheer: () {
              setState(() => cheers++);
              snack(c, 'Cheered! ($cheers)');
            }),
        const Divider(),
        FeedItemTile(
            title: '@jules completed +30 min Sleep experiment',
            subtitle: 'Great job',
            onCheer: () {
              setState(() => cheers++);
              snack(c, 'Cheered! ($cheers)');
            }),
      ]));
}

