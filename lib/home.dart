// home.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:e_voting_system/constants.dart' as Constants;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';
import 'CalendarPage.dart';
import 'NotificationsPage.dart';
import 'ProfileUserPage.dart';
import 'CandidatePostsPage.dart';
import 'CustomBottomNavigationBar.dart';
import 'CustomDrawer.dart';
import 'ElectionDetailPage.dart';

const BASE_URL = Constants.BASE_URL;

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = <Widget>[
    HomeContent(),
    CalendarPage(),
    NotificationsPage(),
    ProfilePage(),
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
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.post_add_sharp),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CandidatePostsPage(),
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
  HomeContent({Key? key}) : super(key: key);

  @override
  _HomeContentState createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  List<dynamic> _featuredElections = [];
  bool _isLoadingFeatured = false;
  String? _featuredError;

  TextEditingController _searchController = TextEditingController();
  List<dynamic> _allElections = [];
  List<dynamic> _filteredElections = [];
  bool _isLoadingAll = false;
  String? _listError;

  bool _upcoming = false;
  bool _active = false;
  int? _faculty;
  int? _department;
  int? _type;

  List<Map<String, dynamic>> _faculties = [];
  List<Map<String, dynamic>> _departments = [];
  bool _isLoadingFaculties = false;
  bool _isLoadingDepartments = false;
  String? _errorFaculties;
  String? _errorDepartments;

  @override
  void initState() {
    super.initState();
    _fetchFeaturedElections();
    _fetchAllElections();
  }

  Future<void> _fetchFeaturedElections() async {
    setState(() {
      _isLoadingFeatured = true;
      _featuredError = null;
    });

    try {
      final String? token = await _getToken();
      if (token == null) throw Exception("No auth token found.");

      final response = await http.get(
        Uri.parse("$BASE_URL/elections/featured"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _featuredElections = data is List ? data : [];
        });
      } else {
        setState(() {
          _featuredError = "Error: ${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        _featuredError = "$e";
      });
    } finally {
      setState(() {
        _isLoadingFeatured = false;
      });
    }
  }

  Future<void> _fetchAllElections() async {
    setState(() {
      _isLoadingAll = true;
      _listError = null;
    });

    try {
      final String? token = await _getToken();
      if (token == null) throw Exception("No auth token found.");

      final response = await http.get(
        Uri.parse("$BASE_URL/elections/filter?page=0&size=100"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final content = parsed["content"];
        setState(() {
          _allElections = content is List ? content : [];
        });
        _applyFilters();
      } else {
        setState(() {
          _listError = "Error: ${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        _listError = "$e";
      });
    } finally {
      setState(() {
        _isLoadingAll = false;
      });
    }
  }

  Future<void> _fetchFaculties() async {
  setState(() {
    _isLoadingFaculties = true;
    _errorFaculties = null;
  });

  final String? token = await _getToken();
  if (token == null) {
    setState(() {
      _errorFaculties = "No authentication token found. Please log in.";
      _isLoadingFaculties = false;
    });
    return;
  }

  final Uri url = Uri.parse("$BASE_URL/faculty-and-department/faculties");

  try {
    final response = await http.get(
      url,
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        _faculties = data.map((f) {
          return {
            "id": f["facultyId"],
            "name": f["facultyName"],
          };
        }).toList();
      });
    } else {
      setState(() {
        _errorFaculties = "Error: ${response.body}";
      });
    }
  } catch (e) {
    setState(() {
      _errorFaculties = "Exception: $e";
    });
  } finally {
    setState(() {
      _isLoadingFaculties = false;
    });
  }
}


  Future<void> _fetchDepartments(int facultyId) async {
  setState(() {
    _isLoadingDepartments = true;
    _errorDepartments = null;
  });

  final String? token = await _getToken();
  if (token == null) {
    setState(() {
      _errorDepartments = "No authentication token found. Please log in.";
      _isLoadingDepartments = false;
    });
    return;
  }

  final Uri url = Uri.parse("$BASE_URL/faculty-and-department/faculties/$facultyId/departments");

  try {
    final response = await http.get(
      url,
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        _departments = data.map((d) {
          return {
            "id": d["departmentId"],
            "name": d["departmentName"],
          };
        }).toList();
      });
    } else {
      setState(() {
        _errorDepartments = "Error: ${response.body}";
      });
    }
  } catch (e) {
    setState(() {
      _errorDepartments = "Exception: $e";
    });
  } finally {
    setState(() {
      _isLoadingDepartments = false;
    });
  }
}

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("authToken");
  }

  void _onSearchChanged(String query) {
    _applyFilters();
  }

  void _applyFilters() {
  final query = _searchController.text.trim().toLowerCase();

  List<dynamic> filtered = _allElections.where((e) {
    final title = (e["title"] ?? "").toString().toLowerCase();
    final matchesSearch = query.isEmpty || title.contains(query);

    bool isUpcomingLocal = false;
    if (e["startDatetime"] != null) {
      try {
        final DateTime dt = DateTime.parse(e["startDatetime"]);
        if (dt.isAfter(DateTime.now())) {
          isUpcomingLocal = true;
        }
      } catch (_) {
        isUpcomingLocal = false;
      }
    }

    final bool isActive = e["isActive"] == true;

    final bool matchesUpcoming = !_upcoming || isUpcomingLocal;
    final bool matchesActive = !_active || isActive;

    final facultyId = e["faculty"] != null ? e["faculty"]["facultyId"] : null;
    final departmentId = e["department"] != null ? e["department"]["departmentId"] : null;
    final electionType = e["type"];

    final bool matchesFaculty = _faculty == null || _faculty == facultyId;
    final bool matchesDept = _department == null || _department == departmentId;
    final bool matchesType = _type == null || _type == electionType;

    return matchesSearch
        && matchesUpcoming
        && matchesActive
        && matchesFaculty
        && matchesDept
        && matchesType;
  }).toList();

  setState(() {
    _filteredElections = filtered;
  });
}


  void _clearFilters() {
    setState(() {
      _searchController.text = "";
      _upcoming = false;
      _active = false;
      _faculty = null;
      _department = null;
      _type = null;
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: <Widget>[
                  _buildFeaturedSection(),

                  const SizedBox(height: 12),
                  _buildSearchBox(),
                  const SizedBox(height: 12),
                  _buildFilterButtons(),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _buildElectionList(),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildFeaturedSection() {
    if (_isLoadingFeatured) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_featuredError != null) {
      return Text("Error: $_featuredError", style: const TextStyle(color: Colors.red));
    }
    if (_featuredElections.isEmpty) {
      return const Text("No featured elections available at the moment.");
    }
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _featuredElections.length,
        itemBuilder: (context, index) {
          final election = _featuredElections[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ElectionDetailsPage(
                  electionId: election["electionId"],
                )),
              );
            },
            child: Container(
              width: 220,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.grey)],
              ),
              child: Column(
                children: <Widget>[
                  election["imageUrl"] != null
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: Image.network(
                            "$BASE_URL/uploads/${election["imageUrl"]}",
                            height: 100,
                            width: 220,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Container(
                          height: 100,
                          color: Colors.grey.shade300,
                          alignment: Alignment.center,
                          child: const Text("No image"),
                        ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      election["title"] ?? "Untitled",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBox() {
    return TextField(
      controller: _searchController,
      onChanged: _onSearchChanged,
      decoration: InputDecoration(
        hintText: 'Search elections...',
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFFF0F4F8),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }


  Widget _buildFilterButtons() {

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          _buildFilterButton("All", onPressed: _clearFilters),
          const SizedBox(width: 8),
          _buildFilterButton("Upcoming", onPressed: () {
            setState(() {
              _upcoming = true;
              _active = false;
            });
            _applyFilters();
          }),
          const SizedBox(width: 8),
          _buildFilterButton("Active", onPressed: () {
            setState(() {
              _upcoming = false;
              _active = true;
            });
            _applyFilters();
          }),
          const SizedBox(width: 8),
          _buildFilterButton("Pick Faculty/Dept", onPressed: _showFacultyDeptDialog),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, {required VoidCallback onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        backgroundColor: const Color.fromARGB(255, 133, 154, 229),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
    );
  }

 Future<void> _showFacultyDeptDialog() async {
  if (_faculties.isEmpty) {
    await _fetchFaculties();
  }

  String? localFaculty = _faculty != null ? _faculty.toString() : null;
  String? localDepartment = _department != null ? _department.toString() : null;

  await showDialog(
    context: context,
    builder: (BuildContext ctx) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) {
          return AlertDialog(
            title: const Text("Select Faculty & Department"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: "Faculty"),
                  value: localFaculty,
                  items: _faculties.map((f) {
                    return DropdownMenuItem<String>(
                      value: f["id"].toString(),
                      child: Text(f["name"]),
                    );
                  }).toList(),
                  onChanged: (value) async {
                    setDialogState(() {
                      localFaculty = value;
                      localDepartment = null;
                      _departments.clear();
                    });

                    if (value != null) {
                      final facultyId = int.tryParse(value);
                      if (facultyId != null) {
                        await _fetchDepartments(facultyId);
                        setDialogState(() {});
                      }
                    }
                  },
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: "Department"),
                  value: localDepartment,
                  items: _departments.map((d) {
                    return DropdownMenuItem<String>(
                      value: d["id"].toString(),
                      child: Text(d["name"]),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      localDepartment = value;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _faculty = localFaculty != null ? int.tryParse(localFaculty!) : null;
                    _department = localDepartment != null ? int.tryParse(localDepartment!) : null;
                  });

                  _applyFilters();

                  Navigator.pop(context);
                },
                child: const Text("Save"),
              ),
            ],
          );
        },
      );
    },
  );
}

  Widget _buildElectionList() {
    if (_isLoadingAll) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_listError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text("Error: $_listError", style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _fetchAllElections,
            child: const Text("Retry"),
          ),
        ],
      );
    }
    if (_filteredElections.isEmpty) {
      return const Text("No elections match your criteria.");
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'All Elections',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: _filteredElections.length,
          itemBuilder: (context, index) {
            final election = _filteredElections[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: const Icon(Icons.how_to_vote, color: Color(0xFF347928)),
                title: Text(
                  election["title"] ?? "No title",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(election["description"] ?? "No description."),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ElectionDetailsPage(
                        electionId: election["electionId"],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class GlassContainer extends StatelessWidget {
  final double blur;
  final double opacity;
  final Widget child;

  GlassContainer({
    Key? key,
    required this.blur,
    required this.opacity,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
            borderRadius: BorderRadius.circular(30),
          ),
          child: child,
        ),
      ),
    );
  }
}
