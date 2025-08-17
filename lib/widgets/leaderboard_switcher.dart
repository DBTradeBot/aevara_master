import 'package:flutter/material.dart';

/// Compact, overflow-safe switcher for Leaderboards.
/// Uses strings (no enum dependency) to avoid type drift.
///
/// API:
///   - boardType: current value (e.g. "Weekly" | "Monthly" | "All-time")
///   - onBoardType: callback with new value
///   - scope: current value (e.g. "Friends" | "Global" | "Clubs")
///   - onScope: callback with new value
class LeaderboardSwitcher extends StatelessWidget {
  final String boardType;
  final String scope;
  final ValueChanged<String> onBoardType;
  final ValueChanged<String> onScope;

  static const List<String> boardTypeOptions = <String>[
    'Weekly', 'Monthly', 'All-time'
  ];
  static const List<String> scopeOptions = <String>[
    'Friends', 'Global', 'Clubs'
  ];

  const LeaderboardSwitcher({
    super.key,
    required this.boardType,
    required this.onBoardType,
    required this.scope,
    required this.onScope,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium;

    return Material(
      type: MaterialType.transparency,
      child: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 120),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isDense: true,
                value: boardType,
                onChanged: (v) => v != null ? onBoardType(v) : null,
                items: boardTypeOptions
                    .map((bt) => DropdownMenuItem<String>(
                  value: bt,
                  child: Text(bt, style: textStyle),
                ))
                    .toList(),
              ),
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 120),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isDense: true,
                value: scope,
                onChanged: (v) => v != null ? onScope(v) : null,
                items: scopeOptions
                    .map((sc) => DropdownMenuItem<String>(
                  value: sc,
                  child: Text(sc, style: textStyle),
                ))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
