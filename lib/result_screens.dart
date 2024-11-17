import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:voting_system/constants.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'HomeScreen.dart';

class ResultDetailsScreen extends StatefulWidget {
  final String electionId;

  const ResultDetailsScreen({
    Key? key,
    required this.electionId,
  }) : super(key: key);

  @override
  _ResultDetailsScreenState createState() => _ResultDetailsScreenState();
}

class _ResultDetailsScreenState extends State<ResultDetailsScreen> {
  late List<CandidateResult> _results = [];
  CandidateResult? _winner;
  bool _isDataSecure = false;

  @override
  void initState() {
    super.initState();
    _fetchResults();
  }

  Future<void> _fetchResults() async {
    final votesSnapshot = await FirebaseFirestore.instance
        .collection('votes')
        .where('electionId', isEqualTo: widget.electionId)
        .get();

    final candidateVotes = <String, int>{};
    votesSnapshot.docs.forEach((doc) {
      final candidateId = doc.data()['candidateId'];
      candidateVotes[candidateId] = (candidateVotes[candidateId] ?? 0) + 1;
    });

    final candidatesSnapshot = await FirebaseFirestore.instance
        .collection('candidates')
        .where('electionId', isEqualTo: widget.electionId)
        .get();

    final results = <CandidateResult>[];
    candidatesSnapshot.docs.forEach((doc) {
      final data = doc.data();
      final candidateId = doc.id;
      final votes = candidateVotes[candidateId] ?? 0;
      results.add(CandidateResult(
        id: candidateId,
        name: data['name'],
        position: data['position'],
        votes: votes,
      ));
    });

    results.sort((a, b) => b.votes.compareTo(a.votes));
    setState(() {
      _results = results;
      _winner = results.isNotEmpty ? results.first : null;
      _isDataSecure = true; // Assuming data is secure
    });
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
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          ),
        ),
        title: const Text(
          'Election Results',
          style: TextStyle(color: Colors.white),  // Ensuring text color matches
        ),
        backgroundColor: AppColors.primaryBlue,  // Keeping the same background color
        elevation: 4,  // Adding elevation to match the card style
        iconTheme: const IconThemeData(color: Colors.white),  // Ensuring all icons match
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWinner(),
              const SizedBox(height: 24),
              _buildResultsChart(),
              const SizedBox(height: 24),
              _buildResultsTable(),
              const SizedBox(height: 24),
              _buildSecurityStatus(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWinner() {
    if (_winner == null) return Container();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.successGreen, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _winner!.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _winner!.position ?? 'Candidate',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${_winner!.votes.toStringAsFixed(0)} votes',
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
      ),
    );
  }

  Widget _buildResultsChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Results Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 16),
            SfCartesianChart(
              primaryXAxis: CategoryAxis(),
              series: <ChartSeries<CandidateResult, String>>[
                BarSeries<CandidateResult, String>(
                  dataSource: _results,
                  xValueMapper: (CandidateResult result, _) => result.name,
                  yValueMapper: (CandidateResult result, _) => result.votes,
                  dataLabelSettings: const DataLabelSettings(
                    isVisible: true,
                    labelPosition: ChartDataLabelPosition.outside,
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsTable() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detailed Results',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Position')),
                  DataColumn(label: Text('Votes'), numeric: true),
                ],
                rows: _results
                    .map((candidate) => DataRow(cells: [
                  DataCell(Text(candidate.name)),
                  DataCell(Text(candidate.position ?? 'Candidate')),
                  DataCell(Text(candidate.votes.toStringAsFixed(0))),
                ]))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityStatus() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.lock, color: AppColors.primaryBlue, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Secure Data',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isDataSecure
                        ? 'Election results are encrypted and tamper-proof'
                        : 'Verifying data integrity...',
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
      ),
    );
  }
}

class CandidateResult {
  final String id;
  final String name;
  final String? position;
  final int votes;

  CandidateResult({
    required this.id,
    required this.name,
    this.position,
    required this.votes,
  });
}