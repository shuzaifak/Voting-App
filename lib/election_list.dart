import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:voting_system/main.dart';
import 'package:voting_system/terms_and_conditions_screen.dart';
import 'HomeScreen.dart';
import 'election_detail_screen.dart';

class ElectionListScreen extends StatefulWidget {
  const ElectionListScreen({Key? key}) : super(key: key);

  @override
  _ElectionListScreenState createState() => _ElectionListScreenState();
}

class _ElectionListScreenState extends State<ElectionListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadElections();
  }

  Future<void> _loadElections() async {
    // Simulate loading delay
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _isLoading = false;
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
          'Elections',
          style: TextStyle(color: Colors.white),  // Ensuring text color matches
        ),
        backgroundColor: AppColors.primaryBlue,  // Keeping the same background color
        elevation: 4,  // Adding elevation to match the card style
        iconTheme: const IconThemeData(color: Colors.white),  // Ensuring all icons match
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchAndFilter(),
            _buildSecurityNotice(),
            Expanded(
              child: _isLoading ? _buildLoadingIndicator() : _buildElectionList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search elections...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All'),
                _buildFilterChip('Ongoing'),
                _buildFilterChip('Upcoming'),
                _buildFilterChip('Completed'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: _selectedFilter == label,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = selected ? label : 'All';
          });
        },
        backgroundColor: Colors.grey[200],
        selectedColor: AppColors.primaryBlue.withOpacity(0.2),
        labelStyle: TextStyle(
          color: _selectedFilter == label ? AppColors.primaryBlue : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildSecurityNotice() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
      ),
      child: Row(
        children: const [
          Icon(Icons.security, color: AppColors.primaryBlue),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'All election data is encrypted and secured using blockchain technology',
              style: TextStyle(
                color: AppColors.primaryBlue,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildElectionList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('elections')
          .orderBy('startDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingIndicator();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        var elections = snapshot.data!.docs;

        // Apply filters
        if (_selectedFilter != 'All') {
          elections = elections.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final endDate = (data['endDate'] as Timestamp).toDate();
            final startDate = (data['startDate'] as Timestamp).toDate();
            final now = DateTime.now();

            switch (_selectedFilter) {
              case 'Ongoing':
                return now.isAfter(startDate) && now.isBefore(endDate);
              case 'Upcoming':
                return now.isBefore(startDate);
              case 'Completed':
                return now.isAfter(endDate);
              default:
                return true;
            }
          }).toList();
        }

        // Apply search query
        if (_searchQuery.isNotEmpty) {
          elections = elections.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['title'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
                (data['description']?.toString().toLowerCase() ?? '').contains(_searchQuery.toLowerCase());
          }).toList();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: elections.length,
          itemBuilder: (context, index) {
            final doc = elections[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildElectionCard(doc.id, data);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.how_to_vote_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No elections found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try adjusting your search or filters'
                : 'Check back later for upcoming elections',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElectionCard(String electionId, Map<String, dynamic> election) {
    final startDate = (election['startDate'] as Timestamp).toDate();
    final endDate = (election['endDate'] as Timestamp).toDate();
    final now = DateTime.now();
    final isOngoing = now.isAfter(startDate) && now.isBefore(endDate);
    final isUpcoming = now.isBefore(startDate);

    void _showStatusDialog(String status) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Row(
              children: [
                Icon(
                  status == 'Upcoming' ? Icons.schedule : Icons.check_circle,
                  color: status == 'Upcoming' ? Colors.orange : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  status == 'Upcoming' ? 'Election Not Started' : 'Election Ended',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Text(
              status == 'Upcoming'
                  ? 'This election has not started yet. You can participate once it begins on ${DateFormat('MMM d, y').format(startDate)}.'
                  : 'This election has ended. The voting period was from ${DateFormat('MMM d, y').format(startDate)} to ${DateFormat('MMM d, y').format(endDate)}.',
              style: TextStyle(color: Colors.grey[700]),
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          if (isOngoing) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TermsAndConditionsScreen(
                  electionId: electionId,
                ),
              ),
            );
          } else {
            _showStatusDialog(isUpcoming ? 'Upcoming' : 'Completed');
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                  _buildStatusChip(isOngoing, isUpcoming),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                election['description'] ?? 'No description available',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDateInfo('Starts', startDate),
                  _buildDateInfo('Ends', endDate),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(bool isOngoing, bool isUpcoming) {
    String label;
    Color color;

    if (isOngoing) {
      label = 'Ongoing';
      color = Colors.green;
    } else if (isUpcoming) {
      label = 'Upcoming';
      color = Colors.orange;
    } else {
      label = 'Completed';
      color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDateInfo(String label, DateTime date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        Text(
          DateFormat('MMM d, y').format(date),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}