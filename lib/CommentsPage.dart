// CommentsPage.dart
import 'package:flutter/material.dart';
import 'CommentSection.dart';

class CommentsPage extends StatelessWidget {
  final int postId;

  const CommentsPage({Key? key, required this.postId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Comments")),
      // Use SingleChildScrollView to allow content to scroll if needed
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: CommentsSection(postId: postId),
      ),
    );
  }
}
