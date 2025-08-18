import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aevara_app/theme/aevara_theme.dart';
import 'metric_info_sheet.dart';

/// Combined Mood + Stress selection (1..5) using symbols:
/// 1 Ã°Å¸Å’Â¿ Calm & Happy
/// 2 Ã°Å¸ÂÆ’ Content
/// 3 Ã°Å¸Å’â€œ Neutral
/// 4 Ã¢Å¡Â¡ Tense
/// 5 Ã°Å¸Å’Âª Overwhelmed
///
/// Usage:
/// await showWellbeingSheet(context, initialValue: 3, onSave: (v) { /* persist v (1..5) */ });
Future<void> showWellbeingSheet(
  BuildContext context, {
  required int initialValue, // 1..5
  ValueChanged<int>? onChanged,
  ValueChanged<int>? onSave,
}) {
  final a = context.aevara;
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => Container(
      decoration: BoxDecoration(
        color: a.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(a.radius)),
        boxShadow: [
          BoxShadow(
              color: a.shadow, blurRadius: 24, offset: const Offset(0, -6))
        ],
      ),
      child: _WellbeingSheetBody(
        initialValue: initialValue,
        onChanged: onChanged,
        onSave: onSave,
      ),
    ),
  );
}

class _WellbeingSheetBody extends StatefulWidget {
  final int initialValue;
  final ValueChanged<int>? onChanged;
  final ValueChanged<int>? onSave;

  const _WellbeingSheetBody({
    required this.initialValue,
    this.onChanged,
    this.onSave,
  });

  @override
  State<_WellbeingSheetBody> createState() => _WellbeingSheetBodyState();
}

class _WellbeingSheetBodyState extends State<_WellbeingSheetBody> {
  late int _value; // 1..5

  static const List<_WBItem> _items = <_WBItem>[
    _WBItem(
      value: 1,
      symbol: 'Ã°Å¸Å’Â¿',
      label: 'Calm & Happy',
      shortLabel: 'Calm',
      description: 'Feeling relaxed, positive, and at ease.',
    ),
    _WBItem(
      value: 2,
      symbol: 'Ã°Å¸ÂÆ’',
      label: 'Content',
      shortLabel: 'Content',
      description: 'Generally good mood, low stress, steady.',
    ),
    _WBItem(
      value: 3,
      symbol: 'Ã°Å¸Å’â€œ',
      label: 'Neutral',
      shortLabel: 'Neutral',
      description: 'Balanced state Ã¢â‚¬â€ neither high nor low mood/stress.',
    ),
    _WBItem(
      value: 4,
      symbol: 'Ã¢Å¡Â¡',
      label: 'Tense',
      shortLabel: 'Tense',
      description: 'Noticeable stress, irritability, or restlessness.',
    ),
    _WBItem(
      value: 5,
      symbol: 'Ã°Å¸Å’Âª',
      label: 'Overwhelmed',
      shortLabel: 'Overwhelmed',
      description: 'High stress, low mood, feeling overloaded.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue.clamp(1, 5);
  }

  void _select(int v) {
    if (_value == v) return HapticFeedback.selectionClick();
    setState(() => _value = v);
    widget.onChanged?.call(_value);
  }

  void _openInfo() {
    final a = context.aevara;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: a.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(a.radius)),
          boxShadow: [
            BoxShadow(
                color: a.shadow, blurRadius: 20, offset: const Offset(0, -4))
          ],
        ),
        child: const MetricInfoSheet(
          metricName: 'Wellbeing',
          whatItIs:
              'Your self-rated mental and emotional state today, on a scale from 1 (very poor) to 5 (excellent). '
              'This combines both Mood and Stress into one selection.',
          whyItMatters:
              'Your perceived wellbeing influences stress response, recovery, and long-term health. '
<<<<<<< Updated upstream
              'Itâ€™s a key part of your overall healthy days score.',
=======
              'ItÃ¢â‚¬â„¢s a key part of your overall healthy days score.',
>>>>>>> Stashed changes
          howItAffectsScore:
              'We combine your wellbeing rating with other affective metrics to adjust healthy days. '
              'Low ratings may reduce your score; consistently high ratings improve it.',
          whereToFindIt: 'Symbols and meanings:\n'
<<<<<<< Updated upstream
              'ðŸŒ¿ (1) Calm & Happy â€” Feeling relaxed, positive, and at ease.\n'
              'ðŸƒ (2) Content â€” Generally good mood, low stress, steady.\n'
              'ðŸŒ“ (3) Neutral â€” Balanced state, neither high nor low mood/stress.\n'
              'âš¡ (4) Tense â€” Noticeable stress, irritability, or restlessness.\n'
              'ðŸŒª (5) Overwhelmed â€” High stress, low mood, feeling overloaded.\n\n'
=======
              'Ã°Å¸Å’Â¿ (1) Calm & Happy Ã¢â‚¬â€ Feeling relaxed, positive, and at ease.\n'
              'Ã°Å¸ÂÆ’ (2) Content Ã¢â‚¬â€ Generally good mood, low stress, steady.\n'
              'Ã°Å¸Å’â€œ (3) Neutral Ã¢â‚¬â€ Balanced state, neither high nor low mood/stress.\n'
              'Ã¢Å¡Â¡ (4) Tense Ã¢â‚¬â€ Noticeable stress, irritability, or restlessness.\n'
              'Ã°Å¸Å’Âª (5) Overwhelmed Ã¢â‚¬â€ High stress, low mood, feeling overloaded.\n\n'
>>>>>>> Stashed changes
              'Wearables: WHOOP (Journal), Garmin (Body Battery + Stress), Fitbit (Mindfulness).\n\n'
              'Manual: Reflect on mood, energy, and stress level; choose the number (and symbol) that feels most accurate.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = context.aevara;
    final t = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: a.iconMuted.withOpacity(.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),

            // Header
            Row(
              children: [
                Icon(Icons.favorite, color: a.icon, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Wellbeing',
                    style: t.textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: .2,
                      color: a.primaryText,
                    ),
                  ),
                ),
                // Info (i)
                Tooltip(
                  message: 'About Wellbeing',
                  preferBelow: false,
                  child: InkResponse(
                    radius: 22,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _openInfo();
                    },
                    child: Icon(Icons.info_outline, color: a.icon, size: 22),
                  ),
                ),
                const SizedBox(width: 8),
                // Dropdown selector
                _WellbeingDropdown(value: _value, onSelected: _select),
              ],
            ),

            const SizedBox(height: 16),

            // Row of tappable symbols
            _WellbeingRow(value: _value, onSelected: _select),

            const SizedBox(height: 16),

            _SelectedDescription(value: _value),

            const SizedBox(height: 16),

            // Footer
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      Navigator.of(context).maybePop();
                    },
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: a.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      widget.onSave?.call(_value);
                      Navigator.of(context).maybePop();
                    },
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WellbeingRow extends StatelessWidget {
  final int value;
  final ValueChanged<int> onSelected;

  const _WellbeingRow({required this.value, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final a = context.aevara;
    final t = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _WellbeingSheetBodyState._items.map((it) {
        final isSelected = value == it.value;
        return InkResponse(
          onTap: () => onSelected(it.value),
          radius: 28,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? a.surface : a.surfaceAlt,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? a.primary : a.iconMuted.withOpacity(.25),
                width: isSelected ? 1.4 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                          color: a.shadow,
                          blurRadius: 10,
                          offset: const Offset(0, 2))
                    ]
                  : [],
            ),
            child: Column(
              children: [
                Text(it.symbol,
                    style: const TextStyle(fontSize: 22, height: 1.05)),
                const SizedBox(height: 4),
                Text(
                  it.shortLabel,
                  style:
                      t.textTheme.labelSmall!.copyWith(color: a.secondaryText),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _WellbeingDropdown extends StatelessWidget {
  final int value;
  final ValueChanged<int> onSelected;
  const _WellbeingDropdown({required this.value, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final a = context.aevara;
    const items = _WellbeingSheetBodyState._items;

    return PopupMenuButton<int>(
      tooltip: 'Select state',
      onSelected: onSelected,
      itemBuilder: (context) {
        return items
            .map(
              (it) => PopupMenuItem<int>(
                value: it.value,
                child: Row(
                  children: [
                    Text(it.symbol, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(it.label),
                  ],
                ),
              ),
            )
            .toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: a.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: a.iconMuted.withOpacity(.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(items.firstWhere((e) => e.value == value).symbol,
                style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}

class _SelectedDescription extends StatelessWidget {
  final int value;
  const _SelectedDescription({required this.value});

  @override
  Widget build(BuildContext context) {
    final a = context.aevara;
    final t = Theme.of(context);
    final it =
        _WellbeingSheetBodyState._items.firstWhere((e) => e.value == value);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: a.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: a.iconMuted.withOpacity(.25)),
      ),
      child: Row(
        children: [
          Text(it.symbol, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(it.label,
                    style: t.textTheme.labelLarge!.copyWith(
                        color: a.primaryText, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(it.description,
                    style: t.textTheme.bodySmall!
                        .copyWith(color: a.secondaryText)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WBItem {
  final int value;
  final String symbol;
  final String label; // Full label
  final String shortLabel; // Compact label for chip
  final String description;

  const _WBItem({
    required this.value,
    required this.symbol,
    required this.label,
    required this.shortLabel,
    required this.description,
  });
}
