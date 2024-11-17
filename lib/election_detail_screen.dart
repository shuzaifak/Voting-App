import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:voting_system/constants.dart';
import 'package:voting_system/election_list.dart';
import 'package:voting_system/voting_screen.dart';

class ElectionDetailsScreen extends StatefulWidget {
  final String electionId;

  const ElectionDetailsScreen({
    Key? key,
    required this.electionId,
  }) : super(key: key);

  @override
  _ElectionDetailsScreenState createState() => _ElectionDetailsScreenState();
}

class _ElectionDetailsScreenState extends State<ElectionDetailsScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool hasVoted = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkVotingStatus();
  }

  Future<void> _checkVotingStatus() async {
    if (user != null) {
      final voteDoc = await FirebaseFirestore.instance
          .collection('votes')
          .where('electionId', isEqualTo: widget.electionId)
          .where('userId', isEqualTo: user!.uid)
          .get();

      setState(() {
        hasVoted = voteDoc.docs.isNotEmpty;
        isLoading = false;
      });
    }
  }

  Future<void> _navigateToVotingScreen(List<Map<String, dynamic>> candidates) async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ready to Vote?'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Before proceeding, please ensure:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text('• You have reviewed all candidates thoroughly'),
            Text('• You have a stable internet connection'),
            Text('• Your device supports biometric authentication'),
            SizedBox(height: 16),
            Text(
              'Security Steps Required:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('1. Biometric verification'),
            Text('2. Face recognition'),
            Text('3. Final confirmation'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Review Again'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
            ),
            child: const Text(
              'Proceed to Vote',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (proceed != true) return;

    if (!mounted) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => VotingScreen(
          electionId: widget.electionId,
          candidates: candidates,
        ),
      ),
    );

    if (result == true) {
      _checkVotingStatus();
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
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('elections')
            .doc(widget.electionId)
            .snapshots(),
        builder: (context, electionSnapshot) {
          if (electionSnapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (!electionSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final electionData = electionSnapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildElectionHeader(electionData),
                const SizedBox(height: 24),
                _buildSecurityInfo(),
                const SizedBox(height: 24),
                _buildVotingRules(),
                const SizedBox(height: 24),
                _buildCandidatesList(electionData),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildElectionHeader(Map<String, dynamic> electionData) {
    final endDate = (electionData['endDate'] as Timestamp).toDate();
    final daysRemaining = endDate.difference(DateTime.now()).inDays;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.how_to_vote, color: AppColors.primaryBlue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    electionData['title'],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              electionData['description'] ?? 'No description available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer, color: AppColors.primaryBlue),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$daysRemaining days remaining',
                        style: const TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Ends on ${_formatDate(endDate)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
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
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildSecurityInfo() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.security, color: AppColors.primaryBlue),
                SizedBox(width: 8),
                Text(
                  'Security Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSecurityItem(
              Icons.lock,
              'End-to-end encryption',
              'Your vote is encrypted and cannot be traced back to you',
            ),
            _buildSecurityItem(
              Icons.verified_user,
              'Dual Authentication',
              'Biometric and facial recognition required',
            ),
            _buildSecurityItem(
              Icons.history,
              'Immutable Record',
              'Votes are permanently recorded and cannot be altered',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVotingRules() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.gavel, color: AppColors.primaryBlue),
                SizedBox(width: 8),
                Text(
                  'Voting Rules',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildRule('You can only vote once in this election'),
            _buildRule('Your vote cannot be changed after submission'),
            _buildRule('Verify your selection before confirming'),
            _buildRule('Both authentication steps are mandatory'),
          ],
        ),
      ),
    );
  }

  Widget _buildRule(String rule) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.successGreen, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(rule),
          ),
        ],
      ),
    );
  }

  Widget _buildCandidateCard(String candidateId, Map<String, dynamic> candidateData) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                  child: Text(
                    candidateData['name'][0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24,
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
                        candidateData['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        candidateData['position'] ?? 'Candidate',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              candidateData['description'] ?? 'No description available',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Update _buildCandidatesList method
  Widget _buildCandidatesList(Map<String, dynamic> electionData) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('candidates')
          .where('electionId', isEqualTo: widget.electionId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Failed to load candidates'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final candidates = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            ...data,
          };
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Candidates',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: candidates.length,
              itemBuilder: (context, index) {
                return _buildCandidateCard(
                  candidates[index]['id'],
                  candidates[index],
                );
              },
            ),
            const SizedBox(height: 24),
            if (!hasVoted && !isLoading)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToVotingScreen(candidates),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.how_to_vote, color: Colors.white),
                  label: const Text(
                    'Proceed to Vote',
                    style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              )
            else if (hasVoted)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      'You have already voted in this election',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}