import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/widgets/floating_glass_navigation_bar.dart';
import '../../services/location_service.dart';
import '../../widgets/greeting_header.dart';

class ProviderDashboardScreen extends StatefulWidget {
  final String userName;
  final bool isDemo;

  const ProviderDashboardScreen({
    super.key,
    required this.userName,
    this.isDemo = false,
  });

  @override
  State<ProviderDashboardScreen> createState() =>
      _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  DocumentReference<Map<String, dynamic>>? _profile;
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _profileStream;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _jobsStream;
  bool _savingAvailability = false;
  bool _fetchingLocation = false;

  @override
  void initState() {
    super.initState();
    if (widget.isDemo) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _profile = FirebaseFirestore.instance
        .collection('providerProfiles')
        .doc(uid);
    _profileStream = _profile!.snapshots();
    _jobsStream = FirebaseFirestore.instance
        .collection('serviceRequests')
        .where('providerId', isEqualTo: uid)
        .snapshots();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _setAvailability(bool available) async {
    if (_profile == null || _savingAvailability) return;
    setState(() => _savingAvailability = true);
    try {
      await _profile!.update({
        'availabilityStatus': available ? 'available' : 'unavailable',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      _showError('Unable to update availability. Please try again.');
    } finally {
      if (mounted) setState(() => _savingAvailability = false);
    }
  }

  Future<void> _fetchLocation() async {
    if (_profile == null || _fetchingLocation) return;
    setState(() => _fetchingLocation = true);
    try {
      final location = await LocationService().getCurrentLocation();
      if (!mounted) return;
      await _profile!.update({
        'baseLocation': location,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on StateError catch (error) {
      _showError(error.message.toString());
    } catch (_) {
      _showError('Unable to save your location. Please try again.');
    } finally {
      if (mounted) setState(() => _fetchingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _profileStream,
          builder: (context, snapshot) {
            final profile = snapshot.data?.data();
            final name = (profile?['displayName'] as String?)?.trim();
            final displayName = name != null && name.isNotEmpty
                ? name
                : widget.userName.trim();
            final firstName = displayName.isEmpty
                ? 'Provider'
                : displayName.split(RegExp(r'\s+')).first;
            final available = profile?['availabilityStatus'] == 'available';
            final location = profile?['baseLocation'] as GeoPoint?;
            final canEdit = profile != null && !snapshot.hasError;
            final statusColor = available
                ? Colors.green.shade700
                : Colors.red.shade700;

            return ListView(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                FloatingGlassNavigationBar.clearanceFor(context) + 16,
              ),
              children: [
                const SizedBox(height: 8),
                GreetingHeader(firstName: firstName),
                const SizedBox(height: 24),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const LinearProgressIndicator(),
                if (snapshot.hasError)
                  const Text(
                    'Unable to load your provider profile. Please reopen the dashboard to retry.',
                  ),
                if (_profile == null)
                  Text(
                    widget.isDemo
                        ? 'Demo preview. Sign in to manage your dashboard.'
                        : 'Sign in to manage your dashboard.',
                  ),
                if (_profile != null &&
                    snapshot.connectionState != ConnectionState.waiting &&
                    !snapshot.hasError &&
                    profile == null)
                  const Text(
                    'Complete your provider profile to manage availability and location.',
                  ),
                _card(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Available?',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              canEdit
                                  ? (available
                                        ? 'Ready to take new jobs'
                                        : 'Currently unavailable')
                                  : 'Availability not loaded',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 32,
                        child: VerticalDivider(
                          width: 24,
                          thickness: 0.5,
                          color: AppColors.border,
                        ),
                      ),
                      if (_savingAvailability) ...[
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        available ? 'Yes' : 'No',
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Switch(
                        value: available,
                        onChanged: canEdit && !_savingAvailability
                            ? _setAvailability
                            : null,
                        activeThumbColor: Colors.white,
                        activeTrackColor: Colors.green.shade700,
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: Colors.red.shade700,
                        trackOutlineColor: const WidgetStatePropertyAll(
                          Colors.transparent,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _card(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Your location',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              location == null
                                  ? 'Location not fetched'
                                  : '${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.outlined(
                        tooltip: 'Fetch current location',
                        onPressed: canEdit && !_fetchingLocation
                            ? _fetchLocation
                            : null,
                        icon: _fetchingLocation
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.my_location),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _buildJobCards(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildJobCards() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _jobsStream,
      builder: (context, snapshot) {
        final jobs = snapshot.data?.docs ?? [];
        final activeJobs = jobs
            .where(
              (job) =>
                  job.data()['requestStatus'] == 'confirmed' ||
                  job.data()['requestStatus'] == 'in_progress',
            )
            .toList();
        activeJobs.sort((a, b) {
          final first = a.data()['createdAt'] as Timestamp?;
          final second = b.data()['createdAt'] as Timestamp?;
          return (second?.millisecondsSinceEpoch ?? 0).compareTo(
            first?.millisecondsSinceEpoch ?? 0,
          );
        });
        final completedJobs = jobs.where(
          (job) => job.data()['requestStatus'] == 'completed',
        );
        final earnings = completedJobs.fold<double>(
          0,
          (total, job) =>
              total + ((job.data()['finalAmount'] as num?)?.toDouble() ?? 0),
        );
        final loading = snapshot.connectionState == ConnectionState.waiting;
        final unavailable =
            snapshot.hasError || (_jobsStream == null && !widget.isDemo);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _cardTitle(Icons.work_outline, 'Active jobs'),
                  const SizedBox(height: 20),
                  if (loading)
                    const Center(child: CircularProgressIndicator())
                  else if (unavailable)
                    const Text(
                      'Unable to load jobs. Please reopen the dashboard to retry.',
                    )
                  else if (activeJobs.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'No active jobs yet. Confirmed jobs will appear here.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  else ...[
                    Text(
                      '${activeJobs.length} active',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    for (final job in activeJobs) ...[
                      const Divider(height: 28),
                      Text(
                        (job.data()['title'] as String?) ?? 'Service job',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        job.data()['requestStatus'] == 'in_progress'
                            ? 'In progress'
                            : 'Confirmed',
                        style: const TextStyle(color: AppColors.primary),
                      ),
                      if ((job.data()['serviceLocation']
                              as Map?)?['addressText']
                          case final String address
                          when address.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          address,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            _card(
              color: AppColors.providerCard,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _cardTitle(
                    Icons.account_balance_wallet_outlined,
                    'Total earnings',
                  ),
                  const SizedBox(height: 20),
                  if (loading)
                    const LinearProgressIndicator()
                  else if (unavailable)
                    const Text('Earnings are currently unavailable.')
                  else ...[
                    Text(
                      'LKR ${earnings.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'From ${completedJobs.length} completed jobs',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _cardTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _card({required Widget child, Color color = Colors.white}) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(padding: const EdgeInsets.all(20), child: child),
    );
  }
}
