import 'package:flutter/material.dart';

/// The landing screen. A placeholder until the first drill exists.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('acerta')),
      body: const Center(child: Text('Pair matching is on its way.')),
    );
  }
}
