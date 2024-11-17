import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:voting_system/constants.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'admin_home_screen.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  _ManageUsersScreenState createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _countryCodeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedGender = 'Male';
  bool _isLoading = false;
  bool _isEditing = false;
  String? _currentEditingId;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  DateTime? _selectedDate;
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey = GlobalKey<ScaffoldMessengerState>();
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    _countryCodeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();

      setState(() {
        _users = snapshot.docs
            .map((doc) => {
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
        })
            .toList();
      });
    } catch (e) {
      _showErrorSnackBar('Error fetching users: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }


  Future<void> _handleGoogleApiError(dynamic error) async {
    String errorMessage = 'An error occurred with Google services';

    if (error.toString().contains('GoogleApiManager')) {
      errorMessage = 'Google API connection error. Please check your internet connection and try again.';
    }

    _showErrorSnackBar(errorMessage);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryBlue,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _sendVerificationEmail(String email, String password) async {
    try {
      // Create user with email and password
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // Send verification email
      await userCredential.user?.sendEmailVerification();

      _showSuccessSnackBar('Verification email sent to $email');
    } catch (e) {
      _showErrorSnackBar('Error sending verification email: ${e.toString()}');
    }
  }

  Future<bool> _checkUserExists(String email) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      _showErrorSnackBar('Error checking user existence: ${e.toString()}');
      return false;
    }
  }


  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim();

      // Only check for existing user when creating new user
      if (!_isEditing) {
        final userExists = await _checkUserExists(email);
        if (userExists) {
          _showErrorSnackBar('User with this email already exists');
          setState(() => _isLoading = false);
          return;
        }
      }

      final userData = {
        'username': _usernameController.text.trim(),
        'email': email,
        'gender': _selectedGender,
        'dob': _dobController.text.trim(),
        'phone': _phoneController.text.trim(),
        'countryCode': _countryCodeController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_isEditing && _currentEditingId != null) {
        // Update existing user
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentEditingId)
            .update(userData);

        // Update password if provided
        if (_passwordController.text.isNotEmpty) {
          try {
            User? user = FirebaseAuth.instance.currentUser;
            if (user != null && user.email == email) {
              await user.updatePassword(_passwordController.text);
            }
          } catch (e) {
            _showErrorSnackBar('Error updating password: ${e.toString()}');
          }
        }

        _showSuccessSnackBar('User updated successfully');
      } else {
        // Creating new user with Firebase Auth
        try {
          // First create the user in Firebase Auth to get the UID
          UserCredential userCredential = await FirebaseAuth.instance
              .createUserWithEmailAndPassword(
              email: email,
              password: _passwordController.text
          );

          String uid = userCredential.user!.uid;

          // Use the UID as document ID in Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)  // Using UID instead of email
              .set({
            ...userData,
            'createdAt': FieldValue.serverTimestamp(),
          });

          // Send verification email
          await userCredential.user?.sendEmailVerification();
          _showSuccessSnackBar('User created successfully');

          // Sign out the newly created user since this is an admin operation
          await FirebaseAuth.instance.signOut();

          // Sign back in as admin if needed
          // Note: You might want to implement proper admin authentication handling
        } catch (e) {
          _showErrorSnackBar('Error creating user: ${e.toString()}');
          return;
        }
      }

      _clearForm();
      await _fetchUsers();
    } catch (e) {
      String errorMessage = 'Error saving user';
      if (e.toString().contains('PERMISSION_DENIED')) {
        errorMessage += ': Permission denied. Please check your Firestore security rules.';
      } else {
        errorMessage += ': ${e.toString()}';
      }
      _showErrorSnackBar(errorMessage);
    } finally {
      setState(() => _isLoading = false);
    }
  }



  Future<void> _deleteUser(String docId, String username) async {
    try {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete User'),
          content: Text('Are you sure you want to delete $username?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                setState(() => _isLoading = true);
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(docId)
                    .delete();
                _showSuccessSnackBar('User deleted successfully');
                _fetchUsers();
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Error deleting user: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }


  void _editUser(Map<String, dynamic> user) {
    setState(() {
      _isEditing = true;
      // Store both the ID and email
      _currentEditingId = user['id'];  // Use the document ID for Firestore operations
      _usernameController.text = user['username'];
      _emailController.text = user['email'];
      _selectedGender = user['gender'];
      _dobController.text = user['dob'];
      _phoneController.text = user['phone'];
      _countryCodeController.text = user['countryCode'];
      _passwordController.clear();
      _confirmPasswordController.clear();
    });
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _usernameController.clear();
    _emailController.clear();
    _dobController.clear();
    _phoneController.clear();
    _countryCodeController.clear();
    setState(() {
      _selectedGender = 'Male';
      _isEditing = false;
      _currentEditingId = null;
    });
  }

  void _showErrorSnackBar(String message) {
    // Dismiss any existing SnackBar
    _scaffoldKey.currentState?.removeCurrentSnackBar();

    _scaffoldKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.fixed, // Changed from floating to fixed
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () {
            _scaffoldKey.currentState?.hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    _scaffoldKey.currentState?.removeCurrentSnackBar();

    _scaffoldKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.fixed, // Changed from floating to fixed
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () {
            _scaffoldKey.currentState?.hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldKey,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,  // Matching the default AppBar icon color
            ),
            style: IconButton.styleFrom(
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AdminHomeScreen()),
            ),
          ),
          title: const Text(
            'Manage Users',
            style: TextStyle(color: Colors.white),  // Ensuring text color matches
          ),
          backgroundColor: AppColors.primaryBlue,  // Keeping the same background color
          elevation: 4,  // Adding elevation to match the card style
          iconTheme: const IconThemeData(color: Colors.white),  // Ensuring all icons match
        ),
        body: SafeArea(
          child: Stack(
            children: [
              Container(
                color: Colors.grey[100],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Check if screen is too narrow for side-by-side layout
                      if (constraints.maxWidth < 900) {
                        return SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildFormSection(constraints),
                              const SizedBox(height: 24),
                              _buildListSection(constraints),
                            ],
                          ),
                        );
                      }

                      // Wide screen layout
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildFormSection(constraints),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 3,
                            child: _buildListSection(constraints),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              if (_isLoading)
                Container(
                  color: Colors.black26,
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormSection(BoxConstraints constraints) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              _isEditing ? 'Edit User' : 'Create New User',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
            if (_isEditing)
              TextButton(
                onPressed: _clearForm,
                child: const Text('Cancel Edit'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        constraints.maxWidth < 900
            ? _buildUserForm()
            : Expanded(child: _buildUserForm()),
      ],
    );
  }

  Widget _buildListSection(BoxConstraints constraints) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Existing Users',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBlue,
          ),
        ),
        const SizedBox(height: 16),
        constraints.maxWidth < 900
            ? SizedBox(
          height: 400, // Fixed height for mobile layout
          child: _buildUserList(),
        )
            : Expanded(child: _buildUserList()),
      ],
    );
  }

  Widget _buildUserForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextFormField(
                'Username',
                _usernameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a username';
                  }
                  if (value.length < 3) {
                    return 'Username must be at least 3 characters';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              _buildTextFormField(
                'Email',
                _emailController,
                enabled: !_isEditing,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email';
                  }
                  if (!EmailValidator.validate(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              _buildPasswordField(),
              SizedBox(height: 16),
              _buildConfirmPasswordField(),
              SizedBox(height: 16),
              _buildDropdown(),
              SizedBox(height: 16),
              _buildDatePicker(),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildTextFormField(
                      'Country Code',
                      _countryCodeController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (!RegExp(r'^\+\d{1,4}$').hasMatch(value)) {
                          return 'Invalid code';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    flex: 5,
                    child: _buildTextFormField(
                      'Phone Number',
                      _phoneController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter phone number';
                        }
                        if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                          return 'Invalid phone number';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  minimumSize: Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  _isEditing ? 'Update User' : 'Create User',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                      color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_showPassword,
      validator: (value) {
        if (!_isEditing && (value == null || value.isEmpty)) {
          return 'Please enter a password';
        }
        if (value != null && value.isNotEmpty && value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: 'Password',
        labelStyle: TextStyle(color: Colors.grey[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _showPassword ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey[600],
          ),
          onPressed: () {
            setState(() {
              _showPassword = !_showPassword;
            });
          },
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: !_showConfirmPassword,
      validator: (value) {
        if (!_isEditing && (value == null || value.isEmpty)) {
          return 'Please confirm your password';
        }
        if (value != _passwordController.text) {
          return 'Passwords do not match';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: 'Confirm Password',
        labelStyle: TextStyle(color: Colors.grey[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _showConfirmPassword ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey[600],
          ),
          onPressed: () {
            setState(() {
              _showConfirmPassword = !_showConfirmPassword;
            });
          },
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildDatePicker() {
    return TextFormField(
      controller: _dobController,
      readOnly: true,
      onTap: () => _selectDate(context),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select date of birth';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: 'Date of Birth',
        labelStyle: TextStyle(color: Colors.grey[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        suffixIcon: const Icon(Icons.calendar_today),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }


  Widget _buildUserList() {
    if (_isLoading && _users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_users.isEmpty) {
      return Center(
        child: Text(
          'No users found',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: _users.length,
          separatorBuilder: (context, index) => Divider(height: 1),
          itemBuilder: (context, index) {
            final user = _users[index];
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  left: BorderSide(
                    color: Colors.transparent,
                    width: 4,
                  ),
                ),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                leading: CircleAvatar(
                  backgroundColor: AppColors.primaryBlue.withOpacity(0.9),
                  radius: 24,
                  child: Text(
                    user['username'][0].toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                title: Text(
                  user['username'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 4),
                    Text(
                      user['email'],
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '${user['countryCode']} ${user['phone']}',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                trailing: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 100),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: AppColors.primaryBlue),
                        onPressed: () => _editUser(user),
                        tooltip: 'Edit User',
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteUser(user['id'], user['username']),
                        tooltip: 'Delete User',
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }


  Widget _buildTextFormField(
      String label,
      TextEditingController controller, {
        String? Function(String?)? validator,
        bool enabled = true,
      }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primaryBlue),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red),
        ),
        filled: true,
        fillColor: enabled ? Colors.grey[50] : Colors.grey[100],
        errorMaxLines: 2,
      ),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      onChanged: (value) {
        setState(() {
          _selectedGender = value!;
        });
      },
      decoration: InputDecoration(
        labelText: 'Gender',
        labelStyle: TextStyle(color: Colors.grey[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primaryBlue),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items: ['Male', 'Female', 'Other']
          .map((gender) => DropdownMenuItem(
        value: gender,
        child: Text(gender),
      ))
          .toList(),
    );
  }
}