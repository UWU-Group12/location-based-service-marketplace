import 'package:flutter/material.dart';
import 'register_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final darkRed = const Color(0xFF8B0000);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              'Select\nuser type',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                color: darkRed,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: _buildRoleCard(
                context: context,
                role: 'Service Provider',
                description: 'Offer your professional services',
                imageUrl: 'assets/images/provider.png',
                backgroundColor: const Color(0xC3FFF5F5), // Light Red
              ),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: _buildRoleCard(
                context: context,
                role: 'Client',
                description: 'Find the best services near you',
                imageUrl: 'assets/images/client.png',
                backgroundColor: const Color(0xC3FFF5F5), // Light Pink
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required String role,
    required String description,
    required String imageUrl,
    required Color backgroundColor,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RegisterScreen(role: role),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            // Cartoonish Image
            Expanded(
              flex: 4,
              child: Image.asset(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 80, color: Colors.black26),
              ),
            ),
            const SizedBox(width: 15),
            // Text Content
            Expanded(
              flex: 5,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black.withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.black26),
          ],
        ),
      ),
    );
  }
}
