import 'package:flutter/material.dart';

class CandidatePostsPage extends StatefulWidget {
  const CandidatePostsPage({super.key});

  @override
  _CandidatePostsPageState createState() => _CandidatePostsPageState();
}

class _CandidatePostsPageState extends State<CandidatePostsPage> {
  final List<Map<String, dynamic>> posts = [
    {
      'name': 'John Doe',
      'image': 'assets/john_doe.jpg',
      'content': "Campaign Announcement: I'm running for Student Council President!",
      'likes': 0,
      'comments': [],
      'liked': false,
    },
    {
      'name': 'Jane Smith',
      'image': 'assets/jane_smith.jpg',
      'content': "My vision for the university includes improving student engagement.",
      'likes': 0,
      'comments': [],
      'liked': false,
    },
  ];

  void _likePost(int index) {
    setState(() {
      posts[index]['likes']++;
      posts[index]['liked'] = true;
    });
  }

  void _commentPost(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add a Comment'),
          content: TextField(
            onSubmitted: (value) {
              setState(() {
                posts[index]['comments'].add(value);
              });
              Navigator.pop(context);
            },
            decoration: const InputDecoration(hintText: 'Enter your comment'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Candidate Posts'),
        backgroundColor: const Color(0xFF347928),
      ),
      body: ListView.builder(
        itemCount: posts.length,
        itemBuilder: (context, index) {
          return _buildPostCard(posts[index], index);
        },
      ),
      backgroundColor: const Color(0xFFFFFBE6),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: AssetImage(post['image']!),
                  radius: 30,
                ),
                const SizedBox(width: 12),
                Text(
                  post['name']!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF347928),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              post['content']!,
              style: const TextStyle(color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () => _likePost(index),
                  icon: const Icon(Icons.thumb_up, color: Color(0xFF347928)),
                  label: Text(
                    '${post['likes']} Likes',
                    style: const TextStyle(color: Color(0xFF347928)),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _commentPost(index),
                  icon: const Icon(Icons.comment, color: Color(0xFFFCCD2A)),
                  label: Text(
                    '${post['comments'].length} Comments',
                    style: const TextStyle(color: Color(0xFFFCCD2A)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
