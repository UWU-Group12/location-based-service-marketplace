import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'customer_home_screen.dart';
import '../provider/provider_dashboard_screen.dart';

class CustomerShellScreen extends StatefulWidget {
  final String? debugRole; // Optional parameter for development bypass
  const CustomerShellScreen({super.key, this.debugRole});

  @override
  State<CustomerShellScreen> createState() => _CustomerShellScreenState();
}

class _CustomerShellScreenState extends State<CustomerShellScreen> {
  int _currentIndex = 0;
  String _userName = 'Nimal'; // Default for preview
  String _initials = 'NP'; // Default for preview
  String _userRole = 'Customer';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.debugRole != null) {
      // Use debug mode values
      _userRole = widget.debugRole == 'Service Provider' ? 'Service Provider' : 'Customer';
      _isLoading = false;
    } else {
      // Regular Firebase mode
      _fetchUserData();
    }
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data();
        final firstName = data?['firstName'] ?? 'User';
        final lastName = data?['lastName'] ?? '';
        setState(() {
          _userName = firstName;
          _initials = "${firstName[0]}${lastName.isNotEmpty ? lastName[0] : ''}".toUpperCase();
          _userRole = data?['role'] ?? 'Customer';
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final List<Widget> pages = _userRole == 'Customer' 
        ? [
            CustomerHomeScreen(userName: _userName, initials: _initials),
            const Center(child: Text('Requests Page')),
            const Center(child: Text('Updates Page')),
            const Center(child: Text('Profile Page')),
          ]
        : [
            ProviderDashboardScreen(userName: _userName),
            const Center(child: Text('Appointments Page')),
            const Center(child: Text('Earning Page')),
            const Center(child: Text('Profile Page')),
          ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF8B0000),
        unselectedItemColor: Colors.grey,
        items: _userRole == 'Customer' 
          ? const [
              BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home', activeIcon: Icon(Icons.home)),
              BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Requests'),
              BottomNavigationBarItem(icon: Icon(Icons.notifications_none_outlined), label: 'Updates'),
              BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
            ]
          : const [
              BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard', activeIcon: Icon(Icons.dashboard)),
              BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: 'Jobs'),
              BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Earnings'),
              BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
            ],
      ),
    );
  }
}
