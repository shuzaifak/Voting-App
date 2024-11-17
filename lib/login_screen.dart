import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:voting_system/main.dart';
import 'package:voting_system/signup_screen.dart';
import 'package:voting_system/admin_login_screen.dart';
import 'HomeScreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Set Firebase language code to prevent null locale warning
    FirebaseAuth.instance.setLanguageCode('en');
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  String? _validateEmail(String? value) {
    final RegExp emailRegExp = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (value == null || value.isEmpty) {
      return 'Email is required';
    } else if (!emailRegExp.hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    } else if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }


  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Initialize Firebase Auth
        final auth = FirebaseAuth.instance;

        // Configure reCAPTCHA verification
        await auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ).timeout(
          const Duration(seconds: 60),
          onTimeout: () {
            throw FirebaseAuthException(
              code: 'timeout',
              message: 'Login timeout. Please try again.',
            );
          },
        );

        // Check if current user exists and is verified
        final user = auth.currentUser;
        if (user != null) {
          if (user.emailVerified) {
            _showSnackBar('Login successful!');
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            }
          } else {
            // Send verification email if not verified
            await user.sendEmailVerification();
            _showSnackBar('Please verify your email before logging in. Verification email sent.');
            await auth.signOut();
          }
        }
      } on FirebaseAuthException catch (e) {
        String message;
        switch (e.code) {
          case 'user-not-found':
            message = 'No user found for that email.';
            break;
          case 'wrong-password':
            message = 'Wrong password provided for that user.';
            break;
          case 'invalid-email':
            message = 'The email address is badly formatted.';
            break;
          case 'user-disabled':
            message = 'This user account has been disabled.';
            break;
          case 'timeout':
            message = 'Login timeout. Please check your internet connection.';
            break;
          case 'too-many-requests':
            message = 'Too many attempts. Please try again later.';
            break;
          default:
            message = 'An error occurred. Please try again.';
        }
        _showSnackBar(message);
      } catch (e) {
        _showSnackBar('An unexpected error occurred. Please try again.');
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
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
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 48),
                  // Login Icon and Text
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryBlue.withOpacity(0.1),
                        ),
                        child: Icon(
                          Icons.login_rounded,
                          size: 64,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Log in',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Email Field
                        CustomTextField(
                          hintText: 'Email',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: _validateEmail,
                          prefixIcon: const Icon(Icons.email_outlined),
                        ),
                        const SizedBox(height: 16),
                        // Password Field
                        CustomTextField(
                          hintText: 'Password',
                          obscureText: !_isPasswordVisible,
                          controller: _passwordController,
                          keyboardType: TextInputType.visiblePassword,
                          validator: _validatePassword,
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: Colors.grey,
                            ),
                            onPressed: _togglePasswordVisibility,
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Login Button
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _login,
                          icon: const Icon(Icons.login, color: Colors.white),
                          label: _isLoading
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : const Text(
                            'Log in',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 2,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Admin Login Button
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AdminLoginScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.admin_panel_settings),
                          label: const Text(
                            'Admin Login',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            foregroundColor: AppColors.primaryBlue,
                            side: const BorderSide(color: AppColors.primaryBlue),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Sign Up Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Don't have an account?",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SignupScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.person_add_outlined,
                                size: 20,
                              ),
                              label: const Text(
                                'Sign up',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primaryBlue,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Loading Overlay
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Make sure you have this CustomTextField widget defined in your project
class CustomTextField extends StatelessWidget {
  final String hintText;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final String? Function(String?)? validator;

  const CustomTextField({
    Key? key,
    required this.hintText,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffixIcon,
    this.prefixIcon,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: AppColors.primaryBlue,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 2,
          ),
        ),
      ),
    );
  }
}