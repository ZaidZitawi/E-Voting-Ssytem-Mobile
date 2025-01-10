import 'package:flutter/material.dart';
import 'ClubElectionDetailPage.dart';

class EngineeringClubsPage extends StatelessWidget {
  const EngineeringClubsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> clubs = [
      {'name': 'نادي علم الحاسوب', 'icon': Icons.computer},
      {'name': 'نادي الهندسة المعمارية والتخطيط الفراغي', 'icon': Icons.architecture},
      {'name': 'نادي الهندسة المدنية', 'icon': Icons.engineering},
      {'name': 'نادي الهندسة الميكانيكية والميكاترونكس', 'icon': Icons.settings},
      {'name': 'نادي الهندسة الكهربائية وهندسة الحاسوب', 'icon': Icons.electrical_services},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Engineering and Technology Clubs'),
        backgroundColor: const Color(0xFF347928), // Primary color
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: clubs.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF347928), // Primary green
                radius: 24,
                child: Icon(
                  clubs[index]['icon'] as IconData,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              title: Text(
                clubs[index]['name'] as String,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B1B1B), // Dark text
                ),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey,
                size: 16,
              ),
              onTap: () {
                // الانتقال إلى صفحة تفاصيل الانتخابات
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ClubElectionDetailPage(
                      clubName: clubs[index]['name'] as String,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
