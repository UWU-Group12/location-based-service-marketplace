import 'package:flutter/material.dart';
import '../../widgets/ai_problem_card.dart';

class CustomerHomeScreen extends StatelessWidget {
  final String userName;
  final String initials;
  const CustomerHomeScreen({super.key, required this.userName, required this.initials});

  @override
  Widget build(BuildContext context) {
    final darkRed = const Color(0xFF8B0000);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good morning,',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                      Text(
                        '$userName 👋',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                            )
                          ],
                        ),
                        child: Stack(
                          children: [
                            const Icon(Icons.notifications_none_outlined, size: 28, color: Colors.black),
                            Positioned(
                              right: 2,
                              top: 2,
                              child: Container(
                                height: 8,
                                width: 8,
                                decoration: BoxDecoration(
                                  color: darkRed,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1.5),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(width: 15),
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFFD2B48C), // Light brown
                        child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 25),
              // Search Bar
              TextField(
                    decoration: InputDecoration(
                      hintText: 'What service do you need?',
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.black.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
              const SizedBox(height: 25),
              // AI Banner
              const AiProblemCard(),
              const SizedBox(height: 30),
              // Popular Services
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Popular services',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text('View all', style: TextStyle(color: darkRed, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildServiceItem(Icons.build_outlined, 'Plumbing', const Color(0xFFFDECEC), const Color(0xFFB71C1C)),
                  _buildServiceItem(Icons.bolt_outlined, 'Electrical', const Color(0xFFE3F2FD), const Color(0xFF0D47A1)),
                  _buildServiceItem(Icons.gavel_outlined, 'Carpentry', const Color(0xFFFFF3E0), const Color(0xFFE65100)),
                  _buildServiceItem(Icons.format_paint_outlined, 'Painting', const Color(0xFFE8F5E9), const Color(0xFF1B5E20)),
                ],
              ),
              const SizedBox(height: 30),
              // Nearby Professionals
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nearby professionals',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Around Badulla',
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text('See all', style: TextStyle(color: darkRed, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              // Professional Card
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      height: 65,
                      width: 65,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCFD8DC).withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'KS',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF455A64),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Kasun Silva',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      height: 6,
                                      width: 6,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF2E7D32),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    const Text(
                                      'Available Today',
                                      style: TextStyle(
                                        color: Color(0xFF2E7D32),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Text(
                            'Plumbing specialist',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Color(0xFFFFA000), size: 18),
                              const SizedBox(width: 4),
                              const Text(
                                '4.8',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Text(
                                ' (86)',
                                style: TextStyle(color: Colors.grey[500], fontSize: 14),
                              ),
                              const SizedBox(width: 15),
                              Icon(Icons.location_on_outlined, color: Colors.grey[400], size: 18),
                              const SizedBox(width: 4),
                              Text(
                                '1.8 km',
                                style: TextStyle(color: Colors.grey[500], fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black.withValues(alpha: 0.15)),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceItem(IconData icon, String label, Color boxColor, Color iconColor) {
    return Column(
      children: [
        Container(
          height: 65,
          width: 65,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Icon(icon, color: iconColor.withValues(alpha: 0.7), size: 28),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.black.withValues(alpha: 0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
