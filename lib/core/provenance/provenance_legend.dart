<<<<<<< Updated upstream
﻿// ignore_for_file: avoid_renaming_method_parameters
=======
// ignore_for_file: avoid_renaming_method_parameters
>>>>>>> Stashed changes
import 'package:flutter/material.dart';
import 'provenance_badge.dart';

class ProvenanceLegend extends StatelessWidget {
  const ProvenanceLegend({super.key});
  @override
  Widget build(BuildContext c) => const Wrap(spacing: 8, children: [
        ProvenanceBadge(provenance: Provenance.manual),
        ProvenanceBadge(provenance: Provenance.synced),
        ProvenanceBadge(provenance: Provenance.estimated),
      ]);
}
<<<<<<< Updated upstream

=======
>>>>>>> Stashed changes
