import 'package:flutter/material.dart';
import '../../core/app_router.dart';
import '../../services/auth_service.dart';
import '../../core/app_colors.dart';

class CustomerRegisterScreen extends StatefulWidget {
  final String role;
  const CustomerRegisterScreen({super.key, required this.role});

  @override
  State<CustomerRegisterScreen> createState() => _CustomerRegisterScreenState();
}

class _CustomerRegisterScreenState extends State<CustomerRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await _authService.registerWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          {
            'firstName': _firstNameController.text.trim(),
            'lastName': _lastNameController.text.trim(),
            'mobile': _mobileController.text.trim(),
            'role': widget.role,
          },
        );
        if (mounted) {
          if (widget.role == 'Customer') {
            AppRouter.goToCustomerDashboard(context);
          } else {
            AppRouter.goToProviderDashboard(context);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _googleSignUp() async {
     setState(() => _isLoading = true);
    try {
      await _authService.signInWithGoogle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google Sign-Up failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final darkRed = AppColors.primary; // Material Red 900 or similar
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary, size: 20),
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
                const SizedBox(height: 0),
                Text(
                  'Register',
                  style: textTheme.headlineLarge?.copyWith(
                    fontSize: 40,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _firstNameController,
                  decoration: _buildInputDecoration('First Name', Icons.edit_outlined),
                  validator: (value) => value!.isEmpty ? 'Enter first name' : null,
                ),
                const SizedBox(height: 13),
                TextFormField(
                  controller: _lastNameController,
                  decoration: _buildInputDecoration('Last Name', Icons.edit_outlined),
                  validator: (value) => value!.isEmpty ? 'Enter last name' : null,
                ),
                const SizedBox(height: 13),
                TextFormField(
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                  decoration: _buildInputDecoration('Mobile Number', Icons.phone_android_outlined),
                  validator: (value) => value!.isEmpty ? 'Enter mobile number' : null,
                ),
                const SizedBox(height: 13),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _buildInputDecoration('Email', Icons.alternate_email),
                  validator: (value) => value!.isEmpty ? 'Enter email' : null,
                ),
                const SizedBox(height: 13),
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
                  validator: (value) => value!.length < 6 ? 'Password must be 6+ chars' : null,
                ),
                const SizedBox(height: 30),
                _isLoading
                    ? Center(child: CircularProgressIndicator(color: darkRed))
                    : ElevatedButton(
                        onPressed: _register,
                        child: const Text('Register'),
                      ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(child: Divider(thickness: 1, color: AppColors.hint.withValues(alpha: 0.4))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'or',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.hint.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    Expanded(child: Divider(thickness: 1, color: AppColors.hint.withValues(alpha: 0.4))),
                  ],
                ),
                const SizedBox(height: 30),
                _buildGoogleButton(_googleSignUp),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary.withValues(alpha: 0.54),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        AppRouter.goToLogin(context);
                      },
                      child: Text(
                        'Login',
                        style: textTheme.labelLarge?.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
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
      hintStyle: TextStyle(color: AppColors.hint.withValues(alpha: 0.8), fontSize: 15),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 20, right: 10),
        child: Icon(icon, color: AppColors.hint.withValues(alpha: 0.8), size: 22),
      ),
      suffixIcon: isPassword
          ? Padding(
              padding: const EdgeInsets.only(right: 20),
              child: IconButton(
                icon: Icon(
                  isVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: AppColors.hint.withValues(alpha: 0.8),
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

  Widget _buildGoogleButton(VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.googleButton,
        foregroundColor: AppColors.textPrimary,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.network(
            'https://img.icons8.com/?size=256&id=17949&format=png',
            height: 24,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
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
