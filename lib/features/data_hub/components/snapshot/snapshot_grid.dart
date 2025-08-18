// ignore_for_file: avoid_renaming_method_parameters
import 'package:flutter/material.dart';
import 'snapshot_card.dart';

class SnapshotGrid extends StatelessWidget {
  final void Function(String metric) onOpenMetric;
  const SnapshotGrid({super.key, required this.onOpenMetric});
  @override
  Widget build(BuildContext c) => GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.25,
        children: [
          SnapshotCard(
              title: 'Sleep',
              bigValue: '7h 42m',
              unit: '',
              source: 'Oura',
              freshness: 'green',
              onTap: () => onOpenMetric('Sleep')),
          SnapshotCard(
              title: 'HRV',
              bigValue: '64',
              unit: 'ms',
              source: 'Oura',
              freshness: 'green',
              onTap: () => onOpenMetric('HRV')),
          SnapshotCard(
              title: 'Steps',
              bigValue: '8,410',
              unit: '',
              source: 'Apple',
              freshness: 'yellow',
              onTap: () => onOpenMetric('Steps')),
          SnapshotCard(
              title: 'RHR',
              bigValue: '54',
              unit: 'bpm',
              source: 'Oura',
              freshness: 'green',
              onTap: () => onOpenMetric('RHR')),
        ],
      );
}

