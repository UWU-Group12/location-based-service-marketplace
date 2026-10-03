import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_colors.dart';
import '../../core/app_router.dart';
import '../../models/service_category_model.dart';
import '../../models/provider_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';
import '../../services/storage_service.dart';

class ProviderProfileScreen extends StatefulWidget {
  final bool _editing;
  const ProviderProfileScreen({super.key}) : _editing = false;
  const ProviderProfileScreen._edit() : _editing = true;

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class ProviderEditProfileScreen extends StatelessWidget {
  const ProviderEditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) => const ProviderProfileScreen._edit();
}

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
  List<String> _categoryIds = const [];
  String? _loadError;
  bool _profileExists = false;

  double _serviceRadius = 10;

  double? _latitude;
  double? _longitude;

  Stream<ProviderModel?>? _profileStatusStream;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isGettingLocation = false;

  List<ServiceCategory> _categories = const [];

  @override
  void initState() {
    super.initState();
    _loadStatusStream();
    _loadProfile();
  }

  void _loadStatusStream() {
    final uid = _authService.currentUser?.uid;
    _profileStatusStream = uid == null
        ? null
        : _firestoreService.watchProviderProfile(uid);
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
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
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
      final categories = await _firestoreService.getActiveCategories();
      final imagePath = profile?.profileImagePath?.trim();
      String? photoUrl;
      if (imagePath != null && imagePath.isNotEmpty) {
        try {
          photoUrl = imagePath.startsWith('http')
              ? imagePath
              : await _storageService.getDownloadUrl(imagePath);
        } catch (_) {
          photoUrl = null;
        }
      }

      if (!mounted) return;

      _categories = categories;

      if (profile != null) {
        _profileExists = true;
        _nameController.text = profile.displayName;

        _phoneController.text = userProfile?.phoneNumber ?? '';

        _bioController.text = profile.bio ?? '';

        _locationNameController.text =
            locationName ??
            (location == null
                ? ''
                : '${location.latitude}, ${location.longitude}');

        _categoryIds = profile.categoryIds;

        _photoUrl = photoUrl;

        if (profile.serviceRadiusKm != null) {
          _serviceRadius = profile.serviceRadiusKm!;
        }

        if (location != null) {
          _latitude = location.latitude;
          _longitude = location.longitude;
        }
      } else {
        _profileExists = false;
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
        _loadError = 'Could not load your profile.';
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

    if (!mounted || source == null) return;

    final image = await _imagePicker.pickImage(
      source: source,
      imageQuality: 82,
      maxWidth: 1200,
    );

    if (!mounted || image == null) return;

    setState(() {
      _selectedImage = File(image.path);
    });
  }

  Future<void> _useCurrentLocation({bool fromMap = false}) async {
    FocusScope.of(context).unfocus();

    setState(() {
      _isGettingLocation = true;
    });

    try {
      final position = fromMap
          ? await _locationService.pickLocationOnMap(
              context,
              initial: _latitude == null || _longitude == null
                  ? null
                  : GeoPoint(_latitude!, _longitude!),
            )
          : await _locationService.getCurrentLocation();

      if (position == null) {
        if (mounted) setState(() => _isGettingLocation = false);
        return;
      }

      final locationName = await _locationService.getAddressFromGeoPoint(
        position,
      );

      if (!mounted) return;

      setState(() {
        _latitude = position.latitude;

        _longitude = position.longitude;

        _locationNameController.text =
            locationName ?? '${position.latitude}, ${position.longitude}';

        _isGettingLocation = false;
      });

      _showMessage('Location selected. Save your profile to apply it.');
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
    if (!widget._editing || _isSaving || _isGettingLocation || !_profileExists) {
      return;
    }
    FocusScope.of(context).unfocus();

    if (_nameController.text.trim().isEmpty) {
      _showMessage('Please enter your full name.');
      return;
    }

    if (_phoneController.text.trim().isEmpty) {
      _showMessage('Please enter your phone number.');
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
        baseLocation: GeoPoint(_latitude!, _longitude!),
        serviceRadiusKm: _serviceRadius,
        profileImagePath: photoStoragePath,
      );

      final uploadedPhotoUrl = photoStoragePath == null
          ? null
          : await _storageService.getDownloadUrl(photoStoragePath);

      await _authService.updateAuthProfile(
        displayName: _nameController.text,
        photoUrl: uploadedPhotoUrl,
      );

      if (!mounted) return;

      setState(() {
        _isSaving = false;
        _selectedImage = null;
        _photoUrl = uploadedPhotoUrl ?? _photoUrl;
      });

      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      Navigator.of(context).pop(true);
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

  Future<void> _editProfile() async {
    final saved = await AppRouter.goToProviderEditProfile(context);
    if (!mounted || saved != true) return;
    await _loadProfile();
    if (!mounted) return;
    _showMessage('Profile updated successfully.');
  }

  Widget _sectionHeader(String title) => Text(
    title,
    style: Theme.of(context).textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w800,
      color: AppColors.primary,
    ),
  );

  Widget _detailField(String label, String value, IconData icon) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                value.trim().isEmpty ? 'Not provided' : value,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ],
    ),
  );

  String get _categoryNames => _categoryIds
      .map((id) {
        final matches = _categories.where((category) => category.id == id);
        return matches.isEmpty ? id : matches.first.name;
      })
      .join(', ');

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    if (!widget._editing) return _detailField(label, controller.text, icon);
    return TextField(
      enabled: !_isSaving,
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
    } else if (_photoUrl != null) {
      image = NetworkImage(_photoUrl!);
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
            if (widget._editing)
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: _profileStatusStream == null
          ? const Text('Sign in to view your status.')
          : StreamBuilder<ProviderModel?>(
              key: ObjectKey(_profileStatusStream),
              stream: _profileStatusStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return TextButton.icon(
                    onPressed: () => setState(_loadStatusStream),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Unable to load status. Try again'),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                final profile = snapshot.data;
                if (profile == null) {
                  return const Text('Profile status unavailable.');
                }
                final isVerified = profile.verificationStatus == 'verified';
                final isAvailable = profile.availabilityStatus == 'available';
                final verificationLabel = switch (profile.verificationStatus) {
                  'verified' => 'Verified',
                  'rejected' => 'Rejected',
                  'not_submitted' => 'Not verified',
                  _ => 'Pending',
                };
                return Row(
                  children: [
                    Expanded(
                      child: _statusItem(
                        icon: Icons.verified_outlined,
                        value: verificationLabel,
                        color: isVerified
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 28,
                      color: Colors.grey.shade200,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statusItem(
                        icon: isAvailable
                            ? Icons.check_circle_outline
                            : Icons.cancel_outlined,
                        value: isAvailable ? 'Available' : 'Not available',
                        color: isAvailable
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _statusItem({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _locationCard() {
    final hasLocation = _latitude != null && _longitude != null;
    if (!widget._editing) {
      return _detailField(
        'Saved service location',
        hasLocation ? _locationNameController.text : 'Not provided',
        Icons.location_on_outlined,
      );
    }

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
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            readOnly: true,
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
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _isGettingLocation
                  ? null
                  : () => _useCurrentLocation(fromMap: true),
              icon: const Icon(Icons.map_outlined),
              label: const Text('Pick on map'),
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

  Future<void> _changeRadius() async {
    final radius = await showDialog<double>(
      context: context,
      builder: (context) => _RadiusDialog(initialRadius: _serviceRadius),
    );
    if (!mounted || radius == null) return;
    setState(() => _serviceRadius = radius);
  }

  Widget _radiusCard() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _detailField(
        'Service radius',
        '${_serviceRadius.toInt()} km',
        Icons.radar_outlined,
      ),
      if (widget._editing)
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _isSaving ? null : _changeRadius,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Change radius'),
          ),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        appBar: widget._editing
            ? AppBar(title: const Text('Edit Profile'))
            : null,
        body: Center(
          child: TextButton.icon(
            onPressed: _loadProfile,
            icon: const Icon(Icons.refresh),
            label: Text('$_loadError Try again'),
          ),
        ),
      );
    }
    return PopScope(
      canPop: !_isSaving,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          automaticallyImplyLeading: widget._editing,
          title: widget._editing ? const Text('Edit Profile') : null,
          actions: [
            if (!widget._editing && _profileExists)
              TextButton.icon(
                onPressed: _editProfile,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit Profile'),
              ),
          ],
        ),
        body: SafeArea(
          child: AbsorbPointer(
            absorbing: _isSaving,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              children: [
                _profileHeader(),

                const SizedBox(height: 28),

                _statusCard(),

                const SizedBox(height: 30),

                _sectionHeader('Personal information'),

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

                _sectionHeader('Professional details'),

                const SizedBox(height: 18),

                _detailField(
                  'Service category',
                  _categoryNames,
                  Icons.home_repair_service_outlined,
                ),

                const SizedBox(height: 18),

                _radiusCard(),

                const SizedBox(height: 30),

                _sectionHeader('Service area'),

                const SizedBox(height: 18),

                _locationCard(),

                const SizedBox(height: 30),

                if (widget._editing)
                  SizedBox(
                    height: 54,
                    child: FilledButton(
                      onPressed: _isSaving || _isGettingLocation
                          ? null
                          : _saveProfile,
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

                if (!widget._editing)
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
        ),
      ),
    );
  }
}

class _RadiusDialog extends StatefulWidget {
  final double initialRadius;
  const _RadiusDialog({required this.initialRadius});

  @override
  State<_RadiusDialog> createState() => _RadiusDialogState();
}

class _RadiusDialogState extends State<_RadiusDialog> {
  late double _selected;
  @override
  void initState() {
    super.initState();
    _selected = widget.initialRadius;
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Change service radius'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Current radius: ${widget.initialRadius.toInt()} km'),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [5.0, 10.0, 15.0, 20.0, 30.0]
              .map(
                (radius) => ChoiceChip(
                  label: Text('${radius.toInt()} km'),
                  selected: _selected == radius,
                  onSelected: (_) => setState(() => _selected = radius),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        const Text(
          'Confirm your radius, then save your profile to apply the change.',
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, _selected),
        child: const Text('Confirm radius'),
      ),
    ],
  );
}
