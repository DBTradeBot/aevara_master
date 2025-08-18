// ignore_for_file: avoid_renaming_method_parameters
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dev_route_registry.dart';

class DevRouteSheet extends StatefulWidget {
  const DevRouteSheet({super.key});
  @override
  State<DevRouteSheet> createState() => _DevRouteSheetState();
}

class _DevRouteSheetState extends State<DevRouteSheet> {
  String _q = '';
  @override
  Widget build(BuildContext c) {
    final kids = <Widget>[];
    kDevRouteGroups.forEach((group, routes) {
      final filtered = routes
          .where((r) => r.toLowerCase().contains(_q.toLowerCase()))
          .toList();
<<<<<<< Updated upstream
      if (filtered.isEmpty) return;
=======
if (filtered.isEmpty) return
>>>>>>> Stashed changes
      kids.add(Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(group,
              style: const TextStyle(fontWeight: FontWeight.w600))));
      for (final r in filtered) {
        kids.add(ListTile(
            dense: true,
            title: Text(r),
            onTap: () {
              Navigator.of(c).pop();
              Navigator.of(c).pushNamed(r);
            }));
      }
    });
    return SafeArea(
        child: SizedBox(
            height: MediaQuery.of(c).size.height * .9,
            child: Column(children: [
              const SizedBox(height: 8),
              Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(3))),
              const SizedBox(height: 12),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                      decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Search routes...'),
                      onChanged: (v) => setState(() => _q = v))),
              const SizedBox(height: 8),
              Expanded(child: ListView(children: kids)),
<<<<<<< Updated upstream
              if (!kDebugMode)
                const Padding(
                    padding: EdgeInsets.all(8), child: Text('Debug disabled')),
            ])));
  }
}

=======
if (!kDebugMode) const Padding(
                    padding: EdgeInsets.all(8), child: Text('Debug disabled')),
            ])))
  }
}



>>>>>>> Stashed changes
