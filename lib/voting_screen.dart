import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:local_auth/local_auth.dart';
import 'package:voting_system/election_list.dart';
import 'package:voting_system/main.dart';

import 'authentication_service.dart';

class VotingScreen extends StatefulWidget {
  final String electionId;
  final List<Map<String, dynamic>> candidates;

  const VotingScreen({
    Key? key,
    required this.electionId,
    required this.candidates,
  }) : super(key: key);

  @override
  _VotingScreenState createState() => _VotingScreenState();
}

class _VotingScreenState extends State<VotingScreen> {
  final BiometricAuthService _authService = BiometricAuthService();
  final User? user = FirebaseAuth.instance.currentUser;

  bool _isLoading = false;
  bool _isBiometricAuthenticated = false;
  bool _isFaceAuthenticated = false;
  String? _selectedCandidateId;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final isSupported = await _authService.checkBiometricSupport();
      if (!isSupported) {
        setState(() {
          _errorMessage = 'Biometric authentication is not available on this device';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error checking biometric availability: $e';
      });
    }
  }

  Future<bool> _authenticateWithBiometrics() async {
    try {
      setState(() => _isLoading = true);

      final result = await _authService.authenticateWithBiometrics();

      if (!mounted) return false;

      if (!result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }

      setState(() {
        _isBiometricAuthenticated = result.success;
        _isLoading = false;
      });

      return result.success;
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Authentication error: $e';
      });
      return false;
    }
  }

  Future<bool> _authenticateWithFaceID() async {
    try {
      setState(() => _isLoading = true);

      final result = await _authService.authenticateWithFaceID();

      if (!mounted) return false;

      if (!result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }

      setState(() {
        _isFaceAuthenticated = result.success;
        _isLoading = false;
      });

      return result.success;
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Face authentication error: $e';
      });
      return false;
    }
  }

  Future<void> _castVote() async {
    if (!_isBiometricAuthenticated || !_isFaceAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete both authentication steps'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedCandidateId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a candidate'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Your Vote'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your vote will be:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.how_to_vote, color: AppColors.primaryBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.candidates
                          .firstWhere((c) => c['id'] == _selectedCandidateId)['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '• Your vote will be encrypted\n'
                  '• This action cannot be undone\n'
                  '• Your vote will remain anonymous',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
            ),
            child: const Text('Confirm Vote', style: TextStyle(color: Colors.white),),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      setState(() => _isLoading = true);

      // Simulate encryption process
      await Future.delayed(const Duration(seconds: 1));

      await FirebaseFirestore.instance.collection('votes').add({
        'electionId': widget.electionId,
        'candidateId': _selectedCandidateId,
        'userId': user!.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'encryptedData': true, // In a real app, implement actual encryption
      });

      setState(() => _isLoading = false);

      if (!mounted) return;

      Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ElectionListScreen()),
          );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vote cast successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to cast vote. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            MaterialPageRoute(builder: (context) => const ElectionListScreen()),
          ),
        ),
        title: const Text(
          'Elections',
          style: TextStyle(color: Colors.white),  // Ensuring text color matches
        ),
        backgroundColor: AppColors.primaryBlue,  // Keeping the same background color
        elevation: 4,  // Adding elevation to match the card style
        iconTheme: const IconThemeData(color: Colors.white),  // Ensuring all icons match
      ),
      body: _isLoading
          ? _buildLoadingState()
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSecurityHeader(),
            const SizedBox(height: 24),
            _buildAuthenticationSection(),
            const SizedBox(height: 24),
            _buildCandidateSelection(),
            const SizedBox(height: 24),
            _buildVoteButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Processing...\nPlease do not close the app',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityHeader() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.security, color: AppColors.primaryBlue),
                SizedBox(width: 8),
                Text(
                  'Secure Voting System',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'This voting system uses multiple layers of security to ensure your vote is secure and anonymous.',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthenticationSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Authentication Required',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 16),
            _buildAuthStep(
              'Biometric Authentication',
              _isBiometricAuthenticated,
              Icons.fingerprint,
              _authenticateWithBiometrics,
            ),
            const SizedBox(height: 16),
            _buildAuthStep(
              'Face Recognition',
              _isFaceAuthenticated,
              Icons.face,
              _authenticateWithFaceID,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthStep(
      String title,
      bool isCompleted,
      IconData icon,
      Future<bool> Function() onAuthenticate,
      ) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryBlue),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                isCompleted ? 'Verified' : 'Required',
                style: TextStyle(
                  color: isCompleted ? Colors.green : Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        if (!isCompleted)
          ElevatedButton(
            onPressed: onAuthenticate,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
            ),
            child: const Text('Verify' , style: TextStyle(color: Colors.white)),
          )
        else
          const Icon(Icons.check_circle, color: Colors.green),
      ],
    );
  }

  Widget _buildCandidateSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Your Candidate',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBlue,
          ),
        ),
        const SizedBox(height: 16),
        ...widget.candidates.map((candidate) => _buildCandidateCard(candidate)),
      ],
    );
  }

  Widget _buildCandidateCard(Map<String, dynamic> candidate) {
    final isSelected = _selectedCandidateId == candidate['id'];

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => setState(() => _selectedCandidateId = candidate['id']),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primaryBlue : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                child: Text(
                  candidate['name'][0].toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      candidate['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      candidate['position'] ?? 'Candidate',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Radio<String>(
                value: candidate['id'],
                groupValue: _selectedCandidateId,
                onChanged: (value) => setState(() => _selectedCandidateId = value),
                activeColor: AppColors.primaryBlue,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoteButton() {
    final canVote = _isBiometricAuthenticated &&
        _isFaceAuthenticated &&
        _selectedCandidateId != null;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canVote ? _castVote : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Cast Vote',
          style: TextStyle(fontSize: 18,color: Colors.white),
        ),
      ),
    );
  }
}