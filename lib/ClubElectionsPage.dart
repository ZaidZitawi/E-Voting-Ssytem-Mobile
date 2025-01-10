import 'package:flutter/material.dart';

import 'ArtsClubsPage.dart';
import 'BusinessEconomyClubsPage.dart';
import 'EngineeringClubsPage .dart';
import 'PharmacyNursingClubsPage.dart';
import 'ScienceClubsPage.dart';

class ClubElectionsPage extends StatefulWidget {
  const ClubElectionsPage({super.key});

  @override
  _ClubElectionsPageState createState() => _ClubElectionsPageState();
}

class _ClubElectionsPageState extends State<ClubElectionsPage> {
  final List<Map<String, String>> colleges = [
    {'name': 'كلية الهندسة و التكنولوجيا', 'image': 'assets/Engineering and Technology.png'},
    {'name': 'كلية الفنون و الموسيقى و التصميم', 'image': 'assets/Arts.jpg'},
    {'name': 'كلية العلوم', 'image': 'assets/the sciences.jpg'},
    {'name': 'كلية الحقوق و الإدارة العامة', 'image': 'assets/Rights and Administration.jpg'},
    {'name': 'كلية الصيدلة و التمريض', 'image': 'assets/Pharmacy and Nursing.jpg'},
    {'name': 'كلية التربية', 'image': 'assets/Education.jpg'},
    {'name': 'كلية الأعمال و الاقتصاد', 'image': 'assets/Business and Economy.jpg'},
    {'name': 'كلية الآداب', 'image': 'assets/Literature.jpg'},
  ];

  List<Map<String, String>> _filteredColleges = [];

  @override
  void initState() {
    super.initState();
    _filteredColleges = colleges;
  }

  void _filterColleges(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredColleges = colleges;
      } else {
        _filteredColleges = colleges
            .where((college) =>
                college['name']!.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Club Elections',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF347928), // Primary color
        centerTitle: true,
        elevation: 2,
      ),
      body: Container(
        color: const Color(0xFFF7F6E7), // Light beige background
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search box
            TextField(
              onChanged: _filterColleges,
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFC0EBA6), // Secondary color
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                hintStyle: const TextStyle(color: Colors.black54),
              ),
            ),
            const SizedBox(height: 16),

            // Display filtered colleges
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 3 / 3.5,
                ),
                itemCount: _filteredColleges.length,
                itemBuilder: (context, index) {
                  return _buildCollegeCard(
                    _filteredColleges[index]['name']!,
                    _filteredColleges[index]['image']!,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

    Widget _buildCollegeCard(String collegeName, String imagePath) {
  return GestureDetector(
    onTap: () {
      if (collegeName == 'كلية الهندسة و التكنولوجيا') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const EngineeringClubsPage(),
          ),
        );
      } else if (collegeName == 'كلية الصيدلة و التمريض') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PharmacyNursingClubsPage(),
          ),
        );
      } else if (collegeName == 'كلية العلوم') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ScienceClubsPage(),
          ),
        );
      } else if (collegeName == 'كلية الأعمال و الاقتصاد') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const BusinessEconomyClubsPage(),
          ),
        );
      } else if (collegeName == 'كلية الآداب') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ArtsClubsPage(),
          ),
        );
      } else {
        print('$collegeName tapped');
      }
    },
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20), // Rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(3, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background image
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              imagePath,
              height: double.infinity,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          // Green overlay
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF347928).withOpacity(0.7), // Primary green
                  Colors.transparent,
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),

          // Text overlay
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                collegeName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // Text color for better contrast
                  shadows: [
                    Shadow(
                      color: Colors.black,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}


}
