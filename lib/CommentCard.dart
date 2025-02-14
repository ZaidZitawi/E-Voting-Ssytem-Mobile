// CommentCard.dart
import 'package:flutter/material.dart';
import 'package:e_voting_system/constants.dart' as Constants;

const BASE_URL = Constants.BASE_URL;
class CommentCard extends StatelessWidget {
  final Map<String, dynamic> commentData;

  const CommentCard({Key? key, required this.commentData}) : super(key: key);

  // A simple relative time approach
  String _timeAgo(String timestamp) {
    if (timestamp.isEmpty) return "Unknown time";
    final date = DateTime.tryParse(timestamp);
    if (date == null) return "Unknown time";

    final now = DateTime.now();
    final seconds = now.difference(date).inSeconds;

    if (seconds < 60) {
      return "${seconds}s ago";
    } else if (seconds < 3600) {
      return "${seconds ~/ 60}m ago";
    } else if (seconds < 86400) {
      return "${seconds ~/ 3600}h ago";
    } else if (seconds < 2592000) {
      return "${seconds ~/ 86400}d ago";
    } else if (seconds < 31536000) {
      return "${seconds ~/ 2592000}mo ago";
    } else {
      return "${seconds ~/ 31536000}y ago";
    }
  }

  @override
  Widget build(BuildContext context) {
    // Example structure:
    // {
    //   "commentId": 123,
    //   "content": "...",
    //   "createdAt": "...",
    //   "userName": "...",
    //   "userProfilePicture": "path/to/pic.jpg"
    // }
    final userName = commentData["userName"] ?? "Unknown";
    final userImage = commentData["userProfilePicture"] ?? "";
    final content = commentData["content"] ?? "";
    final createdAt = commentData["createdAt"] ?? "";

    final String imageUrl = userImage.isNotEmpty
        ? "$BASE_URL/uploads/$userImage"
        : ""; // fallback if needed

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User image
          if (imageUrl.isNotEmpty) 
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                imageUrl,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.white70),
            ),
          const SizedBox(width: 8),

          // Comment details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: user name + time
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(_timeAgo(createdAt), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                // Comment content
                Text(content, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
