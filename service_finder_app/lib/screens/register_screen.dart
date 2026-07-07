import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  final String role;
  const RegisterScreen({super.key, required this.role});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

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
           Navigator.of(context).popUntil((route) => route.isFirst);
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
    final darkRed = const Color(0xFFB71C1C); // Material Red 900 or similar

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF8B0000), size: 20),
          onPressed: () => Navigator.of(context).pop(),
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
                const SizedBox(height: 20),
                const Text(
                  'Register',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF8B0000),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _firstNameController,
                  decoration: _buildInputDecoration('First Name', Icons.edit_outlined),
                  validator: (value) => value!.isEmpty ? 'Enter first name' : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _lastNameController,
                  decoration: _buildInputDecoration('Last Name', Icons.edit_outlined),
                  validator: (value) => value!.isEmpty ? 'Enter last name' : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                  decoration: _buildInputDecoration('Mobile Number', Icons.phone_android_outlined),
                  validator: (value) => value!.isEmpty ? 'Enter mobile number' : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _buildInputDecoration('Email', Icons.alternate_email),
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
                  validator: (value) => value!.length < 6 ? 'Password must be 6+ chars' : null,
                ),
                const SizedBox(height: 30),
                _isLoading
                    ? Center(child: CircularProgressIndicator(color: darkRed))
                    : ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB00000), // Red color from image
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Register',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                const SizedBox(height: 40),
                Row(
                  children: [
                    const Expanded(child: Divider(thickness: 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text('or', style: TextStyle(color: Colors.grey[600])),
                    ),
                    const Expanded(child: Divider(thickness: 1)),
                  ],
                ),
                const SizedBox(height: 30),
                _buildGoogleButton(_googleSignUp),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(color: Colors.black54),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          color: Color(0xFF8B0000),
                          fontWeight: FontWeight.bold,
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
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 16),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 20, right: 10),
        child: Icon(icon, color: Colors.grey, size: 22),
      ),
      suffixIcon: isPassword
          ? Padding(
              padding: const EdgeInsets.only(right: 20),
              child: IconButton(
                icon: Icon(
                  isVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: Colors.grey,
                  size: 22,
                ),
                onPressed: onToggleVisibility,
              ),
            )
          : null,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Colors.black12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Colors.black26),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  Widget _buildGoogleButton(VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFF1F1F1),
        foregroundColor: Colors.black,
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
          const Text(
            'Continue with Google',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
