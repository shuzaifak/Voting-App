import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:voting_system/help_support_screen.dart';
import 'package:voting_system/login_screen.dart';
import 'package:voting_system/main.dart';
import 'package:voting_system/profile_screen.dart';
import 'package:voting_system/results_screen.dart';

import 'election_detail_screen.dart';
import 'election_list.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  String username = '';
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (user != null) {
      DocumentSnapshot userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      setState(() {
        username = userData['username'];
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ElectionListScreen()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ResultsScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Home',
          style: TextStyle(color: Colors.white),  // Ensuring text color matches
        ),
        backgroundColor: AppColors.primaryBlue,
      ),
      drawer: _buildDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeCard(),
              const SizedBox(height: 24),
              _buildSecurityStatusCard(),
              const SizedBox(height: 24),
              _buildCurrentElectionsCard(),
              const SizedBox(height: 24),
              _buildQuickActionsGrid(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.how_to_vote),
            label: 'Vote',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Results',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.primaryBlue,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(username),
            accountEmail: Text(user?.email ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                username.isNotEmpty ? username[0].toUpperCase() : '',
                style: const TextStyle(fontSize: 24.0, color: AppColors.primaryBlue),
              ),
            ),
            decoration: const BoxDecoration(color: AppColors.primaryBlue),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.how_to_vote),
            title: const Text('Voting'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ElectionListScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('Results'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ResultsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Help & Support'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) =>const HelpSupportScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text('Logout'),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back, $username!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last login: ${DateFormat('MMM d, y HH:mm').format(DateTime.now())}',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityStatusCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Security Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.security, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Encryption: Active',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentElectionsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Current Elections',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ElectionListScreen(),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.list_alt,
                    size: 20,
                    color: AppColors.primaryBlue,
                  ),
                  label: const Text(
                    'View All',
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('elections')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Something went wrong'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                // Filter for ongoing elections
                final now = DateTime.now();
                final ongoingElections = snapshot.data?.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final startDate = (data['startDate'] as Timestamp).toDate();
                  final endDate = (data['endDate'] as Timestamp).toDate();
                  return now.isAfter(startDate) && now.isBefore(endDate);
                }).toList();

                if (ongoingElections == null || ongoingElections.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Icon(
                          Icons.how_to_vote_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No ongoing Elections',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ElectionListScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.list_alt),
                          label: const Text('View Elections List'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryBlue,
                            side: const BorderSide(color: AppColors.primaryBlue),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: ongoingElections.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final endDate = (data['endDate'] as Timestamp).toDate();
                    final daysRemaining = endDate.difference(now).inDays;

                    return ListTile(
                      title: Text(data['title']),
                      subtitle: Text('Ends in $daysRemaining days'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ElectionDetailsScreen(
                              electionId: doc.id,
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildActionCard(Icons.how_to_vote, 'Cast Vote', () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) =>const ElectionListScreen()),
          );
        }),
        _buildActionCard(Icons.bar_chart, 'View Results', () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ResultsScreen()),
          );
        }),
        _buildActionCard(Icons.person, 'My Profile', () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) =>const ProfileScreen()),
          );
        }),
        _buildActionCard(Icons.help_outline, 'Help & Support', () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) =>const HelpSupportScreen()),
          );
        }),
      ],
    );
  }

  Widget _buildActionCard(IconData icon, String title, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: AppColors.primaryBlue),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}