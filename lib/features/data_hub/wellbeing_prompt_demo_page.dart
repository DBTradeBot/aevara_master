<<<<<<< Updated upstream
﻿// ignore_for_file: avoid_renaming_method_parameters
=======
// ignore_for_file: avoid_renaming_method_parameters
>>>>>>> Stashed changes
import 'package:flutter/material.dart';
import 'components/coach/wellbeing_prompt_sheet.dart';

class WellbeingPromptDemoPage extends StatelessWidget {
  const WellbeingPromptDemoPage({super.key});
  @override
  Widget build(BuildContext c) => Scaffold(
      appBar: AppBar(title: const Text('Wellbeing Prompt (Demo)')),
      body: Center(
        child: FilledButton(
            onPressed: () {
              showModalBottomSheet(
                  context: c,
                  isScrollControlled: true,
                  builder: (_) => const WellbeingPromptSheet());
            },
            child: const Text('Open wellbeing sheet')),
      ));
}

