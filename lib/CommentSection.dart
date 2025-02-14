// CommentSection.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'CommentCard.dart';
import 'AllCommentsDialog.dart';
import 'package:e_voting_system/constants.dart' as Constants;

const BASE_URL = Constants.BASE_URL;

class CommentsSection extends StatefulWidget {
  final int postId;

  const CommentsSection({Key? key, required this.postId}) : super(key: key);

  @override
  _CommentsSectionState createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  List<dynamic> _comments = [];
  bool _loading = false;
  String? _error;

  // For adding a new comment
  final TextEditingController _commentController = TextEditingController();
  bool _submittingComment = false;

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // 1) Fetch comments from /comments/posts/{postId}/comments
  Future<void> _fetchComments() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = await _getToken();
      if (token == null) {
        setState(() {
          _error = "No auth token found. Please log in.";
          _loading = false;
        });
        return;
      }

      final Uri url = Uri.parse("$BASE_URL/comments/posts/${widget.postId}/comments");
      final response = await http.get(url, headers: {"Authorization": "Bearer $token"});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          setState(() {
            _comments = data;
          });
        } else {
          setState(() {
            _error = "Unexpected response format.";
          });
        }
      } else {
        setState(() {
          _error = "Error: ${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        _error = "$e";
    });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  // 2) Add a new comment
  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _submittingComment = true;
    });

    try {
      final token = await _getToken();
      final userId = await _getUserId();
      if (token == null || userId == null) {
        setState(() {
          _error = "Missing token or userId.";
          _submittingComment = false;
        });
        return;
      }

      // Build comment DTO
      final commentDTO = {
        "userId": int.parse(userId),
        "postId": widget.postId,
        "content": text,
      };

      final Uri url = Uri.parse("$BASE_URL/comments/add");
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(commentDTO),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // The backend presumably returns the newly created comment
        final createdComment = jsonDecode(response.body);

        setState(() {
          _comments.add(createdComment);
          _commentController.clear();
        });
      } else {
        setState(() {
          _error = "Error adding comment: ${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        _error = "$e";
      });
    } finally {
      setState(() {
        _submittingComment = false;
      });
    }
  }

  // Show modal with all comments
  void _showAllComments() {
    showDialog(
      context: context,
      builder: (_) => AllCommentsDialog(
        comments: _comments,
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("authToken");
  }

  Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("userId");
  }

  @override
  Widget build(BuildContext context) {
    // 1) error
    if (_error != null) {
      return Text("Error: $_error", style: const TextStyle(color: Colors.red));
    }

    // 2) loading
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show first 2 comments
    final visibleComments = _comments.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Visible comments
        for (var c in visibleComments)
          CommentCard(commentData: c),

        // If more than 2 comments, show "See all" button
        if (_comments.length > 2)
          TextButton(
            onPressed: _showAllComments,
            child: const Text("See all comments"),
          ),

        // Add new comment row
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  hintText: "Add a comment...",
                ),
              ),
            ),
            const SizedBox(width: 8),
            _submittingComment
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _addComment,
                    child: const Text("Add"),
                  ),
          ],
        ),
      ],
    );
  }
}
