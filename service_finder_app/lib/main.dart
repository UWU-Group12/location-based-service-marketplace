import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_theme.dart';
import 'features/auth/role_selection_screen.dart';
import 'features/auth/splash_screen.dart';
import 'features/auth/welcome_screen.dart';
import 'features/customer/customer_shell_screen.dart';
import 'features/provider/provider_onboarding/build_professional_profile.dart';
import 'features/provider/provider_onboarding_provider.dart';
import 'features/provider/provider_shell_screen.dart';
import 'firebase_options.dart';
import 'models/user_model.dart';
import 'services/auth_service.dart';
import 'services/pref_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Prevents duplicate Firebase initialization during hot restarts.
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (error) {
    if (!error.toString().contains('duplicate-app')) {
      rethrow;
    }
  }

  final isFirstLaunch = await PrefService.isFirstLaunch();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ProviderOnboardingProvider(),
      child: MyApp(isFirstLaunch: isFirstLaunch),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isFirstLaunch;

  const MyApp({super.key, required this.isFirstLaunch});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Service Finder',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: isFirstLaunch ? const SplashScreen() : const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final firebaseUser = snapshot.data;
        if (firebaseUser == null) {
          return const WelcomeScreen();
        }

        return _SignedInHome(userId: firebaseUser.uid);
      },
    );
  }
}

class _SignedInHome extends StatelessWidget {
  final String userId;

  const _SignedInHome({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel?>(
      stream: AuthService().watchUserProfile(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return _AccountMessage(
            message: 'Could not load your account: ${snapshot.error}',
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const RoleSelectionScreen();
        }

        if (!user.isActive) {
          return _AccountMessage(
            message:
                'This account is ${user.accountStatus.name}. '
                'Please contact support.',
          );
        }

        switch (user.role) {
          case UserRole.customer:
            return const CustomerShellScreen();
          case UserRole.provider:
            if (user.profileCompleted) {
              return const ProviderShellScreen();
            }

            return const BuildProfessionalProfile();
        }
      },
    );
  }
}

class _AccountMessage extends StatelessWidget {
  final String message;

  const _AccountMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => AuthService().signOut(),
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
