import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:voting_system/login_screen.dart';
import 'package:voting_system/main.dart';
import 'package:intl/intl.dart';

import 'HomeScreen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;
  Map<String, dynamic> userData = {};
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();

  // Controllers for editing
  late TextEditingController _usernameController;
  late TextEditingController _phoneController;
  late TextEditingController _dobController;
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _phoneController = TextEditingController();
    _dobController = TextEditingController();
    _fetchUserData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    setState(() => _isLoading = true);
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .get();

      if (doc.exists) {
        setState(() {
          userData = doc.data() as Map<String, dynamic>;
          _usernameController.text = userData['username'] ?? '';
          _phoneController.text = userData['phone'] ?? '';
          _dobController.text = userData['dob'] ?? '';
          _selectedGender = userData['gender'];
        });
      }
    } catch (e) {
      _showSnackBar('Error fetching user data');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .update({
        'username': _usernameController.text,
        'phone': _phoneController.text,
        'dob': _dobController.text,
        'gender': _selectedGender,
      });
      _showSnackBar('Profile updated successfully');
      setState(() => _isEditing = false);
      await _fetchUserData();
    } catch (e) {
      _showSnackBar('Error updating profile');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _showChangePasswordDialog() async {
    final TextEditingController currentPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (newPasswordController.text != confirmPasswordController.text) {
                _showSnackBar('Passwords do not match');
                return;
              }
              try {
                // Reauthenticate user
                AuthCredential credential = EmailAuthProvider.credential(
                  email: user?.email ?? '',
                  password: currentPasswordController.text,
                );
                await user?.reauthenticateWithCredential(credential);

                // Change password
                await user?.updatePassword(newPasswordController.text);
                Navigator.pop(context);
                _showSnackBar('Password updated successfully');
              } catch (e) {
                _showSnackBar('Error updating password');
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primaryBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_dobController.text) ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,  // Matches existing color scheme
          ),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          ),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.white),  // Ensuring text color matches
        ),
        backgroundColor: AppColors.primaryBlue,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.primaryBlue,
                      child: Text(
                        (_usernameController.text.isNotEmpty ? _usernameController.text[0] : '?').toUpperCase(),
                        style: const TextStyle(fontSize: 40, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user?.email ?? '',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Profile Fields
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField(
                        label: 'Username',
                        controller: _usernameController,
                        enabled: _isEditing,
                        validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'Phone',
                        controller: _phoneController,
                        enabled: _isEditing,
                        keyboardType: TextInputType.phone,
                        validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      if (_isEditing) ...[
                        DropdownButtonFormField<String>(
                          value: _selectedGender,
                          decoration: const InputDecoration(
                            labelText: 'Gender',
                            border: OutlineInputBorder(),
                          ),
                          items: ['Male', 'Female', 'Other']
                              .map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedGender = newValue;
                            });
                          },
                        ),
                      ] else ...[
                        _buildInfoRow('Gender', _selectedGender ?? ''),
                      ],
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'Date of Birth',
                        controller: _dobController,
                        enabled: _isEditing,
                        readOnly: true,
                        onTap: _isEditing ? () => _selectDate(context) : null,
                        suffixIcon: _isEditing
                            ? const Icon(Icons.calendar_today)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              if (_isEditing)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() => _isEditing = false);
                          _fetchUserData();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Save',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 16),

              // Security Section
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Security',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.lock),
                        title: const Text('Change Password'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: _showChangePasswordDialog,
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.security),
                        title: const Text('Two-Factor Authentication'),
                        trailing: Switch(
                          value: false, // TODO: Implement 2FA
                          onChanged: (bool value) {
                            // TODO: Implement 2FA
                            _showSnackBar('2FA coming soon');
                          },
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.logout),
                        title: const Text('Logout'),
                        onTap: () async {
                          await FirebaseAuth.instance.signOut();
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LoginScreen(),
                              )
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool enabled = true,
    bool readOnly = false,
    String? Function(String?)? validator,
    VoidCallback? onTap,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      readOnly: readOnly,
      validator: validator,
      onTap: onTap,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: suffixIcon,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}