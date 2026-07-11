import 'package:flutter/material.dart';

class ProviderHomeScreen extends StatelessWidget {
  final String userName;
  const ProviderHomeScreen({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome Provider, $userName', style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 20),
            const Text('Your dashboard is under development.'),
          ],
        ),
      ),
    );
  }
}
