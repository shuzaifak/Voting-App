import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:voting_system/constants.dart';

import 'admin_home_screen.dart';

class ManageElectionsScreen extends StatefulWidget {
  const ManageElectionsScreen({Key? key}) : super(key: key);

  @override
  _ManageElectionsScreenState createState() => _ManageElectionsScreenState();
}

class _ManageElectionsScreenState extends State<ManageElectionsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createElection() async {
    if (_formKey.currentState!.validate() && _startDate != null && _endDate != null) {
      try {
        final election = await FirebaseFirestore.instance.collection('elections').add({
          'title': _titleController.text,
          'description': _descriptionController.text,
          'startDate': Timestamp.fromDate(_startDate!),
          'endDate': Timestamp.fromDate(_endDate!),
          'status': 'upcoming',
          'totalVotes': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (!mounted) return;
        Navigator.pop(context);
        _showSnackBar('Election created successfully');

        // Navigate to add candidates screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ManageCandidatesScreen(electionId: election.id),
          ),
        );
      } catch (e) {
        _showSnackBar('Error creating election: Please try again');
        print('Create election error: $e');
      }
    }
  }

  Future<void> _updateElection(String electionId, String currentStatus) async {
    if (_formKey.currentState!.validate() && _startDate != null && _endDate != null) {
      try {
        await FirebaseFirestore.instance
            .collection('elections')
            .doc(electionId)
            .update({
          'title': _titleController.text,
          'description': _descriptionController.text,
          'startDate': Timestamp.fromDate(_startDate!),
          'endDate': Timestamp.fromDate(_endDate!),
          'status': currentStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Clear controllers after successful update
        _titleController.clear();
        _descriptionController.clear();
        _startDate = null;
        _endDate = null;

        if (!mounted) return;
        Navigator.pop(context);
        _showSnackBar('Election updated successfully');
      } catch (e) {
        _showSnackBar('Error updating election: $e');
      }
    }
  }
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _selectDate(bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Stream<QuerySnapshot> _getElectionsStream() {
    return FirebaseFirestore.instance
        .collection('elections')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((error) {
      print('Firestore error: $error');
      _showSnackBar('Error loading elections: Please try again');
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
            MaterialPageRoute(builder: (context) => const AdminHomeScreen()),
          ),
        ),
        title: const Text(
          'Manage Elections',
          style: TextStyle(color: Colors.white),  // Ensuring text color matches
        ),
        backgroundColor: AppColors.primaryBlue,  // Keeping the same background color
        elevation: 4,  // Adding elevation to match the card style
        iconTheme: const IconThemeData(color: Colors.white),  // Ensuring all icons match
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateElectionDialog(),
        backgroundColor: AppColors.primaryBlue,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getElectionsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading elections',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {});  // Refresh the stream
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final elections = snapshot.data?.docs ?? [];

          if (elections.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.ballot_outlined,
                    size: 60,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No elections found',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Click the + button to create a new election',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: elections.length,
            itemBuilder: (context, index) {
              final election = elections[index].data() as Map<String, dynamic>;
              final electionId = elections[index].id;
              return _buildElectionCard(election, electionId);
            },
          );
        },
      ),
    );
  }

  Widget _buildElectionCard(Map<String, dynamic> election, String electionId) {
    final endDate = (election['endDate'] as Timestamp).toDate();
    final status = election['status'] ?? 'upcoming';

    return StreamBuilder<AggregateQuerySnapshot>(
      stream: Stream.periodic(const Duration(seconds: 5))
          .asyncMap((_) async {
        // Get vote count
        final voteCount = await FirebaseFirestore.instance
            .collection('votes')
            .where('electionId', isEqualTo: electionId)
            .count()
            .get();

        // Update election document with new total votes
        await FirebaseFirestore.instance
            .collection('elections')
            .doc(electionId)
            .update({
          'totalVotes': voteCount.count,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return voteCount;
      }),
      builder: (context, snapshot) {
        // Use stored value if stream is still loading
        final totalVotes = snapshot.hasData ? snapshot.data!.count : election['totalVotes'] ?? 0;

        return Card(
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              ListTile(
                title: Text(
                  election['title'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(election['description'] ?? 'No description'),
                trailing: _buildStatusChip(status),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'End Date: ${DateFormat('MMM d, y').format(endDate)}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Total Votes: $totalVotes',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.people),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ManageCandidatesScreen(
                                  electionId: electionId,
                                ),
                              ),
                            );
                          },
                          tooltip: 'Manage Candidates',
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showEditElectionDialog(election, electionId),
                          tooltip: 'Edit Election',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _showDeleteConfirmation(electionId),
                          tooltip: 'Delete Election',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'upcoming':
        color = Colors.blue;
        break;
      case 'active':
        color = Colors.green;
        break;
      case 'completed':
        color = Colors.grey;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(
        status.toUpperCase(),
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
    );
  }

  void _showCreateElectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Election'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Election Title'),
                  validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter a title' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter a description' : null,
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text(_startDate == null
                      ? 'Select Start Date'
                      : DateFormat('MMM d, y').format(_startDate!)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _selectDate(true),
                ),
                ListTile(
                  title: Text(_endDate == null
                      ? 'Select End Date'
                      : DateFormat('MMM d, y').format(_endDate!)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _selectDate(false),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _createElection,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmation(String electionId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Election'),
        content: const Text(
          'Are you sure you want to delete this election? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Delete election document
        await FirebaseFirestore.instance
            .collection('elections')
            .doc(electionId)
            .delete();

        // Delete associated candidates
        final candidatesSnapshot = await FirebaseFirestore.instance
            .collection('candidates')
            .where('electionId', isEqualTo: electionId)
            .get();

        for (var doc in candidatesSnapshot.docs) {
          await doc.reference.delete();
        }

        _showSnackBar('Election deleted successfully');
      } catch (e) {
        _showSnackBar('Error deleting election: $e');
      }
    }
  }
  void _showEditElectionDialog(Map<String, dynamic> election, String electionId) {
    // Pre-fill the controllers with existing data
    _titleController.text = election['title'];
    _descriptionController.text = election['description'] ?? '';
    _startDate = (election['startDate'] as Timestamp).toDate();
    _endDate = (election['endDate'] as Timestamp).toDate();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Election'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Election Title'),
                  validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter a title' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter a description' : null,
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text(
                    _startDate == null
                        ? 'Select Start Date'
                        : DateFormat('MMM d, y').format(_startDate!),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _selectDate(true),
                ),
                ListTile(
                  title: Text(
                    _endDate == null
                        ? 'Select End Date'
                        : DateFormat('MMM d, y').format(_endDate!),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _selectDate(false),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: election['status'] ?? 'upcoming',
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: ['upcoming', 'active', 'completed']
                      .map((status) => DropdownMenuItem(
                    value: status,
                    child: Text(status.toUpperCase()),
                  ))
                      .toList(),
                  onChanged: (value) {
                    election['status'] = value;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Clear controllers and close dialog
              _titleController.clear();
              _descriptionController.clear();
              _startDate = null;
              _endDate = null;
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _updateElection(electionId, election['status']),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

}

// Manage Candidates Screen
class ManageCandidatesScreen extends StatefulWidget {
  final String electionId;

  const ManageCandidatesScreen({
    Key? key,
    required this.electionId,
  }) : super(key: key);

  @override
  _ManageCandidatesScreenState createState() => _ManageCandidatesScreenState();
}

class _ManageCandidatesScreenState extends State<ManageCandidatesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _positionController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _positionController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _addCandidate() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance.collection('candidates').add({
          'electionId': widget.electionId,
          'name': _nameController.text,
          'position': _positionController.text,
          'description': _descriptionController.text,
          'voteCount': 0,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (!mounted) return;
        Navigator.pop(context);
        _showSnackBar('Candidate added successfully');
      } catch (e) {
        _showSnackBar('Error adding candidate: $e');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
            MaterialPageRoute(builder: (context) => const ManageElectionsScreen()),
          ),
        ),
        title: const Text(
          'Manage Candidates',
          style: TextStyle(color: Colors.white),  // Ensuring text color matches
        ),
        backgroundColor: AppColors.primaryBlue,  // Keeping the same background color
        elevation: 4,  // Adding elevation to match the card style
        iconTheme: const IconThemeData(color: Colors.white),  // Ensuring all icons match
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCandidateDialog,
        backgroundColor: AppColors.primaryBlue,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('candidates')
            .where('electionId', isEqualTo: widget.electionId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final candidates = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: candidates.length,
            itemBuilder: (context, index) {
              final candidate = candidates[index].data() as Map<String, dynamic>;
              final candidateId = candidates[index].id;
              return _buildCandidateCard(candidate, candidateId);
            },
          );
        },
      ),
    );
  }

  Widget _buildCandidateCard(Map<String, dynamic> candidate, String candidateId) {
    return StreamBuilder<AggregateQuerySnapshot>(
      stream: Stream.periodic(const Duration(seconds: 5))
          .asyncMap((_) async {
        // Get vote count
        final voteCount = await FirebaseFirestore.instance
            .collection('votes')
            .where('candidateId', isEqualTo: candidateId)
            .count()
            .get();

        // Update candidate document with new vote count
        await FirebaseFirestore.instance
            .collection('candidates')
            .doc(candidateId)
            .update({
          'voteCount': voteCount.count,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return voteCount;
      }),
      builder: (context, snapshot) {
        // Use stored value if stream is still loading
        final voteCount = snapshot.hasData ? snapshot.data!.count : candidate['voteCount'] ?? 0;

        return Card(
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
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
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            candidate['position'] ?? 'No position specified',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showEditCandidateDialog(candidate, candidateId),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteCandidate(candidateId),
                    ),
                  ],
                ),
                if (candidate['description'] != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    candidate['description'],
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.how_to_vote, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Votes: $voteCount',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddCandidateDialog() {
    _nameController.clear();
    _positionController.clear();
    _descriptionController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Candidate'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Candidate Name'),
                  validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter a name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _positionController,
                  decoration: const InputDecoration(labelText: 'Position'),
                  validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter a position' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter a description' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _addCandidate,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditCandidateDialog(Map<String, dynamic> candidate, String candidateId) {
    _nameController.text = candidate['name'];
    _positionController.text = candidate['position'] ?? '';
    _descriptionController.text = candidate['description'] ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Candidate'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Candidate Name'),
                  validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter a name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _positionController,
                  decoration: const InputDecoration(labelText: 'Position'),
                  validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter a position' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter a description' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _updateCandidate(candidateId),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateCandidate(String candidateId) async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance
            .collection('candidates')
            .doc(candidateId)
            .update({
          'name': _nameController.text,
          'position': _positionController.text,
          'description': _descriptionController.text,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (!mounted) return;
        Navigator.pop(context);
        _showSnackBar('Candidate updated successfully');
      } catch (e) {
        _showSnackBar('Error updating candidate: $e');
      }
    }
  }

  Future<void> _deleteCandidate(String candidateId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Candidate'),
        content: const Text(
          'Are you sure you want to delete this candidate? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('candidates')
            .doc(candidateId)
            .delete();
        _showSnackBar('Candidate deleted successfully');
      } catch (e) {
        _showSnackBar('Error deleting candidate: $e');
      }
    }
  }
}