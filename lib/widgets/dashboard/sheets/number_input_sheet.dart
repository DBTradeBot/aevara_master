import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/aevara_theme.dart';
import 'metric_info_sheet.dart';

class NumberInputSheet extends StatefulWidget {
  // Header
  final String metricName;
  final IconData? metricIcon;

  // Value config
  final String unit;
  final double initialValue;
  final double min;
  final double max;
  final double step;

  // Callbacks
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onSave; // called on Save AND Enter/tap-out
  final VoidCallback? onCancel;

  // Info content
  final String infoWhat;
  final String infoWhy;
  final String? infoWhyLinkLabel;
  final VoidCallback? onOpenInfoWhyLink;
  final String infoHowAffects;
  final String infoWhereToFind;

  const NumberInputSheet({
    super.key,
    required this.metricName,
    this.metricIcon,
    required this.unit,
    required this.initialValue,
    required this.min,
    required this.max,
    required this.step,
    this.onChanged,
    this.onSave,
    this.onCancel,
    required this.infoWhat,
    required this.infoWhy,
    this.infoWhyLinkLabel,
    this.onOpenInfoWhyLink,
    required this.infoHowAffects,
    required this.infoWhereToFind,
  });

  @override
  State<NumberInputSheet> createState() => _NumberInputSheetState();
}

class _NumberInputSheetState extends State<NumberInputSheet> {
  static const double _kControlSize = 40;

  late double _v;
  late final TextEditingController _c;
  final _focus = FocusNode();
  bool _hoverInfo = false;

  Timer? _repeatTimer;

  bool get _hasDecimal => widget.step % 1 != 0;

  @override
  void initState() {
    super.initState();
    _v = widget.initialValue.clamp(widget.min, widget.max);
    _c = TextEditingController(text: _fmt(_v));
    _focus.addListener(() {
      if (!_focus.hasFocus) {
        _finalizeFromText();
        widget.onSave?.call(_v);
      }
    });
  }

  @override
  void dispose() {
    _repeatTimer?.cancel();
    _c.dispose();
    _focus.dispose();
    super.dispose();
  }

  String _fmt(double v) => _hasDecimal ? v.toStringAsFixed(1) : v.toStringAsFixed(0);

  double _roundToStep(double x) {
    if (_hasDecimal) return (x * 10).round() / 10.0;
    return x.roundToDouble();
  }

  void _applyImmediateFromText() {
    final raw = _c.text.trim();
    if (raw.isEmpty || raw == '.' || raw == '-') return;
    final parsed = double.tryParse(raw.replaceAll(',', '.'));
    if (parsed == null) return;
    final next = _roundToStep(parsed).clamp(widget.min, widget.max);
    if (next != _v) {
      setState(() => _v = next);
      widget.onChanged?.call(_v);
    }
  }

  void _finalizeFromText() {
    final raw = _c.text.trim();
    double? parsed = double.tryParse(raw.replaceAll(',', '.'));
    if (parsed == null) parsed = _v;
    final next = _roundToStep(parsed).clamp(widget.min, widget.max);
    setState(() {
      _v = next;
      _c.text = _fmt(_v);
      _c.selection = TextSelection.fromPosition(TextPosition(offset: _c.text.length));
    });
  }

  void _bump(double sign) {
    setState(() {
      _v = (_v + sign * widget.step).clamp(widget.min, widget.max);
      _c.text = _fmt(_v);
      if (_focus.hasFocus) {
        _c.selection = TextSelection.fromPosition(TextPosition(offset: _c.text.length));
      }
    });
    widget.onChanged?.call(_v);
  }

  void _startHold(double sign) {
    HapticFeedback.lightImpact();
    _bump(sign);
    _repeatTimer?.cancel();
    _repeatTimer = Timer.periodic(const Duration(milliseconds: 120), (_) {
      HapticFeedback.selectionClick();
      _bump(sign);
    });
  }

  void _stopHold() {
    _repeatTimer?.cancel();
    _repeatTimer = null;
  }

  void _focusAndSelect() {
    if (!_focus.hasFocus) {
      _focus.requestFocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _c.selection = TextSelection(baseOffset: 0, extentOffset: _c.text.length);
      });
    } else {
      _c.selection = TextSelection(baseOffset: 0, extentOffset: _c.text.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = context.aevara;
    final t = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Material(
          color: a.surface,
          elevation: a.elevation,
          borderRadius: BorderRadius.circular(a.radius),
          shadowColor: a.shadow,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: a.iconMuted.withOpacity(.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Icon(widget.metricIcon ?? Icons.speed, color: a.icon, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.metricName,
                        style: t.textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: .2,
                          color: a.primaryText,
                        ),
                      ),
                    ),
                    MouseRegion(
                      onEnter: (_) => setState(() => _hoverInfo = true),
                      onExit: (_) => setState(() => _hoverInfo = false),
                      child: Tooltip(
                        message: 'About ${widget.metricName}',
                        preferBelow: false,
                        child: InkResponse(
                          radius: 22,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => Container(
                                decoration: BoxDecoration(
                                  color: a.surface,
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(a.radius)),
                                  boxShadow: [BoxShadow(color: a.shadow, blurRadius: 20, offset: const Offset(0, -4))],
                                ),
                                child: MetricInfoSheet(
                                  metricName: widget.metricName,
                                  whatItIs: widget.infoWhat,
                                  whyItMatters: widget.infoWhy,
                                  whyItMattersLinkLabel: widget.infoWhyLinkLabel,
                                  onOpenWhyLink: widget.onOpenInfoWhyLink,
                                  howItAffectsScore: widget.infoHowAffects,
                                  whereToFindIt: widget.infoWhereToFind,
                                ),
                              ),
                            );
                          },
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 120),
                            opacity: _hoverInfo ? 1 : .65,
                            child: Icon(Icons.info_outline, color: a.icon, size: 22),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                Align(
                  alignment: Alignment.center,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _focusAndSelect,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        constraints: const BoxConstraints(minHeight: 72),
                        decoration: BoxDecoration(
                          color: a.surfaceAlt,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: a.iconMuted.withOpacity(.25)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _HoldButton(
                              size: _kControlSize,
                              icon: Icons.remove,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                _bump(-1);
                              },
                              onHoldStart: () => _startHold(-1),
                              onHoldEnd: _stopHold,
                            ),
                            const Spacer(),
                            SizedBox(
                              width: 100,
                              height: _kControlSize + 14,
                              child: Stack(
                                clipBehavior: Clip.none,
                                alignment: Alignment.center,
                                children: [
                                  Transform.translate(
                                    offset: const Offset(0, 1),
                                    child: SizedBox(
                                      width: 80,
                                      child: TextField(
                                        controller: _c,
                                        focusNode: _focus,
                                        textAlign: TextAlign.center,
                                        style: t.textTheme.titleLarge!.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: a.primaryText,
                                          height: 1.0,
                                        ),
                                        autofocus: false,
                                        enableInteractiveSelection: true,
                                        autocorrect: false,
                                        enableSuggestions: false,
                                        textInputAction: TextInputAction.done,
                                        keyboardType: TextInputType.numberWithOptions(
                                          decimal: _hasDecimal,
                                          signed: false,
                                        ),
                                        decoration: const InputDecoration(
                                          isCollapsed: true,
                                          contentPadding: EdgeInsets.zero,
                                          border: InputBorder.none,
                                          enabledBorder: InputBorder.none,
                                          focusedBorder: InputBorder.none,
                                          errorBorder: InputBorder.none,
                                          disabledBorder: InputBorder.none,
                                        ),
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                                        ],
                                        onChanged: (_) => _applyImmediateFromText(),
                                        onSubmitted: (_) {
                                          _finalizeFromText();
                                          HapticFeedback.lightImpact();
                                          widget.onSave?.call(_v);
                                        },
                                        onEditingComplete: () {
                                          _finalizeFromText();
                                          _focus.unfocus();
                                          HapticFeedback.lightImpact();
                                          widget.onSave?.call(_v);
                                        },
                                        onTapOutside: (_) {
                                          _finalizeFromText();
                                          HapticFeedback.lightImpact();
                                          widget.onSave?.call(_v);
                                          FocusScope.of(context).unfocus();
                                        },
                                        onTap: _focusAndSelect,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: -6,
                                    child: Text(
                                      widget.unit,
                                      style: t.textTheme.labelSmall!.copyWith(
                                        color: a.secondaryText,
                                        height: 1.0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            _HoldButton(
                              size: _kControlSize,
                              icon: Icons.add,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                _bump(1);
                              },
                              onHoldStart: () => _startHold(1),
                              onHoldEnd: _stopHold,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          widget.onCancel?.call();
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
                          _finalizeFromText();
                          HapticFeedback.mediumImpact();
                          widget.onSave?.call(_v);
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
        ),
      ),
    );
  }
}

class _HoldButton extends StatefulWidget {
  final double size;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback onHoldStart;
  final VoidCallback onHoldEnd;

  const _HoldButton({
    required this.size,
    required this.icon,
    required this.onTap,
    required this.onHoldStart,
    required this.onHoldEnd,
  });

  @override
  State<_HoldButton> createState() => _HoldButtonState();
}

class _HoldButtonState extends State<_HoldButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final a = context.aevara;
    return GestureDetector(
      onTap: widget.onTap,
      onLongPressStart: (_) {
        setState(() => _pressed = true);
        widget.onHoldStart();
      },
      onLongPressEnd: (_) {
        setState(() => _pressed = false);
        widget.onHoldEnd();
      },
      onLongPressCancel: () {
        setState(() => _pressed = false);
        widget.onHoldEnd();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: a.surface,
          borderRadius: BorderRadius.circular(widget.size / 2),
          border: Border.all(color: a.iconMuted.withOpacity(.25)),
          boxShadow: _pressed
              ? [BoxShadow(color: a.shadow.withOpacity(.4), blurRadius: 6, offset: const Offset(0, 1))]
              : [BoxShadow(color: a.shadow, blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Icon(widget.icon, color: a.icon),
      ),
    );
  }
}
