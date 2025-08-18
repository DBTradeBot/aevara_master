import 'package:flutter/material.dart';
import 'package:aevara_app/theme/aevara_theme.dart';

/// Public, named-param API used by callers, e.g. `sheets.section(...)`
Widget section({
  required String title,
  required String whatItIs,
  required String whyItMatters,
  required String howWeCalculateIt,
  required String whereDataComesFrom,
}) {
  return _MetricInfoSection(
    title: title,
    whatItIs: whatItIs,
    whyItMatters: whyItMatters,
    howWeCalculateIt: howWeCalculateIt,
    whereDataComesFrom: whereDataComesFrom,
  );
}

/// Optional: legacy shim so old callsites continue to work
Widget sectionLegacy({
  required String metricName,
  required String whatItIs,
  required String whyItMatters,
  required String howItAffectsScore,
  required String whereToFindIt,
}) {
  return section(
    title: metricName,
    whatItIs: whatItIs,
    whyItMatters: whyItMatters,
    howWeCalculateIt: howItAffectsScore,
    whereDataComesFrom: whereToFindIt,
  );
}

class _MetricInfoSection extends StatelessWidget {
  final String title;
  final String whatItIs;
  final String whyItMatters;
  final String howWeCalculateIt;
  final String whereDataComesFrom;

  const _MetricInfoSection({
    required this.title,
    required this.whatItIs,
    required this.whyItMatters,
    required this.howWeCalculateIt,
    required this.whereDataComesFrom,
  });

  @override
  Widget build(BuildContext context) {
    final a = context.aevara;
    final t = Theme.of(context);

    Widget sect(String heading, String body) => Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(heading,
                  style: t.textTheme.titleSmall!.copyWith(
                      fontWeight: FontWeight.w800, color: a.primaryText)),
              const SizedBox(height: 6),
              Text(body,
                  style:
                      t.textTheme.bodyMedium!.copyWith(color: a.secondaryText)),
            ],
          ),
        );

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: a.iconMuted.withOpacity(.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Title
              Text(title,
                  style: t.textTheme.titleLarge!.copyWith(
                      fontWeight: FontWeight.w900, color: a.primaryText)),

              sect('What it is', whatItIs),
              sect('Why it matters', whyItMatters),
              sect('How we calculate it', howWeCalculateIt),
              sect('Where the data comes from', whereDataComesFrom),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
