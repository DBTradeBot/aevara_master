// lib/features/onboarding/components/fields.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final _dobFmt = DateFormat('y-MM-dd');

class DobField extends StatefulWidget {
  const DobField({super.key, required this.onChanged, this.initial});
  final ValueChanged<DateTime?> onChanged;
  final DateTime? initial;

  @override
  State<DobField> createState() => _DobFieldState();
}

class _DobFieldState extends State<DobField> {
  DateTime? _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initial;
  }

  Future<void> _pick() async {
    final now = DateTime.now();
    final first = DateTime(now.year - 100, 1, 1);
    final last = now;
    final picked = await showDatePicker(
      context: context,
      initialDate: _value ?? DateTime(now.year - 30, now.month, now.day),
      firstDate: first,
      lastDate: last,
      helpText: 'Date of birth',
    );
    if (picked != null) {
      setState(() => _value = picked);
      widget.onChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _pick,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Date of birth',
          border: UnderlineInputBorder(),
        ),
        child: Text(
          _value == null ? 'Tap to select' : _dobFmt.format(_value!),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
