// ignore_for_file: avoid_renaming_method_parameters
import 'package:flutter/material.dart';
import 'provider_card.dart';

class ProviderRow extends StatelessWidget {
  const ProviderRow({super.key});
  @override
  Widget build(BuildContext c) => const SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          SizedBox(width: 8),
          SizedBox(
              width: 220,
              child: ProviderCard(
                  name: 'Apple Health',
                  status: 'Connected',
                  icon: Icons.watch)),
          SizedBox(width: 12),
          SizedBox(
              width: 220,
              child: ProviderCard(
                  name: 'Fitbit',
                  status: 'Connected',
                  icon: Icons.directions_walk)),
          SizedBox(width: 12),
          SizedBox(
              width: 220,
              child: ProviderCard(
                  name: 'Garmin',
                  status: 'Not connected',
                  icon: Icons.sports_score)),
          SizedBox(width: 12),
          SizedBox(
              width: 220,
              child: ProviderCard(
                  name: 'WHOOP',
                  status: 'Not connected',
                  icon: Icons.bolt_outlined)),
          SizedBox(width: 12),
          SizedBox(
              width: 220,
              child: ProviderCard(
                  name: 'Oura',
                  status: 'Connected',
                  icon: Icons.nightlight_round)),
          SizedBox(width: 8),
        ]),
      );
}

