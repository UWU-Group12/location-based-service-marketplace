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
  String? _detectedAddress;
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
      final address = await _locationService.getAddressFromGeoPoint(location);

      if (!mounted) return;

      setState(() {
        _serviceLocation = location;
        _detectedAddress = address ?? "Unknown Area";
      });

      if (address != null) {
        locationController.text = address;
      }

      _showMessage('Current location detected.');
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

  Future<void> _openMapPicker() async {
    if (_isGettingLocation) return;
    setState(() => _isGettingLocation = true);

    try {
      final newPoint = await _locationService.pickLocationOnMap(
        context,
        initial: _serviceLocation,
      );

      if (!mounted) return;

      if (newPoint != null) {
        final address = await _locationService.getAddressFromGeoPoint(newPoint);
        if (!mounted) return;

        setState(() {
          _serviceLocation = newPoint;
          _detectedAddress = address ?? "Unknown Area";
        });

        if (address != null) {
          locationController.text = address;
        }

        _showMessage('Location selected from map.');
      }
    } catch (error) {
      debugPrint('Service map error: $error');
      if (!mounted) return;
      _showMessage('Unable to open map. Please try again.');
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
      _showMessage('Please select your location before submitting.');
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
    } on StateError catch (error) {
      if (!mounted) return;
      _showMessage(error.message.toString());
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                maxLines: 3,
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
              const SizedBox(height: 5),
              Align(
                alignment: Alignment.centerRight,
                child: _AiEnhanceButton(
                  onPressed: isEnhancing || _isSubmitting
                      ? null
                      : _enhanceDescription,
                  isLoading: isEnhancing,
                ),
              ),
              const SizedBox(height: 16),
              _SoftSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Service Location',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (_detectedAddress != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.providerCard,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: AppColors.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Selected Location',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _detectedAddress!,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                              size: 21,
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isGettingLocation || _isSubmitting
                                ? null
                                : _useCurrentLocation,
                            icon: _isGettingLocation
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.my_location, size: 18),
                            label: Text(
                              _isGettingLocation ? 'Detecting...' : 'Use GPS',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isGettingLocation || _isSubmitting
                                ? null
                                : _openMapPicker,
                            icon: const Icon(Icons.map_outlined, size: 18),
                            label: const Text('Pick on Map'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: locationController,
                      decoration: const InputDecoration(
                        labelText: 'Address Description',
                        hintText: 'Near Badulla Hospital, Badulla',
                        prefixIcon: Icon(Icons.location_city_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter an address description';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_month),
                title: Text(selectedDate ?? 'Select preferred date'),
                onTap: _isSubmitting
                    ? null
                    : () async {
                        FocusScope.of(context).unfocus();
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
                        FocusScope.of(context).unfocus();
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
              ElevatedButton(
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
            ],
          ),
        ),
      ),
    );
  }
}

class _AiEnhanceButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const _AiEnhanceButton({required this.onPressed, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? 0.55 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFE7DDFF),
                  Color(0xFFCDE7FF),
                  Color(0xFFC4F2E3),
                ],
                stops: [0, 0.5, 1],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.75)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF29233F),
                    ),
                  )
                else
                  const Icon(
                    Icons.auto_awesome,
                    size: 17,
                    color: Color(0xFF29233F),
                  ),
                const SizedBox(width: 8),
                Text(
                  isLoading ? 'Enhancing...' : 'Enhance Description',
                  style: const TextStyle(
                    color: Color(0xFF29233F),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SoftSectionCard extends StatelessWidget {
  final Widget child;

  const _SoftSectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.045)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(padding: const EdgeInsets.all(18), child: child),
      ),
    );
  }
}
