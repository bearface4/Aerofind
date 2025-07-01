import 'package:flutter/material.dart';

class ConsumerFavoritePage extends StatelessWidget {
  const ConsumerFavoritePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Your favorite items go here.',
        style: TextStyle(fontSize: 16),
      ),
    );
  }
}
