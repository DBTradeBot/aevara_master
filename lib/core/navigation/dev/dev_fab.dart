// ignore_for_file: avoid_renaming_method_parameters
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dev_route_sheet.dart';

class DevFab extends StatelessWidget {
  const DevFab({super.key});
  @override
  Widget build(BuildContext c) {
<<<<<<< Updated upstream
    if (!kDebugMode) return const SizedBox.shrink();
=======
if (!kDebugMode) return const SizedBox.shrink()
>>>>>>> Stashed changes
    return FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
              context: c,
              isScrollControlled: true,
              useSafeArea: true,
              shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(24))),
              builder: (_) => const DevRouteSheet());
        },
        child: const Icon(Icons.bug_report));
  }
}

<<<<<<< Updated upstream
=======


>>>>>>> Stashed changes
