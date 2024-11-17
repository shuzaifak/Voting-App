import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:voting_system/constants.dart';
import 'package:voting_system/result_screens.dart';
import 'HomeScreen.dart';
import 'admin_home_screen.dart';

class AdminResultsScreen extends StatefulWidget {
  @override
  _AdminResultsScreenState createState() => _AdminResultsScreenState();
}

class _AdminResultsScreenState extends State<AdminResultsScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _ongoingElections = [];
  List<Map<String, dynamic>> _completedElections = [];
  bool _isLoading = true;
  bool _mounted = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchElectionResults();
  }

  @override
  void dispose() {
    _mounted = false;
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchElectionResults() async {
    if (!_mounted) return;

    try {
      final now = Timestamp.now();

      // Fetch ongoing elections
      final ongoingDocs = await FirebaseFirestore.instance
          .collection('elections')
          .where('status', isEqualTo: 'active')
          .where('endDate', isGreaterThan: now)
          .get();

      // Fetch completed elections
      final completedDocs = await FirebaseFirestore.instance
          .collection('elections')
          .where('status', isEqualTo: 'completed')
          .where('endDate', isLessThan: now)
          .get();

      final ongoingResults = await _processElections(ongoingDocs);
      final completedResults = await _processElections(completedDocs);

      if (_mounted) {
        setState(() {
          _ongoingElections = ongoingResults;
          _completedElections = completedResults;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching election results: $e');
      if (_mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> _processElections(QuerySnapshot elections) async {
    final results = <Map<String, dynamic>>[];

    for (final electionDoc in elections.docs) {
      if (!_mounted) return results;

      final electionData = electionDoc.data() as Map<String, dynamic>;

      // Fetch votes for this election
      final votesSnapshot = await FirebaseFirestore.instance
          .collection('votes')
          .where('electionId', isEqualTo: electionDoc.id)
          .get();

      // Count votes per candidate
      final candidateVotes = <String, int>{};
      for (final voteDoc in votesSnapshot.docs) {
        final candidateId = voteDoc.data()['candidateId'];
        candidateVotes[candidateId] = (candidateVotes[candidateId] ?? 0) + 1;
      }

      // Fetch candidates
      final candidatesSnapshot = await FirebaseFirestore.instance
          .collection('candidates')
          .where('electionId', isEqualTo: electionDoc.id)
          .get();

      final candidates = <Map<String, dynamic>>[];
      int totalVotes = 0;
      Map<String, dynamic>? winner;

      for (final candidateDoc in candidatesSnapshot.docs) {
        final candidateData = candidateDoc.data();
        final votes = candidateVotes[candidateDoc.id] ?? 0;
        totalVotes += votes;

        candidates.add({
          'id': candidateDoc.id,
          'name': candidateData['name'],
          'position': candidateData['position'] ?? 'Candidate',
          'votes': votes,
          'percentage': totalVotes > 0 ? (votes / totalVotes * 100) : 0.0,
        });

        if (electionData['status'] == 'completed' &&
            (winner == null || votes > (winner['votes'] ?? 0))) {
          winner = candidates.last;
        }
      }

      results.add({
        'id': electionDoc.id,
        'title': electionData['title'],
        'startDate': (electionData['startDate'] as Timestamp).toDate(),
        'endDate': (electionData['endDate'] as Timestamp).toDate(),
        'candidates': candidates,
        'winner': winner,
        'totalVotes': totalVotes,
      });
    }

    return results;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminHomeScreen()),
        );
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AdminHomeScreen()),
            ),
          ),
          title: const Text(
            'Admin Election Results',
            style: TextStyle(color: Colors.white),
          ),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Ongoing Elections'),
              Tab(text: 'Completed Elections'),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
          ),
          backgroundColor: AppColors.primaryBlue,
          elevation: 4,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
          controller: _tabController,
          children: [
            _buildElectionsList(_ongoingElections, isOngoing: true),
            _buildElectionsList(_completedElections, isOngoing: false),
          ],
        ),
      ),
    );
  }

  Widget _buildElectionsList(List<Map<String, dynamic>> elections, {required bool isOngoing}) {
    return elections.isEmpty
        ? Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(
          'No ${isOngoing ? 'ongoing' : 'completed'} elections found',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      ),
    )
        : ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: elections.length,
      itemBuilder: (context, index) =>
          _buildElectionCard(elections[index], isOngoing),
    );
  }

  Widget _buildElectionCard(Map<String, dynamic> election, bool isOngoing) {
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      election['title'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isOngoing ? AppColors.primaryBlue : AppColors.successGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isOngoing ? 'Ongoing' : 'Completed',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                isOngoing
                    ? 'Ends on ${_formatDate(election['endDate'])}'
                    : 'Ended on ${_formatDate(election['endDate'])}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Total Votes: ${election['totalVotes']}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Candidates',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...election['candidates'].map<Widget>((candidate) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  candidate['name'],
                                  style: TextStyle(
                                    fontWeight: !isOngoing && election['winner']?['id'] == candidate['id']
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: !isOngoing && election['winner']?['id'] == candidate['id']
                                        ? AppColors.successGreen
                                        : null,
                                  ),
                                ),
                                Text(
                                  candidate['position'],
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${candidate['votes']} votes (${candidate['percentage'].toStringAsFixed(1)}%)',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: candidate['percentage'] / 100,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation(
                          !isOngoing && election['winner']?['id'] == candidate['id']
                              ? AppColors.successGreen
                              : AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                );
              }),
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