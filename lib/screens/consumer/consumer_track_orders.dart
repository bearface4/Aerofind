import 'package:flutter/material.dart';

class ConsumerTrackOrdersPage extends StatelessWidget {
  const ConsumerTrackOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'You have no active orders.',
        style: TextStyle(fontSize: 16),
      ),
    );
  }
}
