import 'package:flutter/material.dart';

class ConnectPage extends StatelessWidget {
  const ConnectPage({super.key});

  @override
  Widget build(BuildContext context) {
    final providers = <({String name, IconData icon})>[
      (name: 'Apple Health', icon: Icons.apple),
      (name: 'Google Fit', icon: Icons.android),
      (name: 'Fitbit', icon: Icons.watch_outlined),
      (name: 'WHOOP', icon: Icons.fitness_center),
      (name: 'Garmin', icon: Icons.gps_fixed),
      (name: 'Oura', icon: Icons.brightness_2_outlined),
      (name: 'Polar', icon: Icons.snowshoeing),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Connect devices')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Connect one or more providers. You can manage permissions later in Settings.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),

            // >>> Replaces Wrap-with-cards with a bounded GridView <<<
            GridView.builder(
              shrinkWrap: true, // let ListView size it
              physics: const NeverScrollableScrollPhysics(), // single scroller
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                // fixed item height so the sliver can lay out children deterministically
                mainAxisExtent: 150,
              ),
              itemCount: providers.length,
              itemBuilder: (context, i) {
                final p = providers[i];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(p.icon, size: 28),
                        const SizedBox(height: 8),
                        Text(
                          p.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        // Button gets a width via SizedBox so no unbounded constraints
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Connect ${p.name} (stub)')),
                              );
                            },
                            child: const Text('Connect'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back'),
                ),
                FilledButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/onboarding/ready'),
                  child: const Text('Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
