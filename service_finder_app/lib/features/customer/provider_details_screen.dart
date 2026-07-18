import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../models/service_provider_model.dart';

class ProviderDetailsScreen extends StatelessWidget {
  final ServiceProviderModel provider;

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            CircleAvatar(
              radius: 45,
              backgroundColor: Colors.grey.shade300,
              child: Text(
                provider.name.substring(0, 1),
                style: const TextStyle(
                  fontSize: 30,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 16),

            Text(
              provider.name,
              style: textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 6),

            Text(
              provider.service,
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
                  provider.rating.toString(),
                  'Rating',
                ),

                _infoCard(
                  Icons.work_outline,
                  '${provider.experience} yrs',
                  'Experience',
                ),

                _infoCard(
                  Icons.location_on_outlined,
                  provider.location,
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

            _serviceChip(provider.service),
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
                provider.isVerified
                    ? Icons.verified
                    : Icons.error_outline,
                color: provider.isVerified
                    ? Colors.green
                    : Colors.orange,
              ),
              title: Text(
                provider.isVerified
                    ? 'Verified Provider'
                    : 'Verification Pending',
              ),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Request Service screen coming soon.',
                      ),
                    ),
                  );

                },
                child: const Text('Request Service'),
              ),
            ),

          ],
        ),
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