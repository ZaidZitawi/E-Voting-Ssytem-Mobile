// SocialPage.dart
import 'package:e_voting_system/ActionButtons.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:e_voting_system/constants.dart' as Constants;


/// Adjust for your actual backend
const BASE_URL = Constants.BASE_URL;

class SocialPage extends StatefulWidget {
  const SocialPage({Key? key}) : super(key: key);

  @override
  _SocialPageState createState() => _SocialPageState();
}

class _SocialPageState extends State<SocialPage> {
  final List<dynamic> _posts = [];
  int _page = 0;
  bool _loading = false;
  bool _hasMore = true;
  String? _error;

  /// Current filters from the PostsFilter widget
  Map<String, dynamic> _filters = {};

  @override
  void initState() {
    super.initState();
    // Initially fetch page=0, no filters
    _fetchPosts(page: 0, filters: {}, replace: true);
  }

  // ----------------------------
  // 1) Fetch posts from filterPosts
  // ----------------------------
  Future<void> _fetchPosts({
    required int page,
    required Map<String, dynamic> filters,
    bool replace = false,
  }) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
      if (replace) {
        _posts.clear();
        _page = page;
        _hasMore = true;
      }
    });

    try {
      final token = await _getToken();
      final userId = await _getUserId();
      if (token == null || userId == null) {
        throw Exception("No auth token or userId found. Please log in.");
      }

      // Build query parameters
      final query = {
        "page": page.toString(),
        "userId": userId,
      };
      // Merge the filters into the query
      filters.forEach((key, value) {
        if (value != null && value.toString().isNotEmpty) {
          query[key] = value.toString();
        }
      });

      final uri = Uri.parse("$BASE_URL/posts/filterPosts").replace(queryParameters: query);
      final response = await http.get(uri, headers: {"Authorization": "Bearer $token"});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data["content"] ?? [];
        final lastPage = data["last"] ?? true;

        final newPosts = content as List<dynamic>;
        // Deduplicate if needed
        final existingIds = _posts.map((p) => p["postId"]).toSet();
        final unique = newPosts.where((p) => !existingIds.contains(p["postId"]));

        setState(() {
          _posts.addAll(unique);
          _hasMore = !lastPage;
        });
      } else {
        throw Exception("Failed: ${response.body}");
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  // Load more (pagination)
  Future<void> _loadMore() async {
    if (!_hasMore || _loading) return;
    final nextPage = _page + 1;
    await _fetchPosts(page: nextPage, filters: _filters);
    // If successful, increment _page
    if (!_loading && _error == null) {
      setState(() {
        _page = nextPage;
      });
    }
  }

  // Like callback for optimistic UI
  void _updatePostLikes(int postId, bool liked, int likeCount) {
    setState(() {
      for (var post in _posts) {
        if (post["postId"] == postId) {
          post["likedByCurrentUser"] = liked;
          post["likeCount"] = likeCount;
          break;
        }
      }
    });
  }

  // Filter callbacks
  void _onApplyFilters(Map<String, dynamic> newFilters) {
    setState(() {
      _filters = newFilters;
    });
    _fetchPosts(page: 0, filters: newFilters, replace: true);
  }

  void _onClearFilters() {
    setState(() {
      _filters = {};
    });
    _fetchPosts(page: 0, filters: {}, replace: true);
  }

  // Helper: read token, userId from SharedPreferences
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Social Page"),
      ),
      body: Column(
        children: [
          // The advanced filter bar
          Container(
            padding: const EdgeInsets.all(8),
            child: PostsFilter(
              onApplyFilters: _onApplyFilters,
              onClearFilters: _onClearFilters,
            ),
          ),

          // Show error if any
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("Error: $_error", style: const TextStyle(color: Colors.red)),
            ),

          // The post list
          Expanded(
            child: ListView.builder(
              itemCount: _posts.length + 1, // +1 for load more or "no more"
              itemBuilder: (context, index) {
                if (index < _posts.length) {
                  final post = _posts[index];
                  return PostWidget(
                    post: post,
                    // Comments callback could open a CommentsPage, etc.
                    onCommentClick: () {
                      // e.g. Navigator.push(... CommentsPage(...))
                    },
                    updatePostLikes: _updatePostLikes,
                  );
                } else {
                  // The last item => handle load more
                  if (_hasMore && !_loading) {
                    _loadMore();
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  } else if (_loading) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  } else {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: Text("No more posts.")),
                    );
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------------
// PostsFilter: to replicate your React filters: faculty, dateRange, sortBy, keyword
// Also fetches faculties from /faculty-and-department/faculties
// ------------------------------------------------------------------------
class PostsFilter extends StatefulWidget {
  final Function(Map<String, dynamic>) onApplyFilters;
  final VoidCallback onClearFilters;

  const PostsFilter({
    Key? key,
    required this.onApplyFilters,
    required this.onClearFilters,
  }) : super(key: key);

  @override
  _PostsFilterState createState() => _PostsFilterState();
}

class _PostsFilterState extends State<PostsFilter> {
  String _faculty = "";
  String _dateRange = "";
  String _sortBy = "recent";
  String _keyword = "";

  List<dynamic> _faculties = [];
  bool _loadingFaculties = false;
  String? _facError;

  @override
  void initState() {
    super.initState();
    _fetchFaculties();
  }

  Future<void> _fetchFaculties() async {
    setState(() {
      _loadingFaculties = true;
      _facError = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("authToken");
      if (token == null) {
        throw Exception("No auth token found for fetching faculties.");
      }
      final uri = Uri.parse("$BASE_URL/faculty-and-department/faculties");
      final response = await http.get(uri, headers: {"Authorization": "Bearer $token"});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          setState(() {
            _faculties = data;
          });
        }
      } else {
        throw Exception("Faculties error: ${response.body}");
      }
    } catch (e) {
      setState(() {
        _facError = e.toString();
    });
    } finally {
      setState(() {
        _loadingFaculties = false;
      });
    }
  }

  void _applyFilters() {
    final filters = <String, String>{};

    if (_faculty.isNotEmpty) {
      filters["faculty"] = _faculty;
    }
    if (_dateRange.isNotEmpty) {
      filters["dateRange"] = _dateRange;
    }
    if (_sortBy.isNotEmpty) {
      filters["sortBy"] = _sortBy;
    }
    if (_keyword.isNotEmpty) {
      filters["keyword"] = _keyword;
    }

    widget.onApplyFilters(filters);
  }

  void _clearFilters() {
    setState(() {
      _faculty = "";
      _dateRange = "";
      _sortBy = "recent";
      _keyword = "";
    });
    widget.onClearFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            if (_facError != null)
              Text("Faculties Error: $_facError", style: const TextStyle(color: Colors.red)),

            // 1) Faculty
            Row(
              children: [
                const Text("Faculty: "),
                const SizedBox(width: 8),
                _loadingFaculties
                    ? const CircularProgressIndicator()
                    : Expanded(
                        child: DropdownButton<String>(
                          value: _faculty.isEmpty ? null : _faculty,
                          hint: const Text("All Faculties"),
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem(child: Text("All Faculties"), value: ""),
                            ..._faculties.map((f) {
                              final facId = f["facultyId"].toString();
                              final facName = f["facultyName"] ?? "Unknown";
                              return DropdownMenuItem(
                                value: facId,
                                child: Text(facName),
                              );
                            }),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _faculty = val ?? "";
                            });
                          },
                        ),
                      ),
              ],
            ),
            const SizedBox(height: 8),

            // 2) Date Range
            Row(
              children: [
                const Text("Date Range: "),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    value: _dateRange.isEmpty ? null : _dateRange,
                    hint: const Text("All Time"),
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(child: Text("All Time"), value: ""),
                      DropdownMenuItem(child: Text("Last 24 Hours"), value: "24h"),
                      DropdownMenuItem(child: Text("This Week"), value: "week"),
                      DropdownMenuItem(child: Text("This Month"), value: "month"),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _dateRange = val ?? "";
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 3) Sort By
            Row(
              children: [
                const Text("Sort By: "),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    value: _sortBy,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(child: Text("Most Recent"), value: "recent"),
                      DropdownMenuItem(child: Text("Most Liked"), value: "likes"),
                      DropdownMenuItem(child: Text("Most Commented"), value: "comments"),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _sortBy = val ?? "recent";
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 4) Keyword
            Row(
              children: [
                const Text("Keyword: "),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(hintText: "Search posts..."),
                    onChanged: (val) => _keyword = val,
                    controller: TextEditingController(text: _keyword),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: _applyFilters,
                  child: const Text("Apply Filters"),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: _clearFilters,
                  child: const Text("Clear"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// PostWidget: shows post content + ActionButtons
// We'll embed ActionButtons for like, comment, show-likers, etc.
// ----------------------------------------------------------------------
class PostWidget extends StatefulWidget {
  final Map<String, dynamic> post;
  final void Function(int postId, bool liked, int likeCount) updatePostLikes;
  final VoidCallback onCommentClick;

  const PostWidget({
    Key? key,
    required this.post,
    required this.updatePostLikes,
    required this.onCommentClick,
  }) : super(key: key);

  @override
  _PostWidgetState createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  @override
  Widget build(BuildContext context) {
    final p = widget.post;
    final postId = p["postId"] as int;
    final content = p["content"] ?? "";
    final likedByCurrentUser = p["likedByCurrentUser"] == true;
    final likeCount = p["likeCount"] ?? 0;
    final commentCount = p["commentCount"] ?? 0;
    final authorName = p["candidate"]?["name"] ?? p["party"]?["name"] ?? "Unknown";

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author
            Text(authorName, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),

            // Content
            Text(content),
            const SizedBox(height: 8),

            // ActionButtons for Like, Comment, Likers
            ActionButtons(
              postId: postId,
              likedByCurrentUser: likedByCurrentUser,
              likesCount: likeCount,
              commentsCount: commentCount,
              updatePostLikes: widget.updatePostLikes,
            ),
          ],
        ),
      ),
    );
  }
}
