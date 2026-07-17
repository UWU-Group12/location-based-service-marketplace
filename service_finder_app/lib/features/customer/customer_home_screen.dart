import 'package:flutter/material.dart';
import 'package:service_finder_app/core/app_router.dart';
import '../../widgets/ai_problem_card.dart';
import '../../core/app_colors.dart';

class CustomerHomeScreen extends StatelessWidget {
  final String userName;
  final String initials;
  const CustomerHomeScreen({super.key, required this.userName, required this.initials});

  @override
  Widget build(BuildContext context) {
    final darkRed = AppColors.primary.withValues(alpha: 0.8);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
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
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '$userName ',
                        style: textTheme.headlineMedium?.copyWith(
                          fontSize: 28,
                          color: AppColors.primary,
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
                        child: Text(
                          initials,
                          style: textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                          ),
                        ),
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
                  Text(
                    'Popular services',
                    style: textTheme.titleLarge?.copyWith(
                      fontSize: 18,
                    ),
                  ),
                  TextButton(
                    onPressed: () { AppRouter.goToServiceCategoryScreen(context);},
                    child: Text(
                      'View all',
                      style: textTheme.labelLarge?.copyWith(
                        color: darkRed,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildServiceItem(context, Icons.build_outlined, 'Plumbing', const Color(0xFFFDECEC), const Color(0xFFB71C1C)),
                  _buildServiceItem(context, Icons.bolt_outlined, 'Electrical', const Color(0xFFE3F2FD), const Color(0xFF0D47A1)),
                  _buildServiceItem(context, Icons.gavel_outlined, 'Carpentry', const Color(0xFFFFF3E0), const Color(0xFFE65100)),
                  _buildServiceItem(context, Icons.format_paint_outlined, 'Painting', const Color(0xFFE8F5E9), const Color(0xFF1B5E20)),
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
                      Text(
                        'Nearby professionals',
                        style: textTheme.titleLarge?.copyWith(
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'Around Badulla',
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'See all',
                      style: textTheme.labelLarge?.copyWith(
                        color: darkRed,
                      ),
                    ),
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
                      child: Text(
                        'KS',
                        style: textTheme.titleMedium?.copyWith(
                          fontSize: 20,
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
                              Text(
                                'Kasun Silva',
                                style: textTheme.titleMedium?.copyWith(
                                  fontSize: 17,
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
                                    Text(
                                      'Available Today',
                                      style: textTheme.labelSmall?.copyWith(
                                        color: Color(0xFF2E7D32),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Plumbing specialist',
                            style: textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Color(0xFFFFA000), size: 18),
                              const SizedBox(width: 4),
                              Text(
                                '4.8',
                                style: textTheme.labelLarge?.copyWith(
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                ' (86)',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Icon(Icons.location_on_outlined, color: Colors.grey[400], size: 18),
                              const SizedBox(width: 4),
                              Text(
                                '1.8 km',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
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

  Widget _buildServiceItem(BuildContext context, IconData icon, String label, Color boxColor, Color iconColor) {
    final textTheme = Theme.of(context).textTheme;

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
          style: textTheme.bodySmall?.copyWith(
            fontSize: 13,
            color: Colors.black.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
