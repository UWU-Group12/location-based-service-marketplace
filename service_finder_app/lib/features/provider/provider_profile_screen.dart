import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_router.dart';
import '../../models/provider_model.dart';
import '../../models/review_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';
import '../../services/profile_edit_service.dart';
import '../../services/review_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/profile_settings.dart';
import '../customer/personal_information_screen.dart';
import 'provider_professional_profile_screen.dart';
import 'provider_profile_status_controller.dart';
import 'provider_service_area_screen.dart';
import 'provider_status_section.dart';

class ProviderProfileScreen extends StatefulWidget {
  final bool focusReviews;

  const ProviderProfileScreen({super.key, this.focusReviews = false});

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  final _auth = AuthService();
  final _firestore = FirestoreService();
  final _reviews = ReviewService();
  final _reviewsKey = GlobalKey();
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
  bool _focusedReviews = false;

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

  void _focusReviewsIfNeeded() {
    if (!widget.focusReviews || _focusedReviews || _loading || _failed) return;
    _focusedReviews = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _reviewsKey.currentContext;
      if (!mounted || context == null) return;
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
        alignment: 0.15,
      );
    });
  }

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
    _focusReviewsIfNeeded();
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
        ProviderReviewsSection(
          key: _reviewsKey,
          reviews: _profile == null
              ? null
              : _reviews.watchProviderReviews(_profile!.providerId),
          highlight: widget.focusReviews,
          onTap: () => AppRouter.goToProviderReviews(context),
        ),
      ],
    );
  }
}

class ProviderReviewsSection extends StatelessWidget {
  final Stream<List<ReviewModel>>? reviews;
  final bool highlight;
  final VoidCallback? onTap;

  const ProviderReviewsSection({
    super.key,
    required this.reviews,
    this.highlight = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (reviews == null) {
      return _ProviderReviewsContent(
        average: 0,
        count: 0,
        comments: const [],
        loading: false,
        error: false,
        onTap: onTap,
      );
    }
    return StreamBuilder<List<ReviewModel>>(
      stream: reviews,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _ProviderReviewsContent(
            average: 0,
            count: 0,
            comments: const [],
            loading: false,
            error: true,
            highlight: highlight,
            onTap: onTap,
          );
        }
        if (!snapshot.hasData) {
          return _ProviderReviewsContent(
            average: 0,
            count: 0,
            comments: const [],
            loading: true,
            error: false,
            highlight: highlight,
            onTap: onTap,
          );
        }
        final reviewList = snapshot.data!;
        final count = reviewList.length;
        final average = count == 0
            ? 0.0
            : reviewList.fold<double>(
                    0,
                    (total, review) => total + review.rating,
                  ) /
                  count;
        final comments = reviewList
            .map((review) => review.comment)
            .whereType<String>()
            .map((comment) => comment.trim())
            .where((comment) => comment.isNotEmpty)
            .take(2)
            .toList(growable: false);
        return _ProviderReviewsContent(
          average: average,
          count: count,
          comments: comments,
          loading: false,
          error: false,
          highlight: highlight,
          onTap: onTap,
        );
      },
    );
  }
}

class _ProviderReviewsContent extends StatelessWidget {
  final double average;
  final int count;
  final List<String> comments;
  final bool loading;
  final bool error;
  final bool highlight;
  final VoidCallback? onTap;

  const _ProviderReviewsContent({
    required this.average,
    required this.count,
    required this.comments,
    required this.loading,
    required this.error,
    this.highlight = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        color: highlight ? AppColors.providerCard : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.star_border, color: AppColors.primary, size: 23),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reviews',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  if (loading)
                    const LinearProgressIndicator(minHeight: 2)
                  else if (error)
                    const Text(
                      'Could not load reviews.',
                      style: TextStyle(color: AppColors.textSecondary),
                    )
                  else ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: AppColors.rating,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          count == 0
                              ? 'No ratings yet'
                              : average.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        if (count > 0) ...[
                          const SizedBox(width: 6),
                          Text(
                            '($count ${count == 1 ? "review" : "reviews"})',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (comments.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      for (final comment in comments) ...[
                        Text(
                          '“$comment”',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (comment != comments.last) const SizedBox(height: 6),
                      ],
                    ],
                  ],
                ],
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ],
        ),
      ),
    );
  }
}
