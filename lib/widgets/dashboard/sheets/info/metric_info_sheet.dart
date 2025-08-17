import "package:flutter/material.dart";

class MetricInfo {
  final String title;
  final String whatItIs;
  final String whyItMatters;
  final String howWeCalculateIt;
  final String whereDataComesFrom; // now: where users can find/add it

  const MetricInfo({
    required this.title,
    required this.whatItIs,
    required this.whyItMatters,
    required this.howWeCalculateIt,
    required this.whereDataComesFrom,
  });
}

Future<void> showMetricInfo(BuildContext context, MetricInfo info) async {
  final textTheme = Theme.of(context).textTheme;
  Widget section(String title, String body) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(body, style: textTheme.bodyMedium),
          const SizedBox(height: 16),
        ],
      );

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.info_outline),
              const SizedBox(width: 8),
              Text("About ${info.title}", style: textTheme.titleMedium),
            ]),
            const SizedBox(height: 12),
            section("What it is", info.whatItIs),
            section("Why it matters", info.whyItMatters),
            section("How we calculate it", info.howWeCalculateIt),
            section("Where to add/find it", info.whereDataComesFrom),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text("Got it")),
            ),
          ],
        ),
      ),
    ),
  );
}
