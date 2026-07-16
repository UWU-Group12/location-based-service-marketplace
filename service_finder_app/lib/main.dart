import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'services/pref_service.dart';
import 'features/auth/splash_screen.dart';
import 'features/auth/welcome_screen.dart';
import 'features/customer/customer_shell_screen.dart';
import 'core/app_theme.dart';
import 'package:provider/provider.dart';
import 'features/provider/provider_onboarding_provider.dart';
import 'features/provider/provider_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Prevent [core/duplicate-app] error during hot restarts
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    if (!e.toString().contains('duplicate-app')) {
      rethrow;
    }
  }
  
  final bool isFirstLaunch =
    await PrefService.isFirstLaunch();

final bool isProviderCompleted =
    await PrefService.isProviderOnboardingCompleted();

  
  runApp(
  ChangeNotifierProvider(
    create: (_) => ProviderOnboardingProvider(),
    child: MyApp(
      isFirstLaunch: isFirstLaunch,
      isProviderCompleted: isProviderCompleted,
    ),
  ),
);

}

class MyApp extends StatelessWidget {
  final bool isFirstLaunch;
  final bool isProviderCompleted;

  const MyApp({
    super.key,
    required this.isFirstLaunch,
    required this.isProviderCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Service Finder',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: isFirstLaunch
    ? const SplashScreen()
    : isProviderCompleted
        ? const ProviderDashboardScreen(
            userName: "Provider",
          )
        : const AuthWrapper(),
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
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          return const CustomerShellScreen();
        }
        return const WelcomeScreen();
      },
    );
  }
}
