import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:voting_system/constants.dart';
import 'package:voting_system/election_detail_screen.dart';
import 'package:voting_system/result_screens.dart';
import 'HomeScreen.dart';

class ResultsScreen extends StatefulWidget {
  @override
  _ResultsScreenState createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  List<Map<String, dynamic>> _electionResults = [];
  bool _isLoading = true;
  bool _mounted = true; // Track mounted state

  @override
  void initState() {
    super.initState();
    _fetchElectionResults();
  }

  @override
  void dispose() {
    _mounted = false; // Set mounted to false when disposing
    super.dispose();
  }

  Future<void> _fetchElectionResults() async {
    if (!_mounted) return; // Check if widget is still mounted before proceeding

    try {
      final now = Timestamp.now();

      final electionDocs = await FirebaseFirestore.instance
          .collection('elections')
          .where('status', isEqualTo: 'completed')
          .where('endDate', isLessThan: now)
          .get();

      final results = <Map<String, dynamic>>[];

      for (final electionDoc in electionDocs.docs) {
        if (!_mounted) return; // Check mounted state during loop

        final electionData = electionDoc.data();

        if (electionData['status'] != 'completed') {
          continue;
        }

        final votesSnapshot = await FirebaseFirestore.instance
            .collection('votes')
            .where('electionId', isEqualTo: electionDoc.id)
            .get();

        final candidateVotes = <String, int>{};
        for (final voteDoc in votesSnapshot.docs) {
          final candidateId = voteDoc.data()['candidateId'];
          candidateVotes[candidateId] = (candidateVotes[candidateId] ?? 0) + 1;
        }

        final candidatesSnapshot = await FirebaseFirestore.instance
            .collection('candidates')
            .where('electionId', isEqualTo: electionDoc.id)
            .get();

        int totalVotes = 0;
        Map<String, dynamic>? winner;
        for (final candidateDoc in candidatesSnapshot.docs) {
          final candidateData = candidateDoc.data();
          final votes = candidateVotes[candidateDoc.id] ?? 0;
          totalVotes += votes;

          if (winner == null || votes > (winner['votes'] ?? 0)) {
            winner = {
              'id': candidateDoc.id,
              'name': candidateData['name'],
              'position': candidateData['position'] ?? 'Candidate',
              'votes': votes,
            };
          }
        }

        results.add({
          'id': electionDoc.id,
          'title': electionData['title'],
          'startDate': (electionData['startDate'] as Timestamp).toDate(),
          'endDate': (electionData['endDate'] as Timestamp).toDate(),
          'winner': winner,
          'totalVotes': totalVotes,
        });
      }

      if (_mounted) { // Only call setState if still mounted
        setState(() {
          _electionResults = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching election results: $e');
      if (_mounted) { // Only call setState if still mounted
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
            style: IconButton.styleFrom(
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            ),
          ),
          title: const Text(
            'Election Results',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.primaryBlue,
          elevation: 4,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Completed Election Results',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: 16),
                if (_electionResults.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text(
                        'No completed elections found',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  )
                else
                  ..._electionResults.map((election) => _buildElectionResultCard(election)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Rest of the code remains the same...
  Widget _buildElectionResultCard(Map<String, dynamic> election) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResultDetailsScreen(electionId: election['id']),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                election['title'],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ended on ${_formatDate(election['endDate'])}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Winner',
                        style: TextStyle(
                          color: AppColors.successGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        election['winner']['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        election['winner']['position'] ?? 'Candidate',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Total Votes',
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        election['totalVotes'].toStringAsFixed(0),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}