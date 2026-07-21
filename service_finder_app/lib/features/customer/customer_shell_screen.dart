import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'customer_home_screen.dart';
import 'customer_profile_screen.dart';
import 'customer_requests_screen.dart';

class CustomerShellScreen extends StatefulWidget {
  // Give a name only when using the development bypass.
  // Normal users will load their information from Firebase.
  final String? debugUserName;

  const CustomerShellScreen({super.key, this.debugUserName});

  @override
  State<CustomerShellScreen> createState() => _CustomerShellScreenState();
}

class _CustomerShellScreenState extends State<CustomerShellScreen> {
  int _currentIndex = 0;

  String _userName = 'User';
  String _initials = 'U';

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    if (widget.debugUserName != null) {
      final debugName = widget.debugUserName!.trim();

      _userName = debugName.isEmpty ? 'Demo Customer' : debugName;
      _initials = _createInitials(_userName);
      _isLoading = false;
    } else {
      _loadCustomerData();
    }
  }

  Future<void> _loadCustomerData() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser == null) {
        _showError('You must sign in before opening this page.');
        return;
      }

      final userDocument = await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (!userDocument.exists || userDocument.data() == null) {
        _showError('Your user profile could not be found.');
        return;
      }

      final userData = userDocument.data()!;

      final role = userData['role'] as String? ?? '';
      final accountStatus = userData['accountStatus'] as String? ?? 'active';

      if (role != 'customer') {
        _showError('This account is not registered as a customer.');
        return;
      }

      if (accountStatus != 'active') {
        _showError('This account is currently unavailable.');
        return;
      }

      final firestoreName = (userData['displayName'] as String?)?.trim();

      final authenticationName = firebaseUser.displayName?.trim();

      final resolvedName = firestoreName != null && firestoreName.isNotEmpty
          ? firestoreName
          : authenticationName != null && authenticationName.isNotEmpty
          ? authenticationName
          : 'User';

      if (!mounted) return;

      setState(() {
        _userName = resolvedName;
        _initials = _createInitials(resolvedName);
        _isLoading = false;
        _errorMessage = null;
      });
    } on FirebaseException catch (error) {
      debugPrint(
        'Customer data loading error: '
        '${error.code} - ${error.message}',
      );

      _showError('Unable to load your account. Please try again.');
    } catch (error) {
      debugPrint('Customer data loading error: $error');

      _showError('Unable to load your account. Please try again.');
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    setState(() {
      _errorMessage = message;
      _isLoading = false;
    });
  }

  String _createInitials(String name) {
    final nameParts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (nameParts.isEmpty) {
      return 'U';
    }

    if (nameParts.length == 1) {
      return nameParts.first[0].toUpperCase();
    }

    final firstInitial = nameParts.first[0];
    final lastInitial = nameParts.last[0];

    return '$firstInitial$lastInitial'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: _ShellErrorView(
          message: _errorMessage!,
          onRetry: _loadCustomerData,
        ),
      );
    }

    final pages = <Widget>[
      CustomerHomeScreen(
        userName: _userName,
        initials: _initials,
      ),

      const CustomerRequestsScreen(),

      const _CustomerPlaceholderPage(
        icon: Icons.notifications_outlined,
        title: 'Notifications',
        message: 'Your notifications will appear here.',
      ),

      const CustomerProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
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
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Requests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            activeIcon: Icon(Icons.notifications),
            label: 'Notifications',
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

class _CustomerPlaceholderPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _CustomerPlaceholderPage({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: Colors.grey),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShellErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ShellErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.red),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: onRetry, child: const Text('Try Again')),
          ],
        ),
      ),
    );
  }
}
