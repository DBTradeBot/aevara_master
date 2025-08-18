import 'package:flutter/material.dart';
import '../../widgets/atoms/aev_text_field.dart';

class IdentityPage extends StatefulWidget {
  const IdentityPage({super.key});

  @override
  State<IdentityPage> createState() => _IdentityPageState();
}

class _IdentityPageState extends State<IdentityPage> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  DateTime? _dob;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year - 13),
      initialDate: DateTime(now.year - 20),
    );
    if (picked != null) {
      setState(() => _dob = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Identity')),
      // Avoid keyboard re-layout weirdness for now; we just scroll:
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Center(
          // Keep a comfortable max width so it looks like your screenshot on wide screens.
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            // Always-scrollable container with a minimal-height Column.
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AevTextField(controller: _first, label: 'First name'),
                  const SizedBox(height: 12),
                  AevTextField(controller: _last, label: 'Last name'),
                  const SizedBox(height: 12),

                  // DOB field Ã¢â‚¬â€œ tap anywhere to pick.
                  InkWell(
                    onTap: _pickDob,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date of birth',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _dob == null
                            ? 'Not set'
                            : _dob!.toLocal().toString().split(' ').first,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Nav actions (no Spacer; no Expanded inside scrollables)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Back'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          '/onboarding/demographics',
                        ),
                        child: const Text('Next'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
