import 'package:flutter/material.dart';

class CandidateProfilePage extends StatelessWidget {
  final String name;
  final String email;
  final String image;

  const CandidateProfilePage({
    super.key,
    required this.name,
    required this.email,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        backgroundColor: const Color(0xFF347928),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 80,
                backgroundImage: AssetImage(image),
              ),
              const SizedBox(height: 16),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF347928),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                email,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF4A4A4A),
                ),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),
              const Text(
                'Posts by Candidate',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF347928),
                ),
              ),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 3, // Replace with the actual number of posts
                itemBuilder: (context, index) {
                  return Card(
                    color: const Color(0xFFF0F4F8),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(
                        'Post ${index + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF347928),
                        ),
                      ),
                      subtitle: const Text(
                        'This is a description of the post.',
                        style: TextStyle(
                          color: Color(0xFF4A4A4A),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
