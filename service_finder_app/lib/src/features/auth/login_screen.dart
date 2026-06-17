import 'package:flutter/material.dart';
import '../home_screen.dart';
import 'data/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;

  void _handleLogin() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.loginWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Login Successful!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)
                  )
                      : const Text('Login'),
                ),

                const SizedBox(height: 24),

                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text('OR', style: TextStyle(color: Colors.grey)),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),

                const SizedBox(height: 24),

                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: _isLoading
                      ? const SizedBox.shrink()
                      : const Icon(Icons.g_mobiledata, size: 28, color: Colors.red),
                  label: _isLoading
                      ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)
                  )
                      : const Text('Sign in with Google'),
                  onPressed: _isLoading ? null : () async {
                    setState(() {
                      _isLoading = true;
                    });

                    try {
                      var userCredential = await _authService.signInWithGoogle();

                      // Strict check for build context transitions
                      if (userCredential != null && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('✅ Google Login Successful!')),
                        );

                        if (context.mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const HomeScreen()),
                          );
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('❌ Error: $e')),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() {
                          _isLoading = false;
                        });
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}