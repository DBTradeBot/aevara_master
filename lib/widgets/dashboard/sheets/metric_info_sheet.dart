import 'package:flutter/material.dart';
import 'package:aevara_app/theme/aevara_theme.dart';

class MetricInfoSheet extends StatelessWidget {
  final String metricName;
  final String whatItIs;
  final String whyItMatters;
  final String? whyItMattersLinkLabel;
  final VoidCallback? onOpenWhyLink;
  final String howItAffectsScore;
  final String whereToFindIt;

  const MetricInfoSheet({
    super.key,
    required this.metricName,
    required this.whatItIs,
    required this.whyItMatters,
    this.whyItMattersLinkLabel,
    this.onOpenWhyLink,
    required this.howItAffectsScore,
    required this.whereToFindIt,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final a = context.aevara;

    TextStyle title = t.textTheme.titleMedium!.copyWith(
      fontWeight: FontWeight.w700,
      color: a.primaryText,
    );
    TextStyle body = t.textTheme.bodyMedium!.copyWith(
      color: a.secondaryText,
      height: 1.35,
    );

    Widget section(String titleText, Widget child) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titleText, style: title),
            const SizedBox(height: 6),
            child,
          ],
        );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 12),
            Text('About $metricName',
                style: t.textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.w800, color: a.primaryText)),
            const SizedBox(height: 16),
            section('What it is', Text(whatItIs, style: body)),
            const SizedBox(height: 14),
            section(
              'Why it matters',
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  Text(whyItMatters, style: body),
                  if (onOpenWhyLink != null && whyItMattersLinkLabel != null)
                    TextButton(
                      onPressed: onOpenWhyLink,
                      child: Text(whyItMattersLinkLabel!),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            section('How it affects your score',
                Text(howItAffectsScore, style: body)),
            const SizedBox(height: 14),
            section('Where to find it', Text(whereToFindIt, style: body)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('Got it'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
