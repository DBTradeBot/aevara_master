import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Expects a provider exposing current tier or entitlement (e.g., 'free'|'plus'|'pro').
/// If missing, we allow access to avoid locking users out during development.
final _fakeTierProvider = Provider<String?>((_) => 'free');

class SubscriptionGuard extends ConsumerWidget {
  const SubscriptionGuard({
    super.key,
    required this.child,
    this.minTier = 'free',
  });

  final Widget child;
  final String minTier;

  bool _meets(String? have, String need) {
    const order = ['free', 'plus', 'pro'];
    final iHave = order.indexOf(have ?? 'free');
    final iNeed = order.indexOf(need);
    if (iHave < 0 || iNeed < 0) return true; // be permissive in dev
    return iHave >= iNeed;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tier = ref.watch(_fakeTierProvider);
    if (_meets(tier, minTier)) return child;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 32),
            const SizedBox(height: 12),
            Text(
              'This feature requires $minTier or higher',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
