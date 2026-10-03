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

class CustomerEditProfileScreen extends StatefulWidget {
  const CustomerEditProfileScreen({super.key});

  @override
  State<CustomerEditProfileScreen> createState() =>
      _CustomerEditProfileScreenState();
}

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return const CustomerEditProfileScreen();
  }
}

class _CustomerEditProfileScreenState extends State<CustomerEditProfileScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  final LocationService _locationService = LocationService();

  final ImagePicker _imagePicker = ImagePicker();

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _phoneController = TextEditingController();

  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  String? _profileImageUrl;
  File? _selectedImage;

  double? _latitude;
  double? _longitude;
  String? _locationName;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isGettingLocation = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _authService.getUserProfileForCurrentUser();
      final savedPhoto = profile?.photoPath;
      final authPhoto = _authService.currentUser?.photoURL;
      String? resolvedPhotoUrl;

      final photoUrl = savedPhoto == null || savedPhoto.isEmpty
          ? authPhoto
          : savedPhoto;
      if (photoUrl != null && photoUrl.trim().isNotEmpty) {
        try {
          resolvedPhotoUrl = await _storageService.getDownloadUrl(photoUrl);
        } catch (error) {
          debugPrint('Could not load customer profile photo: $error');
          resolvedPhotoUrl = authPhoto;
        }
      }

      if (!mounted) return;

      setState(() {
        _nameController.text = profile?.displayName ?? '';

        _phoneController.text = profile?.phoneNumber ?? '';

        // TODO: customer location is not saved yet, so it loads empty.
        _emailController.text =
            profile?.email ?? _authService.currentUser?.email ?? '';

        _profileImageUrl = resolvedPhotoUrl;

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showMessage('Could not load your profile.', isError: true);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1000,
        maxHeight: 1000,
      );

      if (image == null) return;

      setState(() {
        _selectedImage = File(image.path);
      });
    } catch (e) {
      _showMessage('Could not select image.', isError: true);
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1000,
        maxHeight: 1000,
      );

      if (image == null) return;

      setState(() {
        _selectedImage = File(image.path);
      });
    } catch (e) {
      _showMessage('Could not open camera.', isError: true);
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Profile Picture',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage();
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: const Text('Take a Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _takePhoto();
                  },
                ),

                if (_selectedImage != null ||
                    (_profileImageUrl?.isNotEmpty ?? false))
                  ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: const Text('Remove Photo'),
                    onTap: () {
                      Navigator.pop(context);

                      setState(() {
                        _selectedImage = null;
                        _profileImageUrl = null;
                      });
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _useCurrentLocation({bool fromMap = false}) async {
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
        _locationName = locationName;

        _locationController.text =
            locationName ??
            '${position.latitude.toStringAsFixed(6)}, '
                '${position.longitude.toStringAsFixed(6)}';

        _isGettingLocation = false;
      });

      _showMessage(fromMap ? 'Location selected from map.' : 'Current location added.');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isGettingLocation = false;
      });

      _showMessage(e.toString().replaceFirst('Bad state: ', ''), isError: true);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) {
        throw StateError('User is not signed in.');
      }

      String? photoUrl = _profileImageUrl;
      String? photoPath;
      final clearPhoto = photoUrl == null && _selectedImage == null;

      // Upload new image if selected.
      if (_selectedImage != null) {
        photoPath = await _storageService.uploadProfileImage(
          file: _selectedImage!,
          userFolder: 'users/$userId',
        );
        photoUrl = await _storageService.getDownloadUrl(photoPath);
      }

      await _firestoreService.updateCustomerProfile(
        userId: userId,
        displayName: _nameController.text,
        phoneNumber: _phoneController.text,
        photoPath: photoPath,
        clearPhoto: clearPhoto,
      );

      await _authService.updateAuthProfile(
        displayName: _nameController.text,
        photoUrl: photoPath == null ? null : photoUrl,
        clearPhoto: clearPhoto,
      );

      if (!mounted) return;

      setState(() {
        _profileImageUrl = photoUrl;
        _selectedImage = null;
        _isSaving = false;
      });

      _showMessage('Profile updated successfully.');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      _showMessage(
        'Could not update profile. Please try again.',
        isError: true,
      );
    }
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          'Log out?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Are you sure you want to log out of your account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    try {
      await _authService.signOut();
      if (!mounted) return;

      AppRouter.goToLoginAfterLogout(context);
    } catch (error) {
      debugPrint('Customer logout failed: $error');
      if (!mounted) return;

      _showMessage('Could not log out. Please try again.', isError: true);
    }
  }

  void _showChangePasswordDialog() {
    final passwordController = TextEditingController();

    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        bool obscurePassword = true;
        bool obscureConfirm = true;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Change Password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'New password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmController,
                    obscureText: obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'Confirm password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureConfirm
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            obscureConfirm = !obscureConfirm;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final password = passwordController.text.trim();

                    final confirm = confirmController.text.trim();

                    if (password.length < 6) {
                      _showMessage(
                        'Password must contain at least 6 characters.',
                        isError: true,
                      );
                      return;
                    }

                    if (password != confirm) {
                      _showMessage('Passwords do not match.', isError: true);
                      return;
                    }

                    try {
                      await _authService.changePassword(password);

                      if (!mounted) return;

                      // ignore: use_build_context_synchronously
                      Navigator.pop(context);

                      // ignore: use_build_context_synchronously
                      _showMessage('Password changed successfully.');
                    } catch (e) {
                      if (!mounted) return;

                      // ignore: use_build_context_synchronously
                      _showMessage('Could not change password.', isError: true);
                    }
                  },
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  ImageProvider? _getProfileImage() {
    if (_selectedImage != null) {
      return FileImage(_selectedImage!);
    }

    if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      return NetworkImage(_profileImageUrl!);
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),

      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileHeader(),

              const SizedBox(height: 32),

              _buildSectionTitle('Personal Information'),

              const SizedBox(height: 12),

              _buildTextField(
                controller: _nameController,
                label: 'Full Name',
                hint: 'Enter your full name',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name';
                  }

                  if (value.trim().length < 2) {
                    return 'Name is too short';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              _buildTextField(
                controller: _emailController,
                label: 'Email Address',
                hint: 'Email',
                icon: Icons.email_outlined,
                enabled: false,
              ),

              const SizedBox(height: 16),

              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number',
                hint: 'Enter your phone number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 28),

              _buildSectionTitle('Service Location'),

              const SizedBox(height: 12),

              _buildLocationField(),

              const SizedBox(height: 28),

              _buildSectionTitle('Account Security'),

              const SizedBox(height: 12),

              _buildSecurityCard(),

              const SizedBox(height: 28),

              _buildLocationInfo(),
            ],
          ),
        ),
      ),

      bottomSheet: _buildSaveButton(),
    );
  }

  Widget _buildProfileHeader() {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    width: 4,
                  ),
                ),
                child: CircleAvatar(
                  radius: 54,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.10),
                  backgroundImage: _getProfileImage(),
                  child: _getProfileImage() == null
                      ? Icon(Icons.person, size: 55, color: AppColors.primary)
                      : null,
                ),
              ),

              Positioned(
                right: 0,
                bottom: 0,
                child: InkWell(
                  onTap: _showImageOptions,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            'Change profile picture',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildLocationField() {
    return Column(
      children: [
        TextFormField(
          controller: _locationController,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: 'Service Location',
            hintText: 'Enter your location or use GPS',
            prefixIcon: const Icon(Icons.location_on_outlined),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Colors.grey.withValues(alpha: 0.15),
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isGettingLocation ? null : _useCurrentLocation,
            icon: _isGettingLocation
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
            label: Text(
              _isGettingLocation
                  ? 'Getting location...'
                  : 'Use Current Location',
            ),
          ),
        ),

        const SizedBox(height: 8),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isGettingLocation
                ? null
                : () => _useCurrentLocation(fromMap: true),
            icon: const Icon(Icons.map_outlined),
            label: const Text('Pick on Map'),
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityCard() {
    return Card(
      elevation: 0,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.lock_outline, color: AppColors.primary),
        ),
        title: const Text(
          'Password',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: const Text('Update your account password'),
        trailing: const Icon(Icons.chevron_right),
        onTap: _showChangePasswordDialog,
      ),
    );
  }

  Widget _buildLocationInfo() {
    if (_latitude == null || _longitude == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppColors.primary.withValues(alpha: 0.07),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.gps_fixed, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'GPS Location Saved',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  _locationName ??
                      'Lat: ${_latitude!.toStringAsFixed(6)}\n'
                          'Lng: ${_longitude!.toStringAsFixed(6)}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              blurRadius: 12,
              offset: const Offset(0, -3),
              color: Colors.black.withValues(alpha: 0.06),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _isSaving ? null : _saveProfile,
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
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
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _isSaving ? null : _logout,
                icon: const Icon(Icons.logout_outlined),
                label: const Text('Log Out'),
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
