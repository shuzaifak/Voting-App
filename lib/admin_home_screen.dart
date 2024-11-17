import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:voting_system/admin_results_screen.dart';
import 'package:voting_system/analytics_screen.dart';
import 'package:voting_system/login_screen.dart';
import 'package:voting_system/manage_user_screen.dart';

import 'constants.dart';
import 'manage_election_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({Key? key}) : super(key: key);

  @override
  _AdminHomeScreenState createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(color: Colors.white),  // Ensuring text color matches
        ),
        backgroundColor: AppColors.primaryBlue,
      ),
      drawer: _buildAdminDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeCard(),
              const SizedBox(height: 24),
              _buildStatsCards(),
              const SizedBox(height: 24),
              _buildQuickActionsGrid(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.how_to_vote),
            label: 'Elections',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Users',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.primaryBlue,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AdminHomeScreen()),
              );
              break;
            case 1:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ManageElectionsScreen()),
              );
              break;
            case 2:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ManageUsersScreen()),
              );
              break;
          }
        },
      ),
    );
  }

  Widget _buildAdminDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 30,
                  child: Icon(Icons.admin_panel_settings,
                      size: 30, color: AppColors.primaryBlue),
                ),
                SizedBox(height: 10),
                Text(
                  'Admin Panel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'admin@votingsystem.com',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.how_to_vote),
            title: const Text('Manage Elections'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageElectionsScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Manage Users'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageUsersScreen(),
                )
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Analytics'),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AnalyticsScreen(),
                  )
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text('Logout'),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  )
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
            const Text(
              'Welcome, Admin!',
              style: TextStyle(
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

  Widget _buildStatsCards() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('elections').snapshots(),
      builder: (context, electionSnapshot) {
        // Get active elections stream
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('elections')
              .where('status', isEqualTo: 'active')
              .snapshots(),
          builder: (context, activeElectionSnapshot) {
            // Get users stream
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, usersSnapshot) {
                // Get today's votes stream
                final now = DateTime.now();
                final startOfDay = DateTime(now.year, now.month, now.day);
                final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('votes')
                      .where('timestamp',
                      isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
                      .where('timestamp',
                      isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
                      .snapshots(),
                  builder: (context, votesSnapshot) {
                    // Calculate statistics
                    int totalElections = electionSnapshot.hasData
                        ? electionSnapshot.data!.docs.length
                        : 0;

                    int activeElections = activeElectionSnapshot.hasData
                        ? activeElectionSnapshot.data!.docs.length
                        : 0;

                    int totalUsers = usersSnapshot.hasData
                        ? usersSnapshot.data!.docs.length
                        : 0;

                    int todayVotes = votesSnapshot.hasData
                        ? votesSnapshot.data!.docs.length
                        : 0;

                    // Show loading indicator if any stream is still loading
                    if (!electionSnapshot.hasData ||
                        !activeElectionSnapshot.hasData ||
                        !usersSnapshot.hasData ||
                        !votesSnapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    // Show error if any stream has an error
                    if (electionSnapshot.hasError ||
                        activeElectionSnapshot.hasError ||
                        usersSnapshot.hasError ||
                        votesSnapshot.hasError) {
                      return const Center(
                        child: Text('Error loading statistics'),
                      );
                    }

                    return GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildStatCard(
                            'Total Elections',
                            totalElections.toString(),
                            Icons.how_to_vote
                        ),
                        _buildStatCard(
                            'Active Elections',
                            activeElections.toString(),
                            Icons.timeline
                        ),
                        _buildStatCard(
                            'Total Users',
                            totalUsers.toString(),
                            Icons.people
                        ),
                        _buildStatCard(
                            'Today\'s Votes',
                            todayVotes.toString(),
                            Icons.how_to_reg
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: AppColors.primaryBlue),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBlue,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildActionCard('Create Election', Icons.add_circle_outline, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageElectionsScreen(),
                ),
              );
            }),
            _buildActionCard('View Results', Icons.bar_chart, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>  AdminResultsScreen(),
                ),
              );
            }),
            _buildActionCard('Manage Users', Icons.people_outline, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>  const ManageUsersScreen(),
                ),
              );
            }),
            _buildActionCard('Analytics', Icons.analytics, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>  const AnalyticsScreen(),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: AppColors.primaryBlue),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
