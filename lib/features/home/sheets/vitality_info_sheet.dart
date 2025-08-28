// lib/features/home/sheets/vitality_info_sheet.dart
//
// Vitality Info "Center Sheet" — opened by tapping the Vitality Age gauge
// Trend section with 14/30/60/90 day toggle + dual-line chart.
// Consistent Y scale across ranges, axis labels, interactive tap/drag bubble,
// and a card backplate with elevation.
//
// Update (stack request):
// - LEFT: stack two separate chips (Confidence w/ elevation, then Δ yrs).
// - RIGHT: a single combined stats card (no separate right-side elevation),
//          stacking "Your age" on top, "Vitality Age" below.
// - Removed the tiny anchored badges from stat cards.
// - Kept the rest of the sheet content unchanged.
//
// Notes:
// - Confidence chip is clearly tappable (Material + elevation + stronger bg).
// - Δ-yrs pill is calmer, below Confidence.
//
// Brand-aware colors come from theme tokens (secondaryContainer/onSecondaryContainer).
// If you want a hard brand color, swap bg in _ConfidencePillElevated.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../charts/delta_bar.dart';           // chart + VitalityPoint
import 'confidence_info_sheet.dart';              // existing

class VitalityInfoSheet extends StatefulWidget {
  const VitalityInfoSheet({
    super.key,
    this.vitalityAge,
    this.chronologicalAge,
    this.healthyYears,
    this.scores,
    this.weightsUsed,
    this.staleDays,
    this.confidence,
    this.constants,

    // optional full history (unsorted ok)
    this.history,
  });

  final double? vitalityAge;
  final double? chronologicalAge;
  final double? healthyYears;

  // Optional transparency passed from VM (not rendered in MVP sheet)
  final Map<String, int>? scores;          // 0..100 per domain
  final Map<String, double>? weightsUsed;  // raw
  final Map<String, int>? staleDays;       // days since last fresh per domain
  final int? confidence;                   // 0..100 (header chip)
  final Map<String, num>? constants;       // pivot_risk, scale_years, etc.

  // NEW
  final List<VitalityPoint>? history;

  /// Show as a centered modal dialog (not a bottom sheet).
  static Future<void> show(
      BuildContext context, {
        double? vitalityAge,
        double? chronologicalAge,
        double? healthyYears,
        Map<String, int>? scores,
        Map<String, double>? weightsUsed,
        Map<String, int>? staleDays,
        int? confidence,
        Map<String, num>? constants,
        List<VitalityPoint>? history,
      }) {
    final theme = Theme.of(context);
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: theme.colorScheme.scrim.withOpacity(0.45),
      builder: (ctx) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: _CenterSheetChrome(
              child: VitalityInfoSheet(
                vitalityAge: vitalityAge,
                chronologicalAge: chronologicalAge,
                healthyYears: healthyYears,
                scores: scores,
                weightsUsed: weightsUsed,
                staleDays: staleDays,
                confidence: confidence,
                constants: constants,
                history: history,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  State<VitalityInfoSheet> createState() => _VitalityInfoSheetState();
}

class _VitalityInfoSheetState extends State<VitalityInfoSheet> {
  static const List<int> _ranges = [14, 30, 60, 90];
  int _rangeDays = 30;

  // Expand/collapse state for the info blurb
  bool _infoExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final vAge = widget.vitalityAge?.isFinite == true ? widget.vitalityAge! : double.nan;
    final cAge = widget.chronologicalAge?.isFinite == true ? widget.chronologicalAge! : double.nan;
    final hy = widget.healthyYears?.isFinite == true ? widget.healthyYears! : double.nan;

    final younger = hy.isFinite ? hy > 0.05 : false;
    final older = hy.isFinite ? hy < -0.05 : false;

    final deltaStr = hy.isFinite ? hy.abs().toStringAsFixed(1) : '—';
    final vAgeStr = vAge.isFinite ? vAge.toStringAsFixed(1) : '—';
    final cAgeStr = cAge.isFinite ? cAge.toStringAsFixed(0) : '—';

    final Color deltaColor =
    younger ? const Color(0xFF24A699) : (older ? const Color(0xFFBF4A4A) : theme.colorScheme.primary);

    final Color bgPill = isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04);

    // Prepare history (optional)
    final List<VitalityPoint>? full = widget.history == null || widget.history!.isEmpty
        ? null
        : (List<VitalityPoint>.from(widget.history!)..sort((a, b) => a.date.compareTo(b.date)));

    // Global Y-domain from full history so all ranges share the same scale
    double? globalMin, globalMax;
    if (full != null && full.length >= 2) {
      globalMin = full.map((p) => math.min(p.vitalityAge, p.chronoAge)).reduce(math.min);
      globalMax = full.map((p) => math.max(p.vitalityAge, p.chronoAge)).reduce(math.max);
      final span = (globalMax - globalMin).abs();
      if (span < 0.25) {
        globalMin -= 0.5;
        globalMax += 0.5;
      } else {
        final pad = span * 0.06;
        globalMin -= pad;
        globalMax += pad;
      }
    }

    final List<VitalityPoint>? sliced = _sliceHistory(full, _rangeDays);

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenH = MediaQuery.of(context).size.height;
        final targetH = screenH * 0.82;
        return Semantics(
          label: 'Vitality details',
          explicitChildNodes: true,
          child: SizedBox(
            height: targetH,
            child: Material(
              color: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: theme.brightness == Brightness.dark
                          ? Colors.white.withOpacity(0.08)
                          : Colors.black.withOpacity(0.06),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header row (title + close)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 8, 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Vitality details',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  height: 1.2,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Close',
                              onPressed: () => Navigator.of(context).maybePop(),
                              icon: const Icon(Icons.close_rounded),
                              splashRadius: 22,
                            ),
                          ],
                        ),
                      ),

                      // ===== NEW HEADER LAYOUT =====
                      // LEFT: stacked chips (confidence elevated, then delta)
                      // RIGHT: single combined stat card (Your age on top, Vitality Age below)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // LEFT chips column
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (widget.confidence != null)
                                  _ConfidencePillElevated(confidence: widget.confidence!),
                                if (vAge.isFinite && cAge.isFinite && hy.isFinite) ...[
                                  const SizedBox(height: 10),
                                  _DeltaPill(
                                    deltaStr: deltaStr,
                                    younger: younger,
                                    older: older,
                                    bg: bgPill,
                                    fg: deltaColor,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(width: 16),

                            // RIGHT combined stats card
                            Expanded(
                              child: _StatsCombinedCard(
                                yourAgeStr: cAgeStr,
                                vitalityAgeStr: vAgeStr,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // ===== END NEW HEADER LAYOUT =====

                      const Divider(height: 1),

                      // Scrollable body
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Expandable "Learn more" blurb (between the two dividers)
                              _ExpandableInfoCard(
                                expanded: _infoExpanded,
                                onToggle: () => setState(() => _infoExpanded = !_infoExpanded),
                                collapsedText:
                                'Vitality Age is your body’s functional age — a daily snapshot from recovery, sleep, activity, and wellbeing.',
                                fullText:
                                'Vitality Age is your body’s functional age, estimated from recovery, sleep, activity, and wellbeing. '
                                    'It updates day by day as a snapshot of today — but the real story comes from trends over weeks.\n\n'
                                    'We use a transparent model that weighs HRV, resting heart rate, sleep patterns, steps, and your wellbeing score. '
                                    'When available, we also include VO₂max and other metrics for added precision — the more inputs we have, the more accurate your score becomes.\n\n'
                                    'Onboarding includes a 14-day calibration to adjust for your personal baselines, so early values may shift slightly as your data stabilizes.\n\n'
                                    'Vitality Age is not a diagnosis. It’s a science-based indicator to help you see how daily choices influence long-term health.',
                              ),

                              const Divider(height: 1),

                              // Trend section
                              const SizedBox(height: 12),
                              Text(
                                'Trend (last ${_dynamicDaysLabel})',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: theme.textTheme.bodyMedium?.color,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _RangeToggle(
                                ranges: _ranges,
                                selected: _rangeDays,
                                onChanged: (v) => setState(() => _rangeDays = v),
                              ),
                              const SizedBox(height: 10),
                              if (sliced != null && sliced.length >= 2)
                                _ChartCard(
                                  child: DeltaBar(
                                    points: sliced,
                                    height: 200,
                                    fixedMinY: globalMin,
                                    fixedMaxY: globalMax,
                                  ),
                                )
                              else
                                const _ChartPlaceholder(height: 180),

                              const SizedBox(height: 16),
                              const Divider(height: 1),

                              // Static “what goes into this”
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'What goes into this',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: theme.textTheme.bodyMedium?.color,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const _Bullets(
                                items: [
                                  'Recovery (HRV ↑, Resting HR ↓)',
                                  'Sleep (duration ± regularity)',
                                  'Activity (steps; saturates by ~12k)',
                                  'Wellbeing (single 1–5; 5 is worse)',
                                  'Optional CRF/VO₂max (slow anchor)',
                                ],
                              ),

                              const SizedBox(height: 16),

                              // CTA row
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Tip: trends tell the story. Watch Vitality over weeks, not days.',
                                      style: GoogleFonts.inter(
                                        fontSize: 12.5,
                                        color: theme.textTheme.bodySmall?.color?.withOpacity(0.9),
                                      ),
                                    ),
                                  ),
                                  FilledButton.icon(
                                    onPressed: () {
                                      Navigator.of(context).maybePop();
                                      // TODO: Navigator.pushNamed(context, RoutePaths.insights, arguments: {...});
                                    },
                                    icon: const Icon(Icons.insights_outlined),
                                    label: const Text('See drivers & trends'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String get _dynamicDaysLabel => '$_rangeDays days';

  static List<VitalityPoint>? _sliceHistory(List<VitalityPoint>? full, int days) {
    if (full == null || full.length < 2) return null;
    final end = full.last.date;
    final startCutoff = end.subtract(Duration(days: days));
    final sliced = full.where((p) => !p.date.isBefore(startCutoff)).toList();
    if (sliced.length >= 2) return sliced;
    final n = full.length >= 2 ? _mathMax(2, _mathMin(full.length, 8)) : 0;
    if (n == 0) return null;
    return full.sublist(full.length - n);
  }

  static int _mathMax(int a, int b) => a > b ? a : b;
  static int _mathMin(int a, int b) => a < b ? a : b;

  // Kept for reference, but not shown anymore:
  static String? _constantsLine(Map<String, num>? c) {
    if (c == null || c.isEmpty) return null;
    final pivot = c['pivot_risk'];
    final scale = c['scale_years'];
    if (pivot == null && scale == null) return null;
    final p = pivot != null ? 'pivot ${pivot.toStringAsFixed(3)}' : null;
    final s = scale != null ? 'scale ${scale.toStringAsFixed(1)}y' : null;
    final combo = [p, s].whereType<String>().join(' • ');
    return combo.isEmpty ? null : 'Model constants: $combo';
  }
}

class _CenterSheetChrome extends StatelessWidget {
  const _CenterSheetChrome({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: child,
    );
  }
}

/// Single combined stats card (right side):
/// - Your age (top, large)
/// - Vitality Age (bottom, large)
class _StatsCombinedCard extends StatelessWidget {
  const _StatsCombinedCard({
    required this.yourAgeStr,
    required this.vitalityAgeStr,
  });

  final String yourAgeStr;
  final String vitalityAgeStr;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final Color bg = isDark ? const Color(0xFF1F2A32) : const Color(0xFFF7F9FB);
    final Color border = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 1),
        // one shadow for the whole card (no separate right elevation)
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.16),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.18),
            blurRadius: 36,
            spreadRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Your age (top)
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                yourAgeStr,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Your age',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Vitality Age (bottom)
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                vitalityAgeStr,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Vitality Age',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Elevated, tappable confidence chip.
/// Uses theme secondaryContainer for strong, readable contrast.
class _ConfidencePillElevated extends StatelessWidget {
  const _ConfidencePillElevated({required this.confidence});
  final int confidence;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color bg = theme.colorScheme.secondaryContainer;
    final Color fg = theme.colorScheme.onSecondaryContainer;

    return Material(
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.25),
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () async {
          // Close the center dialog first
          final rootNav = Navigator.of(context, rootNavigator: true);
          if (rootNav.canPop()) rootNav.pop();
          await Future<void>.delayed(const Duration(milliseconds: 30));
          await showModalBottomSheet<void>(
            context: context,
            useRootNavigator: true,
            useSafeArea: true,
            isScrollControlled: true,
            backgroundColor: theme.colorScheme.surface,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (ctx) => const ConfidenceInfoSheet(),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: fg.withOpacity(0.16),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_rounded, size: 16, color: fg),
              const SizedBox(width: 6),
              Text(
                'Confidence: $confidence%',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Compact delta badge for "younger/older" pill (reused below the confidence chip)
class _DeltaPill extends StatelessWidget {
  const _DeltaPill({
    required this.deltaStr,
    required this.younger,
    required this.older,
    required this.bg,
    required this.fg,
  });

  final String deltaStr;
  final bool younger;
  final bool older;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    final prefix = younger ? '−' : (older ? '+' : '±');
    final suffix = younger ? ' younger' : (older ? ' older' : '');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            younger
                ? Icons.arrow_downward_rounded
                : (older ? Icons.arrow_upward_rounded : Icons.remove_rounded),
            size: 16,
            color: fg,
          ),
          const SizedBox(width: 6),
          Text(
            '$prefix$deltaStr yrs$suffix',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

// Expandable info section (collapsed summary -> full description)
class _ExpandableInfoCard extends StatelessWidget {
  const _ExpandableInfoCard({
    required this.expanded,
    required this.onToggle,
    required this.collapsedText,
    required this.fullText,
  });

  final bool expanded;
  final VoidCallback onToggle;
  final String collapsedText;
  final String fullText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.brightness == Brightness.dark
            ? const Color(0xFF243039)
            : const Color(0xFFF4F7FA),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Learn about Vitality Age',
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ),
                  Icon(expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Text(
                collapsedText,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  height: 1.4,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
            ),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Text(
                fullText,
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  height: 1.5,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
            ),
            crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
            firstCurve: Curves.easeOutCubic,
            secondCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }
}

class _Bullets extends StatelessWidget {
  const _Bullets({required this.items});
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: items
          .map(
            (t) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6.5),
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.75),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  t,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.35,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ),
            ),
          ],
        ),
      )
          .toList(),
    );
  }
}

class _RangeToggle extends StatelessWidget {
  const _RangeToggle({
    required this.ranges,
    required this.selected,
    required this.onChanged,
  });

  final List<int> ranges;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: ranges
          .map(
            (d) => ChoiceChip(
          label: Text('$d d'),
          selected: d == selected,
          onSelected: (_) => onChanged(d),
          labelStyle: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      )
          .toList(),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? const Color(0xFF1F2A32)
            : const Color(0xFFF7F9FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.35 : 0.16),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.18),
            blurRadius: 36,
            spreadRadius: 8,
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ChartPlaceholder extends StatelessWidget {
  const _ChartPlaceholder({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.brightness == Brightness.dark
            ? const Color(0xFF243039)
            : const Color(0xFFF4F7FA),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Text(
        'No recent trend to show',
        style: GoogleFonts.inter(
          fontSize: 12.5,
          color: theme.textTheme.bodySmall?.color?.withOpacity(0.9),
        ),
      ),
    );
  }
}
