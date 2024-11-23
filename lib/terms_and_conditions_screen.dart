import 'package:flutter/material.dart';
import 'constants.dart';
import 'election_detail_screen.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  final String electionId;

  const TermsAndConditionsScreen({
    Key? key,
    required this.electionId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Terms & Conditions',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryBlue,
        elevation: 4,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSecurityNotice(),
                    const SizedBox(height: 24),
                    _buildTermsSection(
                      'Voting Integrity',
                      'By participating in this election, you agree to cast only one vote and '
                          'acknowledge that any attempt to manipulate the voting process is strictly '
                          'prohibited and may result in legal action.',
                      Icons.how_to_vote,
                    ),
                    _buildTermsSection(
                      'Data Privacy',
                      'Your vote is completely anonymous and encrypted using blockchain technology. '
                          'While your participation is recorded to prevent duplicate voting, your '
                          'specific voting choice cannot be linked back to your identity.',
                      Icons.lock_outline,
                    ),
                    _buildTermsSection(
                      'Voter Eligibility',
                      'You confirm that you meet all eligibility requirements for this election '
                          'and have not been disqualified from voting. Providing false information '
                          'about your eligibility is a violation of these terms.',
                      Icons.person_outline,
                    ),
                    _buildTermsSection(
                      'System Security',
                      'You agree not to attempt to bypass any security measures or interfere '
                          'with the voting system\'s operation. Any suspicious activity will be '
                          'monitored and reported to relevant authorities.',
                      Icons.security,
                    ),
                    _buildTermsSection(
                      'Vote Finality',
                      'Once submitted, your vote cannot be changed or withdrawn. Please review '
                          'your selection carefully before final submission.',
                      Icons.done_all,
                    ),
                  ],
                ),
              ),
            ),
            _buildBottomActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityNotice() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.verified_user,
            color: AppColors.primaryBlue,
            size: 48,
          ),
          const SizedBox(height: 8),
          Text(
            'Secure Electronic Voting System',
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please review the following terms and conditions carefully before proceeding with your vote.',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTermsSection(String title, String content, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryBlue),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ElectionDetailsScreen(
                    electionId: electionId,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'I Agree to the Terms & Conditions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Decline',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}