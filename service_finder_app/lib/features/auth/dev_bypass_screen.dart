import 'package:flutter/material.dart';
import '../../core/app_router.dart';

class DevBypassScreen extends StatelessWidget {
  const DevBypassScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final darkRed = const Color(0xFF8B0000);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dev Dashboard Bypass'),
        backgroundColor: darkRed,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Development Preview Mode',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Use these buttons to preview the dashboards without logging into Firebase.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 50),
              _buildBypassButton(
                context,
                label: 'View Customer Dashboard',
                icon: Icons.person,
                color: Colors.blue[700]!,
                onPressed: () {
                  AppRouter.goToCustomerDashboard(context, debugUserName: "Debug User");
                },
              ),
              const SizedBox(height: 20),
              _buildBypassButton(
                context,
                label: 'View Provider Dashboard',
                icon: Icons.work,
                color: darkRed,
                onPressed: () {
                  AppRouter.goToProviderDashboard(context, debugUserName: "Debug User");
                },
              ),
              const SizedBox(height: 50),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBypassButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }
}
