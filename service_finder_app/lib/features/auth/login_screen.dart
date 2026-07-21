import 'package:flutter/material.dart';
import '../../core/app_router.dart';
import '../../services/auth_service.dart';
import '../../core/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _authService.loginWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      final user = result.user;

      if (user == null) {
        throw Exception('Login succeeded but user data is missing.');
      }

      final userProfile = await _authService.requireActiveUserProfile(user.uid);

      if (!mounted) {
        return;
      }

      AppRouter.goToSignedInHome(context, userProfile);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login failed: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _googleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _authService.signInWithGoogle();

      // The user closed the Google account selection window.
      if (result == null) {
        return;
      }

      final firebaseUser = result.user;
      if (firebaseUser == null) {
        throw StateError('Firebase did not return the Google user.');
      }

      final existingProfile = await _authService.getUserProfile(
        firebaseUser.uid,
      );

      if (!mounted) return;

      if (existingProfile == null) {
        AppRouter.goToRoleSelection(context);
        return;
      }

      final userProfile = await _authService.requireActiveUserProfile(
        firebaseUser.uid,
      );

      if (!mounted) return;

      AppRouter.goToSignedInHome(context, userProfile);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Google Sign-In failed: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final darkRed = AppColors.primary; // Dark Red
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.primary,
            size: 20,
          ),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 30),
                Text(
                  'Login',
                  style: textTheme.headlineLarge?.copyWith(
                    fontSize: 40,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 60),
                TextFormField(
                  controller: _emailController,
                  decoration: _buildInputDecoration(
                    'Email',
                    Icons.alternate_email,
                  ),
                  validator: (value) => value!.isEmpty ? 'Enter email' : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: _buildInputDecoration(
                    'Password',
                    Icons.lock_outline,
                    isPassword: true,
                    onToggleVisibility: () {
                      setState(() => _isPasswordVisible = !_isPasswordVisible);
                    },
                    isVisible: _isPasswordVisible,
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Enter password' : null,
                ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: () {
                      if (_emailController.text.isNotEmpty) {
                        _authService.sendPasswordResetEmail(
                          _emailController.text.trim(),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Password reset email sent!'),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Enter your email first'),
                          ),
                        );
                      }
                    },
                    child: Text(
                      'Forgot Password',
                      style: textTheme.labelMedium?.copyWith(
                        color: AppColors.textSecondary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _isLoading
                    ? Center(child: CircularProgressIndicator(color: darkRed))
                    : ElevatedButton(
                        onPressed: _login,
                        child: const Text('Login'),
                      ),
                const SizedBox(height: 40),
                Row(
                  children: [
                    const Expanded(child: Divider(thickness: 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'or',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.hint,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider(thickness: 1)),
                  ],
                ),
                const SizedBox(height: 30),
                _buildGoogleButton(_isLoading ? null : _googleSignIn),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Need an account ? ',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        AppRouter.goToRoleSelection(context);
                      },
                      child: Text(
                        'Sign up',
                        style: textTheme.labelLarge?.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Center(
                  child: TextButton(
                    onPressed: () {
                      AppRouter.goToDevBypass(context);
                    },
                    child: Text(
                      'Development Bypass (Preview Dashboards)',
                      style: textTheme.labelSmall?.copyWith(
                        color: Colors.blue,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(
    String label,
    IconData icon, {
    bool isPassword = false,
    VoidCallback? onToggleVisibility,
    bool isVisible = false,
  }) {
    return InputDecoration(
      hintText: label,
      hintStyle: const TextStyle(color: AppColors.hint, fontSize: 16),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 20, right: 10),
        child: Icon(icon, color: AppColors.hint, size: 22),
      ),
      suffixIcon: isPassword
          ? Padding(
              padding: const EdgeInsets.only(right: 20),
              child: IconButton(
                icon: Icon(
                  isVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.hint,
                  size: 22,
                ),
                onPressed: onToggleVisibility,
              ),
            )
          : null,
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: AppColors.focusedBorder),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    );
  }

  Widget _buildGoogleButton(VoidCallback? onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.googleButton,
        foregroundColor: AppColors.textPrimary,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.network(
            'https://img.icons8.com/?size=256&id=17949&format=png',
            height: 24,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.error),
          ),
          const SizedBox(width: 10),
          Text(
            'Continue with Google',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
