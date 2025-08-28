// lib/core/widgets/avatar/coach_insights_overlay.dart
//
// CoachInsightsOverlay — anchored, free-floating drop-down panel
// that opens under an avatar (or any anchor) and overlays the app.
// Uses CompositedTransformFollower + OverlayEntry with slide+fade.
// Design System: radius 24, padding 16, scrim 35%, tap-outside to dismiss.
//
// Guarantees & UX polish:
// - Left-anchor panel to avatar (target bottom-left -> follower top-left).
// - Clamp width to min(360, screenWidth - horizontal padding).
// - Scrim is interactive only AFTER open animation completes (fixes first-tap close).
// - AnimatedSize wraps content so the panel animates as it grows/shrinks.
// - Scroll activates only when content exceeds available height (no Flexible).

import 'dart:math' as math;
import 'package:flutter/material.dart';

typedef CoachInsightsBuilder = Widget Function(BuildContext context, VoidCallback close);

class CoachInsightsOverlayHandle {
  CoachInsightsOverlayHandle._(this._remove);
  bool _closed = false;
  final Future<void> Function() _remove;

  bool get isOpen => !_closed;

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _remove();
  }
}

Future<CoachInsightsOverlayHandle> showCoachInsightsOverlay({
  required BuildContext context,
  required LayerLink link,
  CoachInsightsBuilder? builder,
  double maxHeightFactor = 0.72, // ~72% of screen height
  EdgeInsets pagePadding = const EdgeInsets.symmetric(horizontal: 16),
  Duration inDuration = const Duration(milliseconds: 180),
  Duration outDuration = const Duration(milliseconds: 140),
}) async {
  final overlay = Overlay.of(context);
  assert(overlay != null, 'No Overlay found in context');
  final route = ModalRoute.of(context);

  LocalHistoryEntry? history;
  final key = GlobalKey<_CoachInsightsOverlayWidgetState>();

  // We’ll create the handle after the entry so we can reference it.
  late final CoachInsightsOverlayHandle handle;

  Future<void> removeEntryAnimated(OverlayEntry e) async {
    try {
      await key.currentState?.animateOut();
    } catch (_) {/* ignore animation errors during teardown */}
    e.remove();
    // Ensure the handle reflects closed state no matter how we arrived here.
    handle._closed = true; // OK within this library/file.
  }

  // Close callback assigned after entry creation to avoid pre-reference.
  void Function()? _requestClose;

  final OverlayEntry entry = OverlayEntry(
    maintainState: true,
    builder: (ctx) => _CoachInsightsOverlayWidget(
      key: key,
      link: link,
      pagePadding: pagePadding,
      maxHeightFactor: maxHeightFactor,
      inDuration: inDuration,
      outDuration: outDuration,
      onRequestClose: () {
        final fn = _requestClose;
        if (fn != null) fn();
      },
      childBuilder: builder ?? (innerCtx, close) => const _DefaultInsightsContent(),
    ),
  );

  // Public handle AFTER entry exists.
  handle = CoachInsightsOverlayHandle._(() async {
    handle._closed = true; // mark closed immediately
    if (history != null) {
      history!.remove(); // triggers onRemove below
    } else {
      await removeEntryAnimated(entry);
    }
  });

  // Internal close (scrim/back) also marks handle closed immediately.
  _requestClose = () {
    handle._closed = true;
    if (history != null) {
      history!.remove();
    } else {
      // Visual teardown (non-blocking)
      // ignore: discarded_futures
      removeEntryAnimated(entry);
    }
  };

  if (route != null) {
    history = LocalHistoryEntry(onRemove: () {
      handle._closed = true;
      // ignore: discarded_futures
      removeEntryAnimated(entry);
    });
    route.addLocalHistoryEntry(history!);
  }

  overlay!.insert(entry);
  return handle;
}

class _CoachInsightsOverlayWidget extends StatefulWidget {
  const _CoachInsightsOverlayWidget({
    super.key,
    required this.link,
    required this.pagePadding,
    required this.maxHeightFactor,
    required this.onRequestClose,
    required this.childBuilder,
    this.inDuration = const Duration(milliseconds: 180),
    this.outDuration = const Duration(milliseconds: 140),
  });

  final LayerLink link;
  final EdgeInsets pagePadding;
  final double maxHeightFactor;
  final Duration inDuration;
  final Duration outDuration;
  final VoidCallback onRequestClose;
  final CoachInsightsBuilder childBuilder;

  @override
  State<_CoachInsightsOverlayWidget> createState() =>
      _CoachInsightsOverlayWidgetState();
}

class _CoachInsightsOverlayWidgetState
    extends State<_CoachInsightsOverlayWidget> with TickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  // Prevent the initial tap-up from dismissing immediately.
  bool _scrimInteractive = false;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: widget.inDuration,
      reverseDuration: widget.outDuration,
    );
    _fade = CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(begin: const Offset(0, -0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic));

    // Arm scrim AFTER open animation completes.
    _ac.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _scrimInteractive = true);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ac.forward();
    });
  }

  Future<void> animateOut() async {
    if (mounted) setState(() => _scrimInteractive = false);
    if (mounted && _ac.status != AnimationStatus.dismissed) {
      await _ac.reverse();
    }
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final theme = Theme.of(context);

    // Hard clamp width so it never pushes off-screen.
    final double panelMaxWidth =
    math.min(360.0, size.width - widget.pagePadding.horizontal);
    final double panelMaxHeight = size.height * widget.maxHeightFactor;

    return Stack(
      children: [
        // Scrim (tap to dismiss) — only interactive after open completes
        Positioned.fill(
          child: FadeTransition(
            opacity: _fade.drive(Tween<double>(begin: 0.0, end: 1.0)),
            child: IgnorePointer(
              ignoring: !_scrimInteractive,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onRequestClose,
                child: Container(color: Colors.black.withOpacity(0.35)),
              ),
            ),
          ),
        ),

        // Anchored dropdown panel — LEFT aligned to avatar
        CompositedTransformFollower(
          link: widget.link,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          offset: const Offset(0, 8), // small visual gap below avatar
          showWhenUnlinked: false,
          child: SlideTransition(
            position: _slide,
            child: FadeTransition(
              opacity: _fade,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: panelMaxWidth,
                  maxHeight: panelMaxHeight,
                ),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    color: theme.colorScheme.surface,
                    elevation: 8,
                    borderRadius: BorderRadius.circular(24),
                    clipBehavior: Clip.antiAlias,
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        // === Animated resize + scroll-on-demand ===
                        child: AnimatedSize(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          alignment: Alignment.topLeft,
                          child: LayoutBuilder(
                            builder: (ctx, constraints) {
                              // Constrain the scrollable content to the available height.
                              final maxH = constraints.maxHeight;
                              return ConstrainedBox(
                                constraints: BoxConstraints(maxHeight: maxH),
                                child: SingleChildScrollView(
                                  primary: false,
                                  child: widget.childBuilder(context, widget.onRequestClose),
                                ),
                              );
                            },
                          ),
                        ),
                        // === end animated resize + scroll-on-demand ===
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// --- Default chat-style content (replace with real insights when wiring) ---

class _DefaultInsightsContent extends StatelessWidget {
  const _DefaultInsightsContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header row
        Row(
          children: [
            Text(
              'Coach',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Close',
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Chat bubbles
        _CoachBubble(
          text: "Today’s snapshot:\n• Vitality Age steady\n• Sleep near optimal\n• Steps trending up",
        ),
        const SizedBox(height: 8),
        _CoachBubble(
          text:
          "Focus: Aim for 7–8h sleep tonight. A 20–30 min Zone 2 session could add ~0.1–0.2 Healthy Days this week.",
        ),
        const SizedBox(height: 12),

        // Quick replies (predetermined responses)
        _QuickReplies(
          replies: const [
            "What changed most?",
            "How confident is this?",
            "Give me a plan",
          ],
          onSelect: (label) {
            // TODO: wire to Riverpod/LLM action
            debugPrint("Quick reply tapped: $label");
          },
        ),
        const SizedBox(height: 8),

        // Feedback bar
        const _FeedbackBar(),
      ],
    );
  }
}

// === Chat UI primitives (private) ===

class _CoachBubble extends StatelessWidget {
  const _CoachBubble({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.7),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
        ),
        child: Text(text, style: theme.textTheme.bodyMedium),
      ),
    );
  }
}

class _QuickReplies extends StatelessWidget {
  const _QuickReplies({required this.replies, required this.onSelect});
  final List<String> replies;
  final void Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: replies
          .map(
            (r) => ActionChip(
          label: Text(r, style: theme.textTheme.bodyMedium),
          onPressed: () => onSelect(r),
        ),
      )
          .toList(),
    );
  }
}

class _FeedbackBar extends StatelessWidget {
  const _FeedbackBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          tooltip: 'Thumbs down',
          icon: const Icon(Icons.thumb_down_alt_outlined),
          onPressed: () {
            // TODO: wire feedback -> analytics / Firestore
            debugPrint("Feedback: thumbs down");
          },
        ),
        IconButton(
          tooltip: 'Thumbs up',
          icon: const Icon(Icons.thumb_up_alt_outlined),
          onPressed: () {
            // TODO: wire feedback -> analytics / Firestore
            debugPrint("Feedback: thumbs up");
          },
        ),
      ],
    );
  }
}
