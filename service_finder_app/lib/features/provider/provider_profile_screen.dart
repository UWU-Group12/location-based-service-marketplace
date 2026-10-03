import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
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

  Future<void> _testLocation() async {
    setState(() {
      _locationStatus = "Fetching GPS coordinates... ⏳";
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
        _locationStatus =
        "📍 Lat: ${point.latitude.toStringAsFixed(4)}, Lng: ${point.longitude.toStringAsFixed(4)}\n🏙️ City: $address\n✅ Saved to Firestore!";
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationStatus = "❌ Error: $e";
      });
    }
  }

  Future<void> _openMapPicker() async {
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
        _locationStatus = "❌ Error: $e";
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Profile Service Provider")),
      body: StreamBuilder(
        stream: _authService.user,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data;

          if (user == null) {
            return const Center(
              child: Text('No user is currently signed in.'),
            );
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user.email ?? 'No email',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _showLocationOptions = !_showLocationOptions;
                      });
                    },
                    icon: const Icon(Icons.edit_location_alt),
                    label: Text(_showLocationOptions
                        ? 'Hide Location Options'
                        : 'Change Location 📍'),
                  ),
                  if (_showLocationOptions) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _testLocation,
                      icon: const Icon(Icons.my_location),
                      label: const Text("Test Live GPS Location"),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _openMapPicker,
                      icon: const Icon(Icons.map),
                      label: const Text("Select Location on Map 🗺️"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    if (_locationStatus.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        _locationStatus,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _isLoggingOut ? null : _logout,
                    icon: _isLoggingOut
                        ? const SizedBox(
                      width: 26,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Icon(Icons.logout),
                    label:
                    Text(_isLoggingOut ? 'Logging out...' : 'Logout'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _logout() async {
    setState(() {
      _isLoggingOut = true;
    });

    try {
      await _authService.signOut();

      if (!mounted) return;

      AppRouter.goToLoginAfterLogout(context);
    } catch (error) {
      debugPrint('Logout error: $error');

      if (!mounted) return;

      setState(() {
        _isLoggingOut = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to log out. Please try again.'),
        ),
      );
    }
  }
}