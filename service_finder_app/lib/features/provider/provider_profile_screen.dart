import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_colors.dart';
import '../../core/app_router.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';
import '../../services/storage_service.dart';

class ProviderProfileScreen extends StatefulWidget {
  const ProviderProfileScreen({super.key});

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

typedef ProviderEditProfileScreen = ProviderProfileScreen;

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  final LocationService _locationService = LocationService();

  final ImagePicker _imagePicker = ImagePicker();

  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _phoneController = TextEditingController();

  final TextEditingController _bioController = TextEditingController();

  final TextEditingController _locationNameController = TextEditingController();

  File? _selectedImage;

  String? _photoUrl;
  String? _categoryId;

  double _serviceRadius = 10;

  double? _latitude;
  double? _longitude;

  String _verificationStatus = 'pending';
  String _availabilityStatus = 'available';

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isGettingLocation = false;

  final List<Map<String, String>> _categories = const [
    {'id': 'plumbing', 'name': 'Plumbing'},
    {'id': 'electrical', 'name': 'Electrical'},
    {'id': 'cleaning', 'name': 'Cleaning'},
    {'id': 'carpentry', 'name': 'Carpentry'},
    {'id': 'painting', 'name': 'Painting'},
    {'id': 'ac_repair', 'name': 'AC Repair'},
    {'id': 'appliance_repair', 'name': 'Appliance Repair'},
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _locationNameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final user = _authService.currentUser;
      final userProfile = await _authService.getUserProfileForCurrentUser();
      final profile = user == null
          ? null
          : await _firestoreService.getProviderProfile(user.uid);
      final location = profile?.baseLocation;
      final locationName = location == null
          ? null
          : await _locationService.getAddressFromGeoPoint(location);

      if (!mounted) return;

      if (profile != null) {
        _nameController.text = profile.displayName;

        _phoneController.text = userProfile?.phoneNumber ?? '';

        _bioController.text = profile.bio ?? '';

        _locationNameController.text = locationName ?? '';

        _categoryId = profile.categoryIds.isEmpty
            ? null
            : profile.categoryIds.first;

        _photoUrl = profile.profileImagePath;

        _verificationStatus = profile.verificationStatus;

        _availabilityStatus = profile.availabilityStatus;

        if (profile.serviceRadiusKm != null) {
          _serviceRadius = profile.serviceRadiusKm!;
        }

        if (location != null) {
          _latitude = location.latitude;
          _longitude = location.longitude;
        }
      } else {
        _nameController.text = user?.displayName ?? '';

        _phoneController.text = user?.phoneNumber ?? '';

        _photoUrl = user?.photoURL;
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showMessage('Could not load your profile.');
    }
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Change profile photo',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 18),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.photo_library_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  title: const Text('Choose from gallery'),
                  onTap: () {
                    Navigator.pop(context, ImageSource.gallery);
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Edit Profile'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    AppRouter.goToProviderEditProfile(context);
                  },
                ),
                const SizedBox(height: 6),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.camera_alt_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  title: const Text('Take a photo'),
                  onTap: () {
                    Navigator.pop(context, ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null) return;

    final image = await _imagePicker.pickImage(
      source: source,
      imageQuality: 82,
      maxWidth: 1200,
    );

    if (image == null) return;

    setState(() {
      _selectedImage = File(image.path);
    });
  }

  Future<void> _useCurrentLocation() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _isGettingLocation = true;
    });

    try {
      final position = await _locationService.getCurrentLocation();

      final locationName = await _locationService.getAddressFromGeoPoint(
        position,
      );
      if (locationName == null) {
        throw StateError('Location name could not be found.');
      }

      if (!mounted) return;

      setState(() {
        _latitude = position.latitude;

        _longitude = position.longitude;

        _locationNameController.text = locationName;

        _isGettingLocation = false;
      });

      _showMessage('Service location updated.');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isGettingLocation = false;
      });

      _showMessage(
        e is StateError ? e.message : 'Could not get your current location.',
      );
    }
  }

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();

    if (_nameController.text.trim().isEmpty) {
      _showMessage('Please enter your full name.');
      return;
    }

    if (_phoneController.text.trim().isEmpty) {
      _showMessage('Please enter your phone number.');
      return;
    }

    if (_categoryId == null) {
      _showMessage('Please select your main service.');
      return;
    }

    if (_locationNameController.text.trim().isEmpty) {
      _showMessage('Please enter your service location.');
      return;
    }

    if (_latitude == null || _longitude == null) {
      _showMessage(
        'Please select your service location using the location button.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final providerId = _authService.currentUser?.uid;
      if (providerId == null) {
        throw StateError('No signed-in provider found.');
      }

      String? photoStoragePath;

      if (_selectedImage != null) {
        photoStoragePath = await _storageService.uploadProfileImage(
          file: _selectedImage!,
          userFolder: 'providers/$providerId',
        );
      }

      await _firestoreService.updateProviderProfile(
        providerId: providerId,
        displayName: _nameController.text,
        phoneNumber: _phoneController.text,
        bio: _bioController.text,
        categoryId: _categoryId!,
        baseLocation: GeoPoint(_latitude!, _longitude!),
        serviceRadiusKm: _serviceRadius,
        profileImagePath: photoStoragePath,
      );

      await _authService.updateAuthProfile(
        displayName: _nameController.text,
        photoUrl: photoStoragePath == null
            ? null
            : await _storageService.getDownloadUrl(photoStoragePath),
      );

      if (!mounted) return;

      setState(() {
        _isSaving = false;
        _selectedImage = null;
        _photoUrl = photoStoragePath ?? _photoUrl;
      });

      _showMessage('Profile updated successfully.');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      _showMessage('Could not update your profile.');
    }
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Log out?',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: const Text(
            'Are you sure you want to log out of your account?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Log out'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) {
      return;
    }

    try {
      await _authService.signOut();

      if (!mounted) return;

      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;

      _showMessage('Could not log out. Please try again.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  Widget _sectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
      ),
    );
  }

  Widget _profileHeader() {
    ImageProvider? image;

    if (_selectedImage != null) {
      image = FileImage(_selectedImage!);
    }

    final name = _nameController.text.trim();

    final initials = name.isEmpty
        ? 'P'
        : name
              .split(' ')
              .where((word) => word.isNotEmpty)
              .take(2)
              .map((word) => word[0].toUpperCase())
              .join();

    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 118,
              height: 118,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.18),
                  width: 3,
                ),
              ),
              child: CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                backgroundImage: image,
                child: image == null
                    ? Text(
                        initials,
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
            ),
            Positioned(
              right: 1,
              bottom: 1,
              child: Material(
                color: AppColors.primary,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _pickImage,
                  child: const Padding(
                    padding: EdgeInsets.all(11),
                    child: Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          name.isEmpty ? 'Your profile' : name,
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 5),
        Text('Service Provider', style: TextStyle(color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _statusCard() {
    final isVerified = _verificationStatus == 'verified';

    final isAvailable = _availabilityStatus == 'available';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: _statusItem(
              icon: Icons.verified_outlined,
              title: 'Verification',
              value: isVerified ? 'Verified' : 'Pending',
              active: isVerified,
            ),
          ),
          Container(width: 1, height: 48, color: Colors.grey.shade200),
          Expanded(
            child: _statusItem(
              icon: Icons.circle_outlined,
              title: 'Availability',
              value: isAvailable ? 'Available' : 'Unavailable',
              active: isAvailable,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusItem({
    required IconData icon,
    required String title,
    required String value,
    required bool active,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: active ? AppColors.primary : Colors.grey),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ],
    );
  }

  Widget _locationCard() {
    final hasLocation = _latitude != null && _longitude != null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.location_on_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Service location',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Customers can find you based on this area.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _locationNameController,
            decoration: const InputDecoration(
              labelText: 'Location name',
              hintText: 'Example: Colombo 05',
              prefixIcon: Icon(Icons.place_outlined),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _isGettingLocation ? null : _useCurrentLocation,
              icon: _isGettingLocation
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location_outlined),
              label: Text(
                _isGettingLocation
                    ? 'Getting location...'
                    : 'Use current location',
              ),
            ),
          ),
          if (hasLocation) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Location selected',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _radiusCard() {
    const values = [5.0, 10.0, 15.0, 20.0, 30.0];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.radar_outlined, color: AppColors.primary),
              const SizedBox(width: 10),
              const Text(
                'Service radius',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Text(
                '${_serviceRadius.toInt()} km',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: values.map((value) {
              final selected = _serviceRadius == value;

              return ChoiceChip(
                label: Text('${value.toInt()} km'),
                selected: selected,
                onSelected: (_) {
                  setState(() {
                    _serviceRadius = value;
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            _profileHeader(),

            const SizedBox(height: 28),

            _statusCard(),

            const SizedBox(height: 30),

            _sectionHeader(
              'Personal information',
              'Update the information customers see on your profile.',
            ),

            const SizedBox(height: 18),

            _textField(
              controller: _nameController,
              label: 'Full name',
              hint: 'Enter your full name',
              icon: Icons.person_outline,
            ),

            const SizedBox(height: 14),

            _textField(
              controller: _phoneController,
              label: 'Phone number',
              hint: 'Enter your phone number',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),

            const SizedBox(height: 14),

            _textField(
              controller: _bioController,
              label: 'Professional bio',
              hint: 'Tell customers about your experience',
              icon: Icons.description_outlined,
              maxLines: 4,
            ),

            const SizedBox(height: 30),

            _sectionHeader(
              'Professional details',
              'Tell customers what service you provide.',
            ),

            const SizedBox(height: 18),

            DropdownButtonFormField<String>(
              initialValue: _categoryId,
              decoration: const InputDecoration(
                labelText: 'Main service',
                prefixIcon: Icon(Icons.home_repair_service_outlined),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem<String>(
                  value: category['id'],
                  child: Text(category['name']!),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _categoryId = value;
                });
              },
            ),

            const SizedBox(height: 18),

            _radiusCard(),

            const SizedBox(height: 30),

            _sectionHeader(
              'Service area',
              'Set where you normally provide your services.',
            ),

            const SizedBox(height: 18),

            _locationCard(),

            const SizedBox(height: 30),

            SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: _isSaving ? null : _saveProfile,
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 18),

            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _isSaving ? null : _logout,
                icon: const Icon(Icons.logout_outlined),
                label: const Text(
                  'Log Out',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade200),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
