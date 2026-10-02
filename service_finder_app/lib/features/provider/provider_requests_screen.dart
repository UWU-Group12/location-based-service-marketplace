import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../models/service_request_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/request_card.dart';

class ProviderRequestsScreen extends StatefulWidget {
  const ProviderRequestsScreen({super.key});

  @override
  State<ProviderRequestsScreen> createState() => _ProviderRequestsScreenState();
}

class _ProviderRequestsScreenState extends State<ProviderRequestsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  Stream<List<ServiceRequestModel>>? _requestsStream;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  void _loadRequests() {
    final providerId = FirebaseAuth.instance.currentUser?.uid;
    _requestsStream = providerId == null
        ? null
        : _firestoreService.watchProviderRequests(providerId);
  }

  void _retry() {
    setState(_loadRequests);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Requests',
                style: textTheme.headlineMedium?.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 6),
            
              const SizedBox(height: 24),
              Expanded(
                child: _requestsStream == null
                    ? _statusView(
                        icon: Icons.person_outline,
                        title: 'Sign in to view requests',
                        message:
                            'You must be signed in as a provider to view your requests.',
                        retry: true,
                      )
                    : StreamBuilder<List<ServiceRequestModel>>(
                        key: ObjectKey(_requestsStream),
                        stream: _requestsStream,
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return _statusView(
                              icon: Icons.error_outline,
                              title: 'Unable to load requests',
                              message:
                                  'Please check your connection and try again.',
                              retry: true,
                            );
                          }
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          final requests = snapshot.data!;
                          if (requests.isEmpty) {
                            return _statusView(
                              icon: Icons.assignment_outlined,
                              title: 'No requests yet',
                              message:
                                  '',
                            );
                          }
                          return ListView.builder(
                            itemCount: requests.length,
                            itemBuilder: (context, index) => RequestCard(
                              key: ValueKey(requests[index].requestId),
                              request: requests[index],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusView({
    required IconData icon,
    required String title,
    required String message,
    bool retry = false,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 70, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              title,
              style: textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (retry) ...[
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: _retry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
