import 'package:flutter/material.dart';

class BusinessEconomyClubsPage extends StatelessWidget {
  const BusinessEconomyClubsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> clubs = [
      {'name': 'نادي إدارة الأعمال', 'icon': Icons.business_center},
      {'name': 'نادي المحاسبة', 'icon': Icons.calculate},
      {'name': 'نادي العلوم المالية والمصرفية', 'icon': Icons.account_balance},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('نوادي كلية الأعمال والاقتصاد'),
        backgroundColor: const Color(0xFF347928), // Primary green
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
                  clubs[index]['icon'],
                  color: Colors.white,
                  size: 28,
                ),
              ),
              title: Text(
                clubs[index]['name'],
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
                print('${clubs[index]['name']} tapped');
              },
            ),
          );
        },
      ),
    );
  }
}
