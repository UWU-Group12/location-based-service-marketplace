import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../models/provider_model.dart';
import 'create_request_screen.dart';

class ProviderDetailsScreen extends StatelessWidget {
  final ProviderModel provider;

  const ProviderDetailsScreen({
    super.key,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text('Provider Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      body: Stack(
        children: [

          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [

                CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.grey.shade300,
                  child: Text(
                    provider.displayName.substring(0, 1),
                    style: const TextStyle(
                      fontSize: 30,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  provider.displayName,
                  style: textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 6),

                Text(
                  provider.categoryIds[0],
                  style: textTheme.bodyLarge?.copyWith(
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [

                    _infoCard(
                      Icons.star,
                      provider.ratingAverage.toString(),
                      'Rating',
                    ),

                    _infoCard(
                      Icons.work_outline,
                      '${provider.completedJobCount} jobs',
                      'Experience',
                    ),

                    _infoCard(
                      Icons.location_on_outlined,
                      provider.locationId ?? 'N/A',
                      'Location',
                    ),

                  ],
                ),

                const SizedBox(height: 30),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'About',
                    style: textTheme.titleLarge,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'This is a professional service provider with experience in residential and commercial work. More provider information will be loaded from Firebase in the future.',
                ),

                const SizedBox(height: 30),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Services Offered',
                    style: textTheme.titleLarge,
                  ),
                ),

                const SizedBox(height: 10),

                _serviceChip(provider.categoryIds[0]),
                _serviceChip('Repairs'),
                _serviceChip('Installation'),

                const SizedBox(height: 30),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Verification',
                    style: textTheme.titleLarge,
                  ),
                ),

                const SizedBox(height: 10),

                ListTile(
                  leading: Icon(
                    provider.verificationStatus == 'verified'
                        ? Icons.verified
                        : Icons.error_outline,
                    color: provider.verificationStatus == 'verified'
                        ? Colors.green
                        : Colors.orange,
                  ),
                  title: Text(
                    provider.verificationStatus == 'verified'
                        ? 'Verified Provider'
                        : 'Verification Pending',
                  ),
                ),

                // Space for floating button
                const SizedBox(height: 100),

              ],
            ),
          ),


          // Floating button only
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () {

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateRequestScreen(
                        provider: provider,
                      ),
                    ),
                  );

                },
              child: const Text(
                'Request Service',
              ),
            ),
          ),

        ],
      ),
    );
  }


  Widget _infoCard(
    IconData icon,
    String value,
    String label,
  ) {
    return Column(
      children: [
        Icon(icon),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label),
      ],
    );
  }


  Widget _serviceChip(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Chip(
          label: Text(title),
        ),
      ),
    );
  }
}