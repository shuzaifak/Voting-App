import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_home_screen.dart';
import 'constants.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({Key? key}) : super(key: key);

  @override
  _AdminLoginScreenState createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final TextEditingController _adminEmailController = TextEditingController();
  final TextEditingController _adminPasswordController = TextEditingController();
  final _adminFormKey = GlobalKey<FormState>();
  bool _isAdminPasswordVisible = false;
  bool _isLoading = false;

  void _toggleAdminPasswordVisibility() {
    setState(() {
      _isAdminPasswordVisible = !_isAdminPasswordVisible;
    });
  }

  String? _validateAdminEmail(String? value) {
    final RegExp emailRegExp = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (value == null || value.isEmpty) {
      return 'Email is required';
    } else if (!emailRegExp.hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? _validateAdminPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    } else if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  Future<void> _adminLogin() async {
    if (_adminFormKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('admin')
            .where('email', isEqualTo: _adminEmailController.text)
            .where('password', isEqualTo: _adminPasswordController.text)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          // Show success message before navigation
          _showSnackBar('Admin login successful!');
          // Add a slight delay before navigation to allow SnackBar to be seen
          await Future.delayed(const Duration(milliseconds: 500));
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminHomeScreen()),
          );
        } else {
          _showSnackBar('Invalid admin credentials. Please try again.');
        }
      } catch (e) {
        _showSnackBar('An error occurred. Please try again.');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    // Clear any existing SnackBars
    ScaffoldMessenger.of(context).clearSnackBars();

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
        behavior: SnackBarBehavior.floating,
        // Use a more reliable positioning approach
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _adminEmailController.dispose();
    _adminPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // Custom App Bar with rounded bottom
          Container(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Admin Login',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      // Admin Icon
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryBlue.withOpacity(0.1),
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings,
                          size: 80,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Admin Login Form
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 10,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _adminFormKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              CustomTextField(
                                hintText: 'Admin Email',
                                controller: _adminEmailController,
                                keyboardType: TextInputType.emailAddress,
                                validator: _validateAdminEmail,
                                prefixIcon: const Icon(Icons.email_outlined),
                              ),
                              const SizedBox(height: 16),
                              CustomTextField(
                                hintText: 'Admin Password',
                                obscureText: !_isAdminPasswordVisible,
                                controller: _adminPasswordController,
                                keyboardType: TextInputType.visiblePassword,
                                validator: _validateAdminPassword,
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isAdminPasswordVisible
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: Colors.grey,
                                  ),
                                  onPressed: _toggleAdminPasswordVisibility,
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _isLoading ? null : _adminLogin,
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
                                  'Login as Admin',
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
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// CustomTextField widget (same as in the login screen)
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
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.primaryBlue,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 2,
          ),
        ),
      ),
    );
  }
}
