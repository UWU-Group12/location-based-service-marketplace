import 'package:flutter/material.dart';

import '../../core/app_router.dart';
import '../../models/provider_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';
import '../../services/profile_edit_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/profile_settings.dart';
import '../customer/personal_information_screen.dart';
import 'provider_professional_profile_screen.dart';
import 'provider_profile_status_controller.dart';
import 'provider_service_area_screen.dart';
import 'provider_status_section.dart';

class ProviderProfileScreen extends StatefulWidget {
  const ProviderProfileScreen({super.key});
  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  final _auth = AuthService();
  final _firestore = FirestoreService();
  late final ProviderProfileStatusController _status;
  UserModel? _user;
  ProviderModel? _profile;
  String? _photoUrl;
  String? _locationName;
  String _categoryNames = '';
  bool _loading = true;
  bool _failed = false;
  bool _editing = false;
  bool _loggingOut = false;

  @override
  void initState() {
    super.initState();
    final uid = _auth.currentUser?.uid;
    _status = ProviderProfileStatusController(
      uid == null ? null : _firestore.watchProviderProfile(uid),
    );
    _loadProfile();
  }

  @override
  void dispose() {
    _status.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = _profile == null;
      _failed = false;
    });
    try {
      final firebaseUser = _auth.currentUser;
      final user = await _auth.getUserProfileForCurrentUser();
      final profile = firebaseUser == null
          ? null
          : await _firestore.getProviderProfile(firebaseUser.uid);
      if (!mounted) return;
      _status.seed(profile);
      String? locationName;
      if (profile?.baseLocation != null) {
        try {
          locationName = await LocationService().getAddressFromGeoPoint(
            profile!.baseLocation!,
          );
        } catch (_) {
          // Reverse geocoding must not prevent editing other sections.
        }
        locationName ??=
            '${profile!.baseLocation!.latitude.toStringAsFixed(6)}, ${profile.baseLocation!.longitude.toStringAsFixed(6)}';
      }
      var categoryNames = profile?.categoryNames.join(', ') ?? '';
      if (profile != null && profile.categoryIds.isNotEmpty) {
        try {
          final categories = await _firestore.getActiveCategories();
          categoryNames = profile.categoryIds
              .map((id) {
                final matches = categories.where(
                  (category) => category.id == id,
                );
                return matches.isEmpty ? id : matches.first.name;
              })
              .join(', ');
        } catch (_) {
          // Keep the category names stored in the profile as a fallback.
        }
      }
      var photo =
          profile?.profileImagePath ??
          user?.photoPath ??
          firebaseUser?.photoURL;
      if (photo != null && photo.isNotEmpty) {
        try {
          photo = await StorageService().getDownloadUrl(photo);
        } catch (_) {
          photo = firebaseUser?.photoURL;
        }
      }
      if (!mounted) return;
      setState(() {
        _user = user;
        _profile = profile;
        _photoUrl = photo;
        _locationName = locationName;
        _categoryNames = categoryNames;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _failed = _profile == null;
        _loading = false;
      });
      if (_profile != null) {
        _message('Could not refresh your profile. Please try again.');
      }
    }
  }

  Future<void> _openEditor(Widget screen) async {
    if (_editing) return;
    _editing = true;
    try {
      final saved = await openProfilePage<bool>(context, screen);
      if (!mounted || saved != true) return;
      await _loadProfile();
      if (mounted) _message('Changes saved successfully.');
    } finally {
      _editing = false;
    }
  }

  String get _providerId {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Please sign in to edit your profile.');
    return uid;
  }

  void _editPersonalInformation() => _openEditor(
    PersonalInformationScreen(
      name: _profile?.displayName ?? _user?.displayName ?? '',
      phone: _user?.phoneNumber ?? '',
      email: _user?.email ?? _auth.currentUser?.email ?? '',
      photoUrl: _photoUrl,
      requirePhone: true,
      onSave: (update) => ProfileEditService().savePersonalInformation(
        UserRole.provider,
        update,
      ),
    ),
  );

  void _editServiceArea() => _openEditor(
    ProviderServiceAreaScreen(
      location: _profile?.baseLocation,
      locationName: _locationName,
      serviceRadiusKm: _profile?.serviceRadiusKm ?? 10,
      onSave: (point, radius) => _firestore.updateProviderServiceArea(
        providerId: _providerId,
        baseLocation: point,
        serviceRadiusKm: radius,
      ),
    ),
  );

  void _editProfessionalProfile() => _openEditor(
    ProviderProfessionalProfileScreen(
      bio: _profile?.bio ?? '',
      categoryNames: _categoryNames,
      onSave: (bio) => _firestore.updateProviderProfessionalInformation(
        providerId: _providerId,
        bio: bio,
      ),
    ),
  );

  Future<void> _logout() async {
    if (_loggingOut) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'Are you sure you want to log out of your account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    _loggingOut = true;
    try {
      await _auth.signOut();
      if (mounted) AppRouter.goToWelcomeAfterLogout(context);
    } catch (_) {
      if (mounted) _message('Could not log out. Please try again.');
    } finally {
      _loggingOut = false;
    }
  }

  void _message(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_failed) {
      return Scaffold(
        body: Center(
          child: TextButton.icon(
            onPressed: _loadProfile,
            icon: const Icon(Icons.refresh),
            label: const Text('Could not load your profile. Try again'),
          ),
        ),
      );
    }
    final canEdit = _profile != null;
    return ProfileSettingsView(
      name:
          _profile?.displayName ??
          _user?.displayName ??
          _auth.currentUser?.displayName ??
          '',
      email: _user?.email ?? _auth.currentUser?.email ?? '',
      role: 'Service Provider',
      serviceCategories: _categoryNames,
      photoUrl: _photoUrl,
      onLogout: _logout,
      accountRows: [
        ProfileSettingsRow(
          icon: Icons.person_outline,
          title: 'Personal information',
          onTap: canEdit ? _editPersonalInformation : null,
        ),
        ProfileSettingsRow(
          icon: Icons.location_on_outlined,
          title: 'Service area',
          value: _locationName == null
              ? 'Not provided'
              : '$_locationName · ${(_profile?.serviceRadiusKm ?? 10).toInt()} km',
          onTap: canEdit ? _editServiceArea : null,
        ),
        ProfileSettingsRow(
          icon: Icons.lock_outline,
          title: 'Account security',
          onTap: () => openProfilePage(context, const ProfileSecurityScreen()),
        ),
      ],
      professionalRows: [
        ProfileSettingsRow(
          icon: Icons.home_repair_service_outlined,
          title: 'Professional profile',
          value: _categoryNames.isEmpty
              ? 'Your bio and service details'
              : _categoryNames,
          onTap: canEdit ? _editProfessionalProfile : null,
        ),
        ProviderStatusSection(controller: _status),
      ],
    );
  }
}
