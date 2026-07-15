import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

class CustomerMobileScreen extends StatelessWidget {
  const CustomerMobileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enter your mobile number',
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium?.copyWith(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 28),
              TextField(
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: 'Mobile number',
                  prefixIcon: Icon(Icons.phone_android_outlined),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Create user and navigate dashboard.
                  },
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}