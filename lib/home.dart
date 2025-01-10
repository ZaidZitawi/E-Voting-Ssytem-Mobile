import 'package:flutter/material.dart';
import 'package:e_voting_system/CalendarPage.dart';
import 'package:e_voting_system/ClubElectionsPage.dart';
import 'package:e_voting_system/CustomBottomNavigationBar.dart';
import 'package:e_voting_system/CustomDrawer.dart';
import 'package:e_voting_system/ElectionDetailPage.dart';
import 'package:e_voting_system/NotificationsPage.dart';
import 'package:e_voting_system/ProfileUserPage.dart';
import 'package:e_voting_system/CandidatePostsPage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = <Widget>[
    const HomeContent(),
    const CalendarPage(),
    const NotificationsPage(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'E Voting System',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF347928),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.post_add_sharp),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CandidatePostsPage(),
                ),
              );
            },
          ),
        ],
      ),
      drawer: CustomDrawer(
        
        onItemTapped: _onItemTapped,
        onNavigateToFacebook: () {},
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  _HomeContentState createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final List<Map<String, dynamic>> _elections = [
    {
      'title': 'Student Council Elections',
      'icon': Icons.group,
      'color': const Color(0xFF347928), // Green
    },
    {
      'title': 'Club Elections',
      'icon': Icons.sports,
      'color': const Color(0xFF5E82FF), // Blue
    },
    {
      'title': 'College Representative Elections',
      'icon': Icons.school,
      'color': const Color(0xFFFCCD2A), // Yellow
    },
    {
      'title': 'Teaching Union Elections',
      'icon': Icons.how_to_vote,
      'color': const Color(0xFFE63946), // Red
    },
  ];

  List<Map<String, dynamic>> _filteredElections = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _filteredElections = _elections;
  }

  void _filterElections(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredElections = _elections;
      } else {
        _filteredElections = _elections
            .where((election) => election['title']
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _applyFilter(String filterType) {
    setState(() {
      switch (filterType) {
        case 'All':
          _filteredElections = _elections;
          break;
        case 'Department':
          _filteredElections = _elections
              .where((e) => e['title'].contains('Department'))
              .toList();
          break;
        case 'Faculty':
          _filteredElections =
              _elections.where((e) => e['title'].contains('Faculty')).toList();
          break;
        case 'Upcoming':
          _filteredElections =
              _elections.where((e) => e['title'].contains('Upcoming')).toList();
          break;
        case 'Active':
          _filteredElections =
              _elections.where((e) => e['title'].contains('Active')).toList();
          break;
        case 'Type':
          _filteredElections =
              _elections.where((e) => e['title'].contains('Type')).toList();
          break;
      }
    });
  }

 @override
Widget build(BuildContext context) {
  return Scaffold(
    body: CustomScrollView(
      slivers: [
        // ثابتة: Search Box + Filter Buttons
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(12.0), // حواف أصغر حول المحتوى
            child: Column(
              children: [
                // Search box
                TextField(
                  onChanged: _filterElections,
                  decoration: InputDecoration(
                    hintText: 'Search elections...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFFF0F4F8),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12), // حواف صغيرة داخل مربع النص
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24), // حواف دائرية أصغر
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12), // مسافة صغيرة بين مربع البحث والأزرار

                // Filter Buttons
                _buildFilterButtons(),
              ],
            ),
          ),
        ),

        // قابل للتمرير: GridView + ListView
        SliverList(
          delegate: SliverChildListDelegate(
            [
              const SizedBox(height: 12), // مسافة صغيرة بين الأقسام
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12), // حواف صغيرة للنص
                child: Text(
                  'Types of Elections',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),

              // Grid of election cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12), // حواف صغيرة للشبكة
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12, // مسافة صغيرة بين الأعمدة
                    mainAxisSpacing: 12, // مسافة صغيرة بين الصفوف
                    childAspectRatio: 4 / 3,
                  ),
                  itemCount: _filteredElections.length,
                  itemBuilder: (context, index) {
                    final election = _filteredElections[index];
                    return _buildElectionCard(
                      title: election['title'],
                      icon: election['icon'],
                      color: election['color'],
                      onTap: () {
                        if (election['title'] == 'Club Elections') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ClubElectionsPage(),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ElectionDetailPage(
                                electionTitle: election['title'],
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              // List of ongoing elections
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12), // حواف صغيرة للنص
                child: Text(
                  'Ongoing Elections',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12), // حواف صغيرة للقائمة
                child: ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: _elections.length,
                  itemBuilder: (context, index) {
                    final election = _elections[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4), // مسافة صغيرة بين البطاقات
                      child: ListTile(
                        leading: Icon(
                          election['icon'],
                          color: election['color'],
                        ),
                        title: Text(
                          election['title'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          if (election['title'] == 'Club Elections') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ClubElectionsPage(),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ElectionDetailPage(
                                  electionTitle: election['title'],
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}



  Widget _buildFilterButtons() {
  final filters = [
    {'label': 'All', 'filter': () => _applyFilter('All')},
    {'label': 'Department', 'filter': () => _applyFilter('Department')},
    {'label': 'Faculty', 'filter': () => _applyFilter('Faculty')},
    {'label': 'Upcoming', 'filter': () => _applyFilter('Upcoming')},
    {'label': 'Active', 'filter': () => _applyFilter('Active')},
    {'label': 'Type', 'filter': () => _applyFilter('Type')},
  ];

  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: filters.map((filter) {
        return Padding(
          padding: const EdgeInsets.only(right: 8), // Spacing between buttons
          child: ElevatedButton(
            onPressed: filter['filter'] as VoidCallback,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              backgroundColor: const Color.fromARGB(255, 133, 154, 229),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              filter['label'] as String,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }).toList(),
    ),
  );
}

  Widget _buildElectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.7),
              color.withOpacity(0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 16,
              spreadRadius: 4,
              offset: const Offset(4, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.9),
                ),
                child: Icon(
                  icon,
                  size: 48,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
