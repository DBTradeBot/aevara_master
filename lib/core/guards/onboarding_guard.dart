// lib/core/guards/onboarding_guard.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../routing/route_paths.dart';
import '../../state/app_providers.dart';
import '../logic/onboarding_router.dart';

class OnboardingGuard extends ConsumerWidget {
  final Widget child;
  const OnboardingGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authUserProvider);

    return authAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (user) {
        if (user == null) {
          // AuthGuard will already handle redirect to signin.
          return const SizedBox.shrink();
        }

        final uid = user.uid;
        final docRef = FirebaseFirestore.instance.collection('users').doc(uid);

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: docRef.snapshots(),
          builder: (context, snap) {
            // While loading first value, keep a tiny splash
            if (snap.connectionState == ConnectionState.waiting) {
              return const _OnboardingSplash();
            }

            final exists = snap.hasData && snap.data!.exists;
            final data = exists ? snap.data!.data() : null;

            // Decide next step
            final next = computeNextOnboardingRoute(
              firebaseUser: user,
              profileData: data,
            );

            // If onboarding finished and the cache field isn't set, stamp it.
            if (next == null && exists == true) {
              final onboarding = (data?['onboarding'] as Map<String, dynamic>?) ?? const {};
              final completed = onboarding['completed'] == true;
              if (!completed) {
                // best-effort set; no await needed
                docRef.set({
                  'onboarding': {
                    ...onboarding,
                    'completed': true,
                    'updated_at': FieldValue.serverTimestamp(),
                  },
                  'updated_at': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));
              }
            }

            // If we need to route to an onboarding step, do it now.
            if (next != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final current = ModalRoute.of(context)?.settings.name;
                if (current != next) {
                  Navigator.of(context).pushNamedAndRemoveUntil(next, (r) => false);
                }
              });
              return const _OnboardingSplash(); // placeholder while redirecting
            }

            // All good -> show the app shell
            return child;
          },
        );
      },
    );
  }
}

class _OnboardingSplash extends StatelessWidget {
  const _OnboardingSplash();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text('Preparing your setup…', style: t.bodyMedium),
          ],
        ),
      ),
    );
  }
}
