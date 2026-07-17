import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'provider_dashboard_screen.dart';
import 'provider_profile_screen.dart';

class ProviderShellScreen extends StatefulWidget {
  // Give a name only when using the development bypass.
  final String? debugUserName;

  const ProviderShellScreen({
    super.key,
    this.debugUserName,
  });

  @override
  State<ProviderShellScreen> createState() =>
      _ProviderShellScreenState();
}

class _ProviderShellScreenState extends State<ProviderShellScreen> {
  int _currentIndex = 0;

  String _providerName = 'Provider';

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    if (widget.debugUserName != null) {
      final debugName = widget.debugUserName!.trim();

      _providerName =
      debugName.isEmpty ? 'Demo Provider' : debugName;

      _isLoading = false;
    } else {
      _loadProviderData();
    }
  }

  Future<void> _loadProviderData() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser == null) {
        _showError('You must sign in before opening this page.');
        return;
      }

      final firestore = FirebaseFirestore.instance;

      final userDocument = await firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (!userDocument.exists || userDocument.data() == null) {
        _showError('Your user profile could not be found.');
        return;
      }

      final userData = userDocument.data()!;

      final role = userData['role'] as String? ?? '';
      final accountStatus =
          userData['accountStatus'] as String? ?? 'active';

      if (role != 'provider') {
        _showError(
          'This account is not registered as a service provider.',
        );
        return;
      }

      if (accountStatus != 'active') {
        _showError('This account is currently unavailable.');
        return;
      }

      final providerDocument = await firestore
          .collection('providerProfiles')
          .doc(firebaseUser.uid)
          .get();

      final providerData = providerDocument.data();

      final professionalName =
      (providerData?['displayName'] as String?)?.trim();

      final userName =
      (userData['displayName'] as String?)?.trim();

      final authenticationName =
      firebaseUser.displayName?.trim();

      final resolvedName =
      professionalName != null && professionalName.isNotEmpty
          ? professionalName
          : userName != null && userName.isNotEmpty
          ? userName
          : authenticationName != null &&
          authenticationName.isNotEmpty
          ? authenticationName
          : 'Provider';

      if (!mounted) return;

      setState(() {
        _providerName = resolvedName;
        _isLoading = false;
        _errorMessage = null;
      });
    } on FirebaseException catch (error) {
      debugPrint(
        'Provider data loading error: '
            '${error.code} - ${error.message}',
      );

      _showError(
        'Unable to load your provider account. Please try again.',
      );
    } catch (error) {
      debugPrint('Provider data loading error: $error');

      _showError(
        'Unable to load your provider account. Please try again.',
      );
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    setState(() {
      _errorMessage = message;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: _ProviderShellErrorView(
          message: _errorMessage!,
          onRetry: _loadProviderData,
        ),
      );
    }

    final pages = <Widget>[
      ProviderDashboardScreen(
        userName: _providerName,
      ),
      const _ProviderPlaceholderPage(
        icon: Icons.inbox_outlined,
        title: 'Requests',
        message: 'New customer requests will appear here.',
      ),
      const _ProviderPlaceholderPage(
        icon: Icons.work_outline,
        title: 'Jobs',
        message: 'Confirmed and active jobs will appear here.',
      ),
      const ProviderProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF8B0000),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inbox_outlined),
            activeIcon: Icon(Icons.inbox),
            label: 'Requests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            activeIcon: Icon(Icons.work),
            label: 'Jobs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _ProviderPlaceholderPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _ProviderPlaceholderPage({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 56,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProviderShellErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ProviderShellErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 56,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}