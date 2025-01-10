import 'package:flutter/material.dart';

class GroupProfilePage extends StatelessWidget {
  final String groupName;
  final String clubName;
  final String groupImage;
  final String groupBio;

  const GroupProfilePage({
    super.key,
    required this.groupName,
    required this.clubName,
    required this.groupImage,
    required this.groupBio,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> members = [
      {'name': 'John Smith', 'role': 'Leader', 'image': 'assets/member1.png'},
      {'name': 'Emily Davis', 'role': 'Member', 'image': 'assets/member2.png'},
      {'name': 'Michael Brown', 'role': 'Member', 'image': 'assets/member3.png'},
      {'name': 'Sophia Johnson', 'role': 'Member', 'image': 'assets/member4.png'},
      {'name': 'James Wilson', 'role': 'Member', 'image': 'assets/member5.png'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(groupName),
        backgroundColor: const Color(0xFF347928),
      ),
      body: Column(
        children: [
          // Header Section
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 180,
                decoration: const BoxDecoration(
                  color: Color(0xFF347928), // أخضر أساسي
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                    
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(80),
                        child: Image.asset(
                          groupImage,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        groupName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'النادي: $clubName',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFFFFF9C4), // أصفر فاتح
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Bio Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'About the Group:',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF347928),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  groupBio,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Members Section
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Members:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF347928),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: members.length,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemBuilder: (context, index) {
                final member = members[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 4,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: AssetImage(member['image']!),
                      radius: 30,
                    ),
                    title: Text(
                      member['name']!,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4CAF50), // أخضر أساسي
                      ),
                    ),
                    subtitle: Text(
                      member['role']!,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    trailing: member['role'] == 'Leader'
                        ? const Icon(
                            Icons.star,
                            color: Color(0xFFFFD700), // لون ذهبي للرئيس
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
