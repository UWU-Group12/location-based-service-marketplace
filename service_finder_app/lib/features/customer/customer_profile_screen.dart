import 'package:flutter/material.dart';

import '../../core/app_router.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/profile_edit_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/profile_settings.dart';
import 'personal_information_screen.dart';
import 'saved_location_screen.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  final _auth = AuthService();
  UserModel? _profile;
  String? _photoUrl;
  bool _loading = true;
  bool _loggingOut = false;
  bool _editing = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = _profile == null;
      _failed = false;
    });
    try {
      final profile = await _auth.getUserProfileForCurrentUser();
      var photo = profile?.photoPath ?? _auth.currentUser?.photoURL;
      if (photo != null && photo.isNotEmpty) {
        try {
          photo = await StorageService().getDownloadUrl(photo);
        } catch (_) {
          photo = _auth.currentUser?.photoURL;
        }
      }
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _photoUrl = photo;
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

  void _editPersonalInformation() => _openEditor(
    PersonalInformationScreen(
      name: _profile?.displayName ?? _auth.currentUser?.displayName ?? '',
      phone: _profile?.phoneNumber ?? '',
      email: _profile?.email ?? _auth.currentUser?.email ?? '',
      photoUrl: _photoUrl,
      onSave: (update) => ProfileEditService().savePersonalInformation(
        UserRole.customer,
        update,
      ),
    ),
  );

  void _editLocation() => _openEditor(
    SavedLocationScreen(
      location: _profile?.savedLocation,
      locationName: _profile?.locationName,
      onSave: (point, name) async {
        final uid = _auth.currentUser?.uid;
        if (uid == null) {
          throw StateError('Please sign in to edit your location.');
        }
        await FirestoreService().updateCustomerLocation(
          userId: uid,
          savedLocation: point,
          locationName: name,
        );
      },
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
    final canEdit = _auth.currentUser != null;
    return ProfileSettingsView(
      name: _profile?.displayName ?? _auth.currentUser?.displayName ?? '',
      email: _profile?.email ?? _auth.currentUser?.email ?? '',
      role: 'Customer',
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
          title: 'Saved location',
          value: _profile?.locationName ?? 'Choose your service location',
          onTap: canEdit ? _editLocation : null,
        ),
        ProfileSettingsRow(
          icon: Icons.lock_outline,
          title: 'Account security',
          onTap: () => openProfilePage(context, const ProfileSecurityScreen()),
        ),
      ],
    );
  }
}
