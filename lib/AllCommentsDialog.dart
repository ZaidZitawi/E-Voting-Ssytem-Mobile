// AllCommentsDialog.dart
import 'package:flutter/material.dart';
import 'CommentCard.dart';

class AllCommentsDialog extends StatelessWidget {
  final List<dynamic> comments;
  final VoidCallback onClose;

  const AllCommentsDialog({Key? key, required this.comments, required this.onClose})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: double.maxFinite,
        height: 400,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("All Comments", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  final comment = comments[index];
                  return CommentCard(commentData: comment);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
