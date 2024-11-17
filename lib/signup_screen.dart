import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:voting_system/main.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _countryCodeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  DateTime? _selectedDate;
  String? _selectedGender;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    const Text(
                      'Register Account',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 32),
                    CustomTextField(
                      hintText: 'Username',
                      controller: _usernameController,
                      validator: _validateUsername,
                      keyboardType: TextInputType.text,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      hintText: 'Email',
                      controller: _emailController,
                      validator: _validateEmail,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedGender,
                      hint: const Text('Select Gender'),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedGender = newValue;
                        });
                      },
                      items: ['Male', 'Female', 'Other']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      validator: _validateGender,
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: AbsorbPointer(
                        child: CustomTextField(
                          hintText: 'Date of Birth',
                          controller: _dobController,
                          validator: _validateDOB,
                          keyboardType: TextInputType.datetime,
                          suffixIcon: const Icon(Icons.calendar_today),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: CustomTextField(
                            hintText: 'Country Code',
                            controller: _countryCodeController,
                            validator: _validateCountryCode,
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 5,
                          child: CustomTextField(
                            hintText: 'Phone Number',
                            controller: _phoneController,
                            validator: _validatePhone,
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      hintText: 'Password',
                      obscureText: _obscurePassword,
                      controller: _passwordController,
                      validator: _validatePassword,
                      keyboardType: TextInputType.visiblePassword,
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      hintText: 'Confirm Password',
                      obscureText: _obscureConfirmPassword,
                      controller: _confirmPasswordController,
                      validator: _validateConfirmPassword,
                      keyboardType: TextInputType.visiblePassword,
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleSignup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Register',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.white),
                            ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }
    if (value.length < 3) {
      return 'Username must be at least 3 characters long';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validateGender(String? value) {
    if (_selectedGender == null || _selectedGender!.isEmpty) {
      return 'Gender is required';
    }
    return null;
  }

  String? _validateCountryCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Country code is required';
    }
    if (!RegExp(r'^\+?[\d]{1,4}$').hasMatch(value)) {
      return 'Enter a valid country code';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    if (!RegExp(r'^\+?[\d]{10,14}$').hasMatch(value)) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirm password is required';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  String? _validateDOB(String? value) {
    if (value == null || value.isEmpty) {
      return 'Date of Birth is required';
    }
    if (_selectedDate == null) {
      return 'Please select a valid date';
    }
    return null;
  }

  void _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Check network connectivity
        var connectivityResult = await Connectivity().checkConnectivity();
        if (connectivityResult == ConnectivityResult.none) {
          throw Exception('No internet connection');
        }

        // Create user account
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
            email: _emailController.text,
            password: _passwordController.text);

        // Send email verification
        await userCredential.user!.sendEmailVerification();

        // Save user data to Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'username': _usernameController.text,
          'email': _emailController.text,
          'gender': _selectedGender,
          'dob': _dobController.text,
          'phone': _phoneController.text,
          'countryCode': _countryCodeController.text,
        });

        setState(() {
          _isLoading = false;
        });

        _showDialog('Success',
            'Account created successfully! Please check your email for verification.');
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        String errorMessage = 'Failed to create account. Please try again.';

        if (e is FirebaseAuthException) {
          switch (e.code) {
            case 'weak-password':
              errorMessage = 'The password provided is too weak.';
              break;
            case 'email-already-in-use':
              errorMessage = 'The account already exists for that email.';
              break;
            case 'invalid-email':
              errorMessage = 'The email address is not valid.';
              break;
          // Add more specific FirebaseAuth error cases as needed
          }
        } else if (e is FirebaseException) {
          errorMessage = 'Firebase error: ${e.message}';
        } else if (e is Exception) {
          errorMessage = e.toString();
        }

        print('Error during signup: $e'); // For debugging
        _showDialog('Error', errorMessage);
      }
    }
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                if (title == 'Success') {
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }
}
