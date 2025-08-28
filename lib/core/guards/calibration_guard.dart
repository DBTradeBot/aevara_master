import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Simple gate that hides [child] until calibration is complete.
/// Expect a provider `calibrationStatusProvider` that yields 'pending'|'complete'.
/// If the provider does not exist yet or errors, we render [child] to avoid deadlocks.
final _fakeCalibrationProvider = Provider<String?>((_) => 'complete');

class CalibrationGuard extends ConsumerWidget {
  const CalibrationGuard({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: replace `_fakeCalibrationProvider` with your real provider when ready.
    final status = ref.watch(_fakeCalibrationProvider);
    if (status == 'pending') {
      return const SizedBox.shrink();
    }
    return child;
  }
}
