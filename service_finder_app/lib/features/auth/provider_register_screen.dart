import 'package:flutter/material.dart';

import 'customer_register_screen.dart';

class ProviderRegisterScreen extends StatelessWidget {
  const ProviderRegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomerRegisterScreen(role: 'Service Provider');
  }
}
