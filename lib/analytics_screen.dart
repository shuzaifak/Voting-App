import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'constants.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedTimeFrame = 'Week';
  final List<String> _timeFrames = ['Week', 'Month', 'Year'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Analytics Dashboard',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryBlue,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTimeFrameSelector(),
              const SizedBox(height: 24),
              _buildOverviewCards(),
              const SizedBox(height: 24),
              _buildVoterTurnoutChart(),
              const SizedBox(height: 24),
              _buildElectionStatusBreakdown(),
              const SizedBox(height: 24),
              _buildRecentActivityList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeFrameSelector() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Time Frame:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            DropdownButton<String>(
              value: _selectedTimeFrame,
              items: _timeFrames.map((String frame) {
                return DropdownMenuItem<String>(
                  value: frame,
                  child: Text(frame),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedTimeFrame = newValue;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('elections').snapshots(),
      builder: (context, electionSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('votes').snapshots(),
          builder: (context, votesSnapshot) {
            if (!electionSnapshot.hasData || !votesSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final totalElections = electionSnapshot.data!.docs.length;
            final totalVotes = votesSnapshot.data!.docs.length;

            // Calculate completion rate
            int completedElections = 0;
            for (var doc in electionSnapshot.data!.docs) {
              if (doc['status'] == 'completed') {
                completedElections++;
              }
            }
            final completionRate = totalElections > 0
                ? (completedElections / totalElections * 100).toStringAsFixed(1)
                : '0';

            return LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = (constraints.maxWidth - 32) / 3;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: cardWidth,
                      child: _buildOverviewCard(
                        'Total Elections',
                        totalElections.toString(),
                        Icons.how_to_vote,
                        Colors.blue,
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _buildOverviewCard(
                        'Total Votes',
                        totalVotes.toString(),
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _buildOverviewCard(
                        'Completion Rate',
                        '$completionRate%',
                        Icons.trending_up,
                        Colors.orange,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildOverviewCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoterTurnoutChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Voter Turnout',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            AspectRatio(
              aspectRatio: 1.7,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('votes')
                    .orderBy('timestamp')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final List<FlSpot> spots = _processVoteData(snapshot.data!.docs);

                  return LineChart(
                    LineChartData(
                      gridData: FlGridData(show: true),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: true),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: AppColors.primaryBlue,
                          barWidth: 3,
                          dotData: FlDotData(show: false),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildElectionStatusBreakdown() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Election Status Breakdown',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            AspectRatio(
              aspectRatio: 1.7,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('elections')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  Map<String, int> statusCount = {
                    'upcoming': 0,
                    'active': 0,
                    'completed': 0
                  };

                  for (var doc in snapshot.data!.docs) {
                    final status = doc['status'] as String;
                    statusCount[status] = (statusCount[status] ?? 0) + 1;
                  }

                  return PieChart(
                    PieChartData(
                      sectionsSpace: 0,
                      centerSpaceRadius: 40,
                      sections: [
                        PieChartSectionData(
                          color: Colors.blue,
                          value: statusCount['upcoming']!.toDouble(),
                          title: 'Upcoming',
                          radius: 50,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          color: Colors.green,
                          value: statusCount['active']!.toDouble(),
                          title: 'Active',
                          radius: 50,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          color: Colors.orange,
                          value: statusCount['completed']!.toDouble(),
                          title: 'Completed',
                          radius: 50,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityList() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('votes')
                  .orderBy('timestamp', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final vote = snapshot.data!.docs[index];
                    final timestamp = (vote['timestamp'] as Timestamp).toDate();

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('elections')
                          .doc(vote['electionId'])
                          .get(),
                      builder: (context, electionSnapshot) {
                        if (!electionSnapshot.hasData) {
                          return const ListTile(
                            title: Text('Loading...'),
                          );
                        }

                        final election = electionSnapshot.data!;
                        return ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.how_to_vote),
                          ),
                          title: Text('Vote cast in ${election['title']}'),
                          subtitle: Text(
                            DateFormat('MMM d, y HH:mm').format(timestamp),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _processVoteData(List<QueryDocumentSnapshot> docs) {
    Map<String, int> votesByDay = {};

    for (var doc in docs) {
      final timestamp = (doc['timestamp'] as Timestamp).toDate();
      final day = DateFormat('MM/dd').format(timestamp);
      votesByDay[day] = (votesByDay[day] ?? 0) + 1;
    }

    List<FlSpot> spots = [];
    var sortedDays = votesByDay.keys.toList()..sort();

    for (var i = 0; i < sortedDays.length; i++) {
      spots.add(FlSpot(i.toDouble(), votesByDay[sortedDays[i]]!.toDouble()));
    }

    return spots;
  }
}