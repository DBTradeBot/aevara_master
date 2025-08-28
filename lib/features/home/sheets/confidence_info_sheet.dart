// lib/features/home/sheets/confidence_info_sheet.dart
//
// Bottom sheet that explains Score Confidence and offers quick fixes.
// NOTE: This version removes hard dependencies on ConfidencePanel and
// metric-specific input sheet class names (which varied), so it compiles cleanly
// across your codebase. You can wire providers later to show live % values.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'connect_providers_sheet.dart';

class ConfidenceInfoSheet extends StatelessWidget {
  const ConfidenceInfoSheet({super.key});

  Future<void> _openConnectSheet(BuildContext context) async {
    await HapticFeedback.selectionClick();
    // Explicit <void> removes inference warnings
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const ConnectProvidersSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.verified_user_rounded, color: cs.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Score confidence',
                    style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Explainer card (static copy; safe without providers)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.surfaceVariant.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Confidence tells you how complete and fresh today’s inputs are. '
                      'Higher confidence means your Vitality Age and Healthy Days are based on more recent and complete data.',
                  style: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.35),
                ),
              ),
              const SizedBox(height: 16),

              // Actions
              Text('Boost your confidence today', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ActionButton(
                    icon: Icons.watch_rounded,
                    label: 'Connect device',
                    onTap: () => _openConnectSheet(context),
                  ),
                  // We avoid referencing specific input sheet classes (which vary in naming).
                  // The user can add inputs from the Dashboard tiles; this stays consistent.
                  _ActionButton(
                    icon: Icons.touch_app_rounded,
                    label: 'Add today’s inputs',
                    onTap: () async {
                      await HapticFeedback.selectionClick();
                      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
                      // Guidance: user taps tiles on Dashboard (Sleep, HRV, Steps, Mood, Stress)
                      // If you later expose named routes for input sheets, navigate there here.
                      // Example (if you add it): context.push('/sheets/input');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // How we calculate it (your transparency copy)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: RichText(
                  text: TextSpan(
                    style: textTheme.bodyMedium?.copyWith(color: cs.onSecondaryContainer, height: 1.35),
                    children: const [
                      TextSpan(
                        text: 'How we calculate it\n',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(
                        text:
                        '• Completeness = Σ weights from metrics we observed ÷ Σ all metric weights.\n'
                            '• Freshness penalty: 0% (≤1 day stale), −10% (2–3 days), −25% (≥4 days).\n'
                            '• Final score = round(100 × Completeness × (1 − Weighted Staleness)).',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Methods link
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Navigate to Methods page if you have a named route here.
                  // Example:
                  // context.push('/info/methods_doc');
                },
                icon: const Icon(Icons.menu_book_rounded),
                label: const Text('Methods & Transparency'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceVariant.withOpacity(0.6),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
