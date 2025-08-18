import 'package:flutter/material.dart';

class BaseInputSheet extends StatelessWidget {
  final IconData icon; // NEW: matches your caller
  final String title;
  final String unit;
  final double value;
  final double min;
  final double max;
  final String helper;
  final void Function(BuildContext) onInfo; // expects (ctx) => ...
  final ValueChanged<double> onSave;

  const BaseInputSheet({
    super.key,
    required this.icon,
    required this.title,
    required this.unit,
    required this.value,
    required this.min,
    required this.max,
    required this.helper,
    required this.onInfo,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = TextEditingController(text: value.toStringAsFixed(1));

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header row
                Row(
                  children: [
                    Icon(icon, size: 24, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.info_outline),
                      onPressed: () =>
                          onInfo(context), // pass ctx as your code expects
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // +/- and input
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _RoundIconButton(
                      icon: Icons.remove,
                      onTap: () {
                        final parsed =
                            double.tryParse(controller.text) ?? value;
                        final newValue = (parsed - 0.5).clamp(min, max);
                        controller.text = newValue.toStringAsFixed(1);
                      },
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 88,
                      child: TextField(
                        controller: controller,
                        textAlign: TextAlign.center,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          isDense: true,
                          suffixText: unit,
                          border: const OutlineInputBorder(),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    _RoundIconButton(
                      icon: Icons.add,
                      onTap: () {
                        final parsed =
                            double.tryParse(controller.text) ?? value;
                        final newValue = (parsed + 0.5).clamp(min, max);
                        controller.text = newValue.toStringAsFixed(1);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Helper text
                Text(
                  helper,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final parsed =
                              double.tryParse(controller.text) ?? value;
                          onSave(parsed);
                          Navigator.pop(context);
                        },
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkResponse(
      onTap: onTap,
      radius: 24,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface
              .withOpacity(0.08), // no deprecated surfaceVariant
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 20, color: theme.colorScheme.onSurface),
      ),
    );
  }
}
