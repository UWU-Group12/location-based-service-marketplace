import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_router.dart';
import '../../models/provider_model.dart';
import '../../models/service_request_model.dart';
import '../../services/ai_service.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';

class CreateRequestScreen extends StatefulWidget {
  final ProviderModel provider;

  const CreateRequestScreen({super.key, required this.provider});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final AIService _aiService = AIService();
  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();
  final _formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final locationController = TextEditingController();

  bool isEnhancing = false;
  bool _isGettingLocation = false;
  bool _isSubmitting = false;
  GeoPoint? _serviceLocation;
  String? selectedDate;
  String? selectedTime;

  Future<void> _enhanceDescription() async {
    if (descriptionController.text.trim().isEmpty) {
      _showMessage('Please enter a description first.');
      return;
    }

    setState(() => isEnhancing = true);

    final improvedDescription = await _aiService.improveDescription(
      descriptionController.text.trim(),
    );

    if (!mounted) return;

    setState(() => isEnhancing = false);

    if (improvedDescription != null && improvedDescription.isNotEmpty) {
      descriptionController.text = improvedDescription;
    } else {
      _showMessage('Unable to enhance description. Try again.');
    }
  }

  Future<void> _useCurrentLocation() async {
    if (_isGettingLocation) return;

    setState(() => _isGettingLocation = true);

    try {
      final location = await _locationService.getCurrentLocation();
      if (!mounted) return;

      setState(() => _serviceLocation = location);
      _showMessage('Current location selected.');
    } on StateError catch (error) {
      if (!mounted) return;
      _showMessage(error.message.toString());
    } catch (error) {
      debugPrint('Service request location error: $error');
      if (!mounted) return;
      _showMessage('Unable to get your location. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isGettingLocation = false);
      }
    }
  }

  Future<void> _submitRequest() async {
    if (_isSubmitting || _isGettingLocation) return;

    if (!_formKey.currentState!.validate()) return;

    final serviceLocation = _serviceLocation;
    if (serviceLocation == null) {
      _showMessage('Please use your current location before submitting.');
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showMessage('Please sign in before creating a service request.');
      return;
    }

    if (widget.provider.categoryIds.isEmpty) {
      _showMessage('This provider does not have a service category.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final now = DateTime.now();
      final request = ServiceRequestModel(
        requestId: '',
        customerId: currentUser.uid,
        providerId: widget.provider.providerId,
        categoryId: widget.provider.categoryIds.first,
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        imagePaths: const [],
        servicePoint: serviceLocation,
        addressText: locationController.text.trim(),
        requestStatus: 'submitted',
        quotationStatus: 'pending',
        createdAt: now,
        updatedAt: now,
      );

      await _firestoreService.createServiceRequest(request);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request created successfully.')),
      );
      AppRouter.goToCustomerDashboard(context);
    } catch (error) {
      debugPrint('Service request creation error: $error');
      if (!mounted) return;

      _showMessage('Unable to create your request. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final categoryName = widget.provider.categoryIds.isEmpty
        ? 'Service provider'
        : widget.provider.categoryIds.first;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Create Request')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.provider.displayName, style: textTheme.titleLarge),
              Text(
                categoryName,
                style: textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 25),
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Service Title',
                  hintText: 'Example: Fix water leakage',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a service title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Problem Description',
                  hintText: 'Explain your issue',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a problem description';
                  }
                  return null;
                },
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: isEnhancing || _isSubmitting
                      ? null
                      : _enhanceDescription,
                  icon: isEnhancing
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(
                    isEnhancing ? 'Enhancing...' : 'Enhance Description',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Service Location',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isGettingLocation || _isSubmitting
                    ? null
                    : _useCurrentLocation,
                icon: _isGettingLocation
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
                label: Text(
                  _isGettingLocation
                      ? 'Getting Location...'
                      : 'Use Current Location',
                ),
              ),
              if (_serviceLocation != null) ...[
                const SizedBox(height: 8),
                const Text(
                  'Current location selected',
                  style: TextStyle(color: Colors.green),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Address Description',
                  hintText: 'Near Badulla Hospital, Badulla',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter an address description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_month),
                title: Text(selectedDate ?? 'Select preferred date'),
                onTap: _isSubmitting
                    ? null
                    : () async {
                        final date = await showDatePicker(
                          context: context,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2030),
                          initialDate: DateTime.now(),
                        );

                        if (date != null && mounted) {
                          setState(() {
                            selectedDate =
                                '${date.day}/${date.month}/${date.year}';
                          });
                        }
                      },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time),
                title: Text(selectedTime ?? 'Select preferred time'),
                onTap: _isSubmitting
                    ? null
                    : () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );

                        if (time != null && mounted) {
                          setState(() => selectedTime = time.format(context));
                        }
                      },
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting || _isGettingLocation
                      ? null
                      : _submitRequest,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Submit Request'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
