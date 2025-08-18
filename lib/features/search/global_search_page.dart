// ignore_for_file: avoid_renaming_method_parameters
import 'package:flutter/material.dart';

class GlobalSearchPage extends StatefulWidget {
  const GlobalSearchPage({super.key});
  @override
  State<GlobalSearchPage> createState() => _GlobalSearchPageState();
}

class _GlobalSearchPageState extends State<GlobalSearchPage> {
  String q = '';
  @override
  Widget build(BuildContext c) => Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(children: [
        Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search users, badges, challenges...'),
                onChanged: (v) => setState(() => q = v))),
        Expanded(
            child: ListView(children: [
          if (q.isEmpty)
            const ListTile(title: Text('Try searching for "steps"')),
          if (q.isNotEmpty) ListTile(title: Text('Result for: $q'))
        ])),
      ]));
}

