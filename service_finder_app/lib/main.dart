import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'src/features/auth/login_screen.dart';
import 'firebase_options.dart';

void main() async {
  // 1. Establish secure framework channel hooks before running async calls
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 2. Wrap Firebase initialization inside a safe structural try-catch block
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("✅ Firebase initialized successfully!");
  } catch (e) {
    // Prevents application boot thread freezes if parameters mismatch
    print("⚠️ Firebase initialization bypassed or encountered an error: $e");
  }

  // 3. Always execute the app layout loop even if tracking logs error out
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Service Finder App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}