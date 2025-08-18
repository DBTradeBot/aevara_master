// ignore_for_file: avoid_renaming_method_parameters
import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String q = '';
  @override
  Widget build(BuildContext c) => Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(children: [
        Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
                onChanged: (v) => setState(() => q = v),
                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search users, badges, challenges...'))),
        Expanded(
            child: ListView(children: [
<<<<<<< Updated upstream
          if (q.isEmpty) const ListTile(title: Text('Try: "steps challenge"')),
          if (q.isNotEmpty)
            ListTile(title: Text('Result for "$q" (placeholder)'))
        ])),
      ]));
}

=======
if (q.isEmpty) const ListTile(title: Text('Try: "steps challenge"')),
          if (q.isNotEmpty)
            ListTile(title: Text('Result for "$q" (placeholder)'))
        ])),
      ]))
}



>>>>>>> Stashed changes
