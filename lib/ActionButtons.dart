// ActionButtons.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Suppose you have these routes
import 'CommentsPage.dart'; // Where CommentsPage(...) is defined
import 'package:e_voting_system/constants.dart' as Constants;

/// Example constants
const BASE_URL = Constants.BASE_URL;

class ActionButtons extends StatefulWidget {
  final int postId;
  final bool likedByCurrentUser;
  final int likesCount;
  final int commentsCount;

  /// Called when we do an optimistic UI update for likes
  final void Function(int postId, bool newLiked, int newLikeCount) updatePostLikes;

  const ActionButtons({
    Key? key,
    required this.postId,
    required this.likedByCurrentUser,
    required this.likesCount,
    required this.commentsCount,
    required this.updatePostLikes,
  }) : super(key: key);

  @override
  _ActionButtonsState createState() => _ActionButtonsState();
}

class _ActionButtonsState extends State<ActionButtons> {
  late bool _liked;
  late int _likeCount;

  bool _likersDialogOpen = false;
  List<dynamic> _likers = [];

  @override
  void initState() {
    super.initState();
    _liked = widget.likedByCurrentUser;
    _likeCount = widget.likesCount;
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("authToken");
  }

  Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("userId");
  }

  // 1) Like/unlike logic
  Future<void> _handleLikeClick() async {
    final userId = await _getUserId();
    final token = await _getToken();
    if (userId == null || token == null) {
      debugPrint("User ID or auth token missing. Cannot like/unlike.");
      return;
    }

    // Optimistic update
    final newLiked = !_liked;
    final newLikeCount = newLiked ? _likeCount + 1 : _likeCount - 1;
    setState(() {
      _liked = newLiked;
      _likeCount = newLikeCount;
    });
    widget.updatePostLikes(widget.postId, newLiked, newLikeCount);

    try {
      final headers = {"Authorization": "Bearer $token"};
      final uri = Uri.parse("$BASE_URL/likes/posts/${widget.postId}?userId=$userId");

      if (newLiked) {
        // POST to like
        final resp = await http.post(uri, headers: headers);
        if (resp.statusCode >= 400) {
          throw Exception("Error liking: ${resp.body}");
        }
      } else {
        // DELETE to unlike
        final resp = await http.delete(uri, headers: headers);
        if (resp.statusCode >= 400) {
          throw Exception("Error unliking: ${resp.body}");
        }
      }
    } catch (e) {
      debugPrint("Error updating like status: $e");
      // revert if fails
      setState(() {
        _liked = widget.likedByCurrentUser;
        _likeCount = widget.likesCount;
      });
      widget.updatePostLikes(widget.postId, widget.likedByCurrentUser, widget.likesCount);
    }
  }

  // 2) Navigate to CommentsPage
  void _handleCommentClick() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CommentsPage(postId: widget.postId)),
    );
  }

  // 3) Show who liked this post
  Future<void> _handleLikeCountClick() async {
    final token = await _getToken();
    if (token == null) {
      debugPrint("Missing auth token for fetching likers.");
      return;
    }
    final uri = Uri.parse("$BASE_URL/likes/posts/${widget.postId}/likers");
    try {
      final resp = await http.get(uri, headers: {"Authorization": "Bearer $token"});
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        setState(() {
          _likers = data is List ? data : [];
          _likersDialogOpen = true;
        });
      } else {
        debugPrint("Error fetching likers: ${resp.body}");
      }
    } catch (e) {
      debugPrint("Error fetching likers: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row of "Like" and "Comment"
        Row(
          children: [
            ElevatedButton(
              onPressed: _handleLikeClick,
              child: Text(_liked ? "Unlike 👎" : "Like 👍"),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _handleCommentClick,
              child: Text("💬 ${widget.commentsCount} Comments"),
            ),
          ],
        ),
        const SizedBox(height: 4),

        // The like count is clickable to show who liked
        GestureDetector(
          onTap: _handleLikeCountClick,
          child: Text(
            "$_likeCount ${_likeCount == 1 ? 'Like' : 'Likes'}",
            style: const TextStyle(
              decoration: TextDecoration.underline,
              color: Colors.blue,
            ),
          ),
        ),

        // If open, show the list of likers in a small dialog
        if (_likersDialogOpen)
          LikesDialog(
            likers: _likers,
            onClose: () => setState(() => _likersDialogOpen = false),
          ),
      ],
    );
  }
}

// ----------------------------------------------------------------------
// LikesDialog: shows who liked this post
// ----------------------------------------------------------------------
class LikesDialog extends StatelessWidget {
  final List<dynamic> likers;
  final VoidCallback onClose;

  const LikesDialog({
    Key? key,
    required this.likers,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 300,
        height: 400,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Who Liked This Post",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // The list of likers
            Expanded(
              child: likers.isEmpty
                  ? const Center(child: Text("No one liked this post yet."))
                  : ListView.builder(
                      itemCount: likers.length,
                      itemBuilder: (context, index) {
                        final user = likers[index];
                        final displayName =
                            user["name"] ?? user["username"] ?? "Unknown";
                        return ListTile(
                          leading: const Icon(Icons.person),
                          title: Text(displayName),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
