// ElectionDetailPage.dart
import 'package:e_voting_system/CommentSection.dart';
import 'package:e_voting_system/CommentsPage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:e_voting_system/constants.dart' as Constants;

const BASE_URL = Constants.BASE_URL;

/// A placeholder default image if election imageUrl is null
const DEFAULT_ELECTION_IMAGE = "https://via.placeholder.com/600x300";

class ElectionDetailsPage extends StatefulWidget {
  final int electionId;
  const ElectionDetailsPage({Key? key, required this.electionId}) : super(key: key);

  @override
  _ElectionDetailsPageState createState() => _ElectionDetailsPageState();
}

class _ElectionDetailsPageState extends State<ElectionDetailsPage> {
  bool _loading = true;
  String? _error;

  // Main election data from "GET /elections/{id}"
  Map<String, dynamic>? _election;

  // Parties from "GET /parties/election/{id}"
  List<dynamic> _parties = [];

  // Check user eligibility + if user has voted
  bool _eligibilityChecked = false;
  bool _userEligible = false;
  bool _userHasVoted = false;
  bool _voteChecked = false;
  String? _transactionHash;  // If user already voted, store the TX
  String? _characterName;    // e.g. "anonymous"

  // Some data for faculty/department
  String? _facultyName;
  String? _departmentName;

  // "Blockchain" total votes & parties with votes
  int _blockchainTotalVotes = 0;
  List<Map<String, dynamic>> _partiesWithVotes = [];

  // For re-fetching blockchain data every 30s
  Timer? _blockchainTimer;

  // Whether we show the vote dialog
  bool _showVoteDialog = false;

  @override
  void initState() {
    super.initState();
    _fetchEverything();
  }

  @override
  void dispose() {
    // Cancel any timers if running
    _blockchainTimer?.cancel();
    super.dispose();
  }

  // ---------------------------------------------
  // MASTER FETCH: fetch election + parties + checks
  // ---------------------------------------------
  Future<void> _fetchEverything() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _fetchElection();
      await _fetchParties();
      await _checkEligibility();
      await _checkUserVote();
      await _fetchFacultyDepartmentNames();

      // Once we have election + parties, fetch "blockchain" votes
      if (_election != null && _parties.isNotEmpty) {
        await _fetchBlockchainData();

        // Also poll it every 30 sec (like React does)
        _blockchainTimer = Timer.periodic(
          const Duration(seconds: 30),
          (timer) => _fetchBlockchainData(),
        );
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

  // ---------------------------------------------
  // 1) FETCH ELECTION /elections/{id}
  // ---------------------------------------------
  Future<void> _fetchElection() async {
    final token = await _getToken();
    if (token == null) throw Exception("No auth token found. Please log in.");

    final Uri url = Uri.parse("$BASE_URL/elections/${widget.electionId}");
    final response = await http.get(url, headers: {"Authorization": "Bearer $token"});

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _election = data;
      });
    } else {
      throw Exception("Error fetching election: ${response.body}");
    }
  }

  // ---------------------------------------------
  // 2) FETCH PARTIES  /parties/election/{id}
  // ---------------------------------------------
  Future<void> _fetchParties() async {
    final token = await _getToken();
    if (token == null) throw Exception("No auth token found.");

    final Uri url = Uri.parse("$BASE_URL/parties/election/${widget.electionId}");
    final response = await http.get(url, headers: {"Authorization": "Bearer $token"});

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _parties = data is List ? data : [];
      });
    } else {
      throw Exception("Error fetching parties: ${response.body}");
    }
  }

  // ---------------------------------------------
  // 3) CHECK USER ELIGIBILITY 
  // /eligibility/elections/{electionId}/check
  // returns { "eligible": true/false }
  // ---------------------------------------------
  Future<void> _checkEligibility() async {
    setState(() {
      _eligibilityChecked = false;
    });

    final token = await _getToken();
    if (token == null) {
      // Without token, can't check
      _eligibilityChecked = true;
      return;
    }

    final Uri url = Uri.parse("$BASE_URL/eligibility/elections/${widget.electionId}/check");
    try {
      final response = await http.get(url, headers: {"Authorization": "Bearer $token"});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _userEligible = data["eligible"] == true;
        });
      }
    } catch (_) {}
    setState(() {
      _eligibilityChecked = true;
    });
  }

  // ---------------------------------------------
  // 4) CHECK IF USER HAS ALREADY VOTED
  // /votes/election/{electionId}/myVote
  // ---------------------------------------------
  Future<void> _checkUserVote() async {
    setState(() {
      _voteChecked = false;
    });

    final token = await _getToken();
    if (token == null) {
      // Without token, can't check
      _voteChecked = true;
      return;
    }

    final Uri url = Uri.parse("$BASE_URL/votes/election/${widget.electionId}/myVote");
    try {
      final response = await http.get(url, headers: {"Authorization": "Bearer $token"});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["status"] == "no_vote") {
          setState(() {
            _userHasVoted = false;
          });
        } else {
          setState(() {
            _userHasVoted = true;
            _transactionHash = data["transactionHash"];
            _characterName = data["characterName"] ?? "Unknown";
          });
        }
      }
    } catch (_) {}
    setState(() {
      _voteChecked = true;
    });
  }

  // ---------------------------------------------
  // 5) FETCH FACULTY & DEPARTMENT NAMES 
  // if your election has facultyId, departmentId
  // /faculty-and-department/faculties/{facultyId}
  // /faculty-and-department/departments/{departmentId}
  // ---------------------------------------------
  Future<void> _fetchFacultyDepartmentNames() async {
    if (_election == null) return;

    final token = await _getToken();
    if (token == null) return;

    final facultyId = _election!["facultyId"];
    final departmentId = _election!["departmentId"];

    if (facultyId != null) {
      final Uri url = Uri.parse("$BASE_URL/faculty-and-department/faculties/$facultyId");
      try {
        final response = await http.get(url, headers: {"Authorization": "Bearer $token"});
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          setState(() {
            _facultyName = data["facultyName"];
          });
        }
      } catch (_) {}
    }

    if (departmentId != null) {
      final Uri url2 = Uri.parse("$BASE_URL/faculty-and-department/departments/$departmentId");
      try {
        final response = await http.get(url2, headers: {"Authorization": "Bearer $token"});
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          setState(() {
            _departmentName = data["departmentName"];
          });
        }
      } catch (_) {}
    }
  }

  // ---------------------------------------------
  // 6) FETCH "BLOCKCHAIN" DATA 
  // We'll do a placeholder approach, or replicate your Infura logic 
  // for totalVotes, parties' votes, etc.
  // ---------------------------------------------
  Future<void> _fetchBlockchainData() async {
    // In React, you used ethers.js. 
    // For Flutter, you’d typically use web3dart or a dedicated API.
    // For now, let's do a mock approach:

    // We'll assume total = 0 for demonstration, and each party gets random votes
    final total = 0; 
    final updatedParties = <Map<String, dynamic>>[];

    for (var p in _parties) {
      final votes = (p["randomVotes"] ?? 0) + 5; // mock for UI
      updatedParties.add({
        ...p,
        "votes": votes,
      });
    }

    // Sort by descending votes
    updatedParties.sort((a, b) => (b["votes"] as int).compareTo(a["votes"] as int));

    setState(() {
      _blockchainTotalVotes = total;
      _partiesWithVotes = updatedParties.map((x) => Map<String, dynamic>.from(x)).toList();
    });
  }

  // ---------------------------------------------
  // getToken from SharedPreferences
  // ---------------------------------------------
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("authToken");
  }

  // ---------------------------------------------
  // BUILD UI
  // ---------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Election Details")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Election Details")),
        body: Center(child: Text("Error: $_error", style: const TextStyle(color: Colors.red))),
      );
    }
    if (_election == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Election Details")),
        body: const Center(child: Text("Election not found.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_election!["title"] ?? "Election Details"),
        backgroundColor: const Color(0xFF347928),
        elevation: 2,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // Coverage Hero
                _buildCoverageHero(),

                const SizedBox(height: 20),

                // PARTIES & CANDIDATES
                _buildSectionTitle("Parties & Candidates"),
                _buildPartiesSection(),

                // LEADERBOARD
                _buildSectionTitle("Leadership Board"),
                _buildLeaderboardSection(),

                // POSTS
                _buildSectionTitle("Posts Feed"),
                _buildPostsSection(),

                const SizedBox(height: 40),
              ],
            ),
          ),

          // VOTE DIALOG
          if (_showVoteDialog)
            VoteDialog(
              electionId: widget.electionId,
              parties: _parties,
              onClose: _closeVoteDialog,
              onVoteCast: _handleVoteCast,
            ),
        ],
      ),
    );
  }

  /// A nice heading for each section
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 10),
      child: Row(
        children: [
          Container(width: 4, height: 20, color: Colors.green),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          )
        ],
      ),
    );
  }

  // ---------------------------------------------
  // Coverage Hero (top portion)
  // ---------------------------------------------
  Widget _buildCoverageHero() {
    final imageUrl = _election!["imageUrl"];
    final background = (imageUrl != null) 
      ? "$BASE_URL/uploads/$imageUrl"
      : DEFAULT_ELECTION_IMAGE;

    return Container(
      height: 280,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
      ),
      child: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.network(
              background,
              fit: BoxFit.cover,
            ),
          ),
          // Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black87, Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
          ),
          // Content
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _buildHeroContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _election!["title"] ?? "Untitled",
          style: const TextStyle(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _election!["description"] ?? "",
          style: const TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                "${_formatDateTime(_election!["startDatetime"])} - ${_formatDateTime(_election!["endDatetime"])}",
                style: const TextStyle(color: Colors.white70),
              ),
            ),
            Text(
              _getElectionType(_election!["typeId"]),
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (_facultyName != null) ...[
              const Icon(Icons.account_balance, color: Colors.white70, size: 16),
              const SizedBox(width: 4),
              Text(_facultyName!, style: const TextStyle(color: Colors.white70)),
              const SizedBox(width: 12),
            ],
            if (_departmentName != null) ...[
              const Icon(Icons.account_tree_sharp, color: Colors.white70, size: 16),
              const SizedBox(width: 4),
              Text(_departmentName!, style: const TextStyle(color: Colors.white70)),
            ],
          ],
        ),
        const SizedBox(height: 12),

        // Voting Section
        _buildVotingSection(),
      ],
    );
  }

  // Voting logic 
  Widget _buildVotingSection() {
    final bool isActive = _election?["isActive"] == true;

    if (!_eligibilityChecked || !_voteChecked) {
      return const Text(
        "Checking eligibility...",
        style: TextStyle(color: Colors.white),
      );
    }

    if (!isActive) {
      return const Text(
        "Voting Closed",
        style: TextStyle(color: Colors.white),
      );
    }

    if (_userHasVoted) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "You have already voted as ${_characterName ?? "anonymous"}.",
              style: const TextStyle(color: Colors.white),
            ),
            if (_transactionHash != null) ...[
              const SizedBox(height: 4),
              Text(
                "Transaction Hash: $_transactionHash",
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ],
        ),
      );
    } else if (!_userEligible) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          "You are not eligible to vote.",
          style: TextStyle(color: Colors.white),
        ),
      );
    } else {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: _openVoteDialog,
        child: const Text("Vote Now"),
      );
    }
  }

  // ---------------------------------------------
  // PARTIES & CANDIDATES
  // ---------------------------------------------
  Widget _buildPartiesSection() {
    if (_parties.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text("No parties registered for this election."),
      );
    }
    return ListView.builder(
      itemCount: _parties.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final p = _parties[index];
        return PartyCard(party: p);
      },
    );
  }

  // ---------------------------------------------
  // LEADERBOARD
  // ---------------------------------------------
  Widget _buildLeaderboardSection() {
    if (_partiesWithVotes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text("No ranking available yet."),
      );
    }

    final topParty = _partiesWithVotes.first;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        children: [
          // Top Party Card
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  "Top Party: ${topParty["name"] ?? "Unnamed"}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text("Votes: ${topParty["votes"] ?? 0}"),
              ],
            ),
          ),

          // Ranking List
          ListView.builder(
            itemCount: _partiesWithVotes.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final item = _partiesWithVotes[index];
              final rank = index + 1;
              return Card(
                color: Colors.grey.shade100,
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: Text("#$rank"),
                  title: Text(item["name"] ?? "Unknown"),
                  trailing: Text("${item["votes"]} votes"),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------
  // POSTS FEED
  // ---------------------------------------------
  Widget _buildPostsSection() {
    return Container(
      width: double.infinity,
      color: Colors.grey.shade100,
      padding: const EdgeInsets.all(16),
      child: PostsSection(electionId: widget.electionId),
    );
  }

  // ---------------------------------------------
  // VOTE DIALOG
  // ---------------------------------------------
  void _openVoteDialog() => setState(() => _showVoteDialog = true);
  void _closeVoteDialog() => setState(() => _showVoteDialog = false);

  // Called when the user successfully casts a vote
  void _handleVoteCast(Map<String, dynamic> voteData) {
    setState(() {
      _userHasVoted = true;
      _transactionHash = voteData["transactionHash"];
      _characterName = voteData["characterName"];
    });
  }

  // Utility to format datetime strings from server
  String _formatDateTime(dynamic dt) {
    if (dt == null) return "";
    try {
      final DateTime dateTime = DateTime.parse(dt.toString());
      return "${dateTime.toLocal()}".split(".")[0]; // Or format as you like
    } catch (_) {
      return dt.toString();
    }
  }

  // Utility to get election type name
  String _getElectionType(dynamic typeId) {
    if (typeId == 1) return "University Election";
    if (typeId == 2) return "Faculty Election";
    return "Department Election";
  }
}

// ----------------------------------------------------------------------
// PARTIES & CANDIDATES WIDGETS
// ----------------------------------------------------------------------
class PartyCard extends StatefulWidget {
  final Map<String, dynamic> party;
  const PartyCard({Key? key, required this.party}) : super(key: key);

  @override
  _PartyCardState createState() => _PartyCardState();
}

class _PartyCardState extends State<PartyCard> {
  bool _expanded = false;
  List<dynamic> _candidates = [];
  bool _loadingCandidates = false;

  Future<void> _fetchCandidatesForParty(int partyId) async {
    setState(() {
      _loadingCandidates = true;
    });

    final token = await _getToken();
    if (token == null) {
      setState(() {
        _loadingCandidates = false;
      });
      return;
    }

    final Uri url = Uri.parse("$BASE_URL/candidates/party/$partyId");
    try {
      final response = await http.get(url, headers: {"Authorization": "Bearer $token"});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _candidates = data is List ? data : [];
        });
      }
    } catch (_) {}
    setState(() {
      _loadingCandidates = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.party;
    final partyTitle = p["name"] ?? "Unnamed Party";
    final imageUrl = p["imageUrl"];
    final fullImage = (imageUrl != null) ? "$BASE_URL/uploads/$imageUrl" : null;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          ListTile(
            leading: fullImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(fullImage, width: 50, height: 50, fit: BoxFit.cover),
                  )
                : Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.flag, color: Colors.white70),
                  ),
            title: Text(partyTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(p["bio"] ?? "No description provided."),
            trailing: IconButton(
              icon: Icon(_expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
              onPressed: () async {
                setState(() {
                  _expanded = !_expanded;
                });
                if (_expanded) {
                  final id = p["partyId"] ?? p["id"];
                  if (id != null) {
                    await _fetchCandidatesForParty(id);
                  }
                }
              },
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _loadingCandidates
                  ? const Center(child: CircularProgressIndicator())
                  : _candidates.isEmpty
                      ? const Text("No candidates for this party.", style: TextStyle(color: Colors.grey))
                      : Column(
                          children: _candidates.map((c) {
                            final cName = c["candidateName"] ?? "Unnamed Candidate";
                            final photo = c["profilePicture"];
                            final fullPhoto = (photo != null) ? "$BASE_URL/uploads/$photo" : null;
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                leading: (fullPhoto != null)
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.network(fullPhoto, width: 40, height: 40, fit: BoxFit.cover),
                                      )
                                    : const Icon(Icons.person),
                                title: Text(cName),
                                subtitle: Text("Candidate ID: ${c["candidateId"]}"),
                              ),
                            );
                          }).toList(),
                        ),
            ),
        ],
      ),
    );
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("authToken");
  }
}

// ----------------------------------------------------------------------
// POSTS SECTION
// ----------------------------------------------------------------------
class PostsSection extends StatefulWidget {
  final int electionId;
  const PostsSection({Key? key, required this.electionId}) : super(key: key);

  @override
  _PostsSectionState createState() => _PostsSectionState();
}

class _PostsSectionState extends State<PostsSection> {
  bool _loadingPosts = false;
  String? _postsError;
  List<dynamic> _posts = [];

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
  setState(() {
    _loadingPosts = true;
    _postsError = null;
  });

  // 1) Get token & userId from SharedPreferences
  final token = await _getToken();
  final userId = await _getUserId();

  if (token == null) {
    setState(() {
      _postsError = "No auth token found. Please log in.";
      _loadingPosts = false;
    });
    return;
  }
  if (userId == null || userId.isEmpty) {
    setState(() {
      _postsError = "No userId found in preferences. Please re-login.";
      _loadingPosts = false;
    });
    return;
  }

  try {
    // 2) Build the URL with query param userId
    final Uri url = Uri.parse("$BASE_URL/posts/election/${widget.electionId}/posts")
      .replace(queryParameters: {"userId": userId});

    // 3) Make the request
    final response = await http.get(
      url,
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _posts = (data is List) ? data : [];
      });
    } else {
      setState(() {
        _postsError = "Error: ${response.body}";
      });
    }
  } catch (e) {
    setState(() {
      _postsError = "$e";
    });
  } finally {
    setState(() {
      _loadingPosts = false;
    });
  }
}
Future<String?> _getUserId() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString("userId");
}


  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("authToken");
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingPosts) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_postsError != null) {
      return Text("Error: $_postsError", style: const TextStyle(color: Colors.red));
    }
    if (_posts.isEmpty) {
      return const Text("No posts for this election.");
    }

    return Column(
      children: _posts.map((p) => PostWidget(post: p)).toList(),
    );
  }
}

class PostWidget extends StatefulWidget {
  final Map<String, dynamic> post;
  final Function(int postId, bool newValue, int newLikeCount)? onLikeToggle;

  const PostWidget({
    Key? key,
    required this.post,
    this.onLikeToggle,
  }) : super(key: key);

  @override
  _PostWidgetState createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  late int likeCount;
  late bool likedByCurrentUser;

  @override
  void initState() {
    super.initState();
    likeCount = widget.post["likeCount"] ?? 0;
    likedByCurrentUser = widget.post["likedByCurrentUser"] == true;
  }

  // Placeholder method to toggle like on the server
  Future<void> _toggleLike() async {
    final postId = widget.post["postId"];
    final newValue = !likedByCurrentUser;
    int newLikeCount = likeCount;

    // Locally update
    setState(() {
      likedByCurrentUser = newValue;
      newLikeCount = newValue ? likeCount + 1 : likeCount - 1;
      likeCount = newLikeCount;
    });

    // Optionally, call an API like: POST /posts/{postId}/like or /unlike
    // If there's an error, revert state

    // If you provided an onLikeToggle callback in parent, call it
    if (widget.onLikeToggle != null) {
      widget.onLikeToggle!(postId, newValue, newLikeCount);
    }
  }

  // Example helper to format the date from "createdAt"
  String _formatDateTime(String? dateStr) {
    if (dateStr == null) return "";
    try {
      final dt = DateTime.parse(dateStr);
      return "${dt.toLocal()}".split(".")[0];
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final candidate = post["candidate"];
    final String candidateName = candidate?["name"] ?? "Unknown Candidate";
    final String candidateImage = candidate?["imageUrl"] ?? ""; // or local fallback
    final String content = post["content"] ?? "";
    final String? mediaUrl = post["mediaUrl"];
    final int commentCount = post["commentCount"] ?? 0;
    final String createdAt = _formatDateTime(post["createdAt"]);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row: Candidate image + Name + Timestamp
            Row(
              children: [
                // Candidate image
                if (candidateImage.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      "$BASE_URL/uploads/$candidateImage",
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
                // Candidate name & date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(candidateName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(createdAt, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Post content text
            Text(content, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 8),

      
            // Row of actions: Like button, comment count
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Like button with count
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        likedByCurrentUser ? Icons.favorite : Icons.favorite_border,
                        color: likedByCurrentUser ? Colors.red : Colors.grey,
                      ),
                      onPressed: _toggleLike,
                    ),
                    Text("$likeCount likes", style: const TextStyle(fontSize: 14)),
                  ],
                ),
                // Comments
                Row(
  children: [
    IconButton(
      icon: Icon(Icons.comment, color: Colors.grey.shade700),
      onPressed: () {
        // Navigate to the CommentsPage
        Navigator.push(
          context,
          MaterialPageRoute(
    builder: (_) => CommentsPage(postId: post["postId"]),
          ),
        );
      },
    ),
    const SizedBox(width: 4),
    Text("$commentCount comments", style: const TextStyle(fontSize: 14)),
  ],
),

              ],
            ),
          ],
        ),
      ),
    );
  }
}

class VoteDialog extends StatefulWidget {
  final int electionId;
  final List<dynamic> parties;
  final VoidCallback onClose;
  final Function(Map<String, dynamic>) onVoteCast;

  const VoteDialog({
    Key? key,
    required this.electionId,
    required this.parties,
    required this.onClose,
    required this.onVoteCast,
  }) : super(key: key);

  @override
  _VoteDialogState createState() => _VoteDialogState();
}

class _VoteDialogState extends State<VoteDialog> {
  int? _selectedPartyId;
  bool _submitting = false;
  String? _error;
  String? _txHash;

  // We'll add a two-step flow:
  // step = 0 -> disclaimers + party selection
  // step = 1 -> confirm screen
  // step = 2 -> success screen
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    // The entire overlay that dismisses if tapped outside
    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        color: Colors.black54,
        child: Center(
          // Prevent the underlying onTap from closing
          child: GestureDetector(
            onTap: () {},
            child: _buildDialogBox(),
          ),
        ),
      ),
    );
  }

  // The white box containing the steps
  Widget _buildDialogBox() {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: _buildDialogContent(),
    );
  }

  Widget _buildDialogContent() {
    // Step 2: After success, show success screen
    if (_txHash != null) {
      return _buildSuccessContent();
    }

    // If we're currently submitting
    if (_submitting) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          CircularProgressIndicator(),
          SizedBox(height: 8),
          Text("Submitting vote..."),
        ],
      );
    }

    // Step 0: disclaimers + radio list
    if (_currentStep == 0) {
      return _buildDisclaimersAndPartySelection();
    }

    // Step 1: confirmation screen
    return _buildConfirmation();
  }

  // -----------------------------------------------
  // Step 0: disclaimers + party selection
  // -----------------------------------------------
  Widget _buildDisclaimersAndPartySelection() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Cast Your Vote",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          // If there's an error
          if (_error != null) ...[
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
          ],

          // Disclaimers
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              "Disclaimer:\n"
              "• Your vote is final and cannot be changed.\n"
              "• Make sure you've selected the correct party.\n"
              "• Blockchain ensures transparency and security.",
              style: TextStyle(fontSize: 13),
            ),
          ),

          // Party selection
          Container(
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              itemCount: widget.parties.length,
              itemBuilder: (context, index) {
                final p = widget.parties[index];
                final pid = p["partyId"] ?? p["id"];
                final pname = p["name"] ?? "Unnamed Party";
                return RadioListTile<int>(
                  title: Text(pname),
                  value: pid,
                  groupValue: _selectedPartyId,
                  onChanged: (val) {
                    setState(() {
                      _selectedPartyId = val;
                    });
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(onPressed: widget.onClose, child: const Text("Cancel")),
              ElevatedButton(
                onPressed: _selectedPartyId == null
                    ? null
                    : () => setState(() => _currentStep = 1),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text("Next"),
              ),
            ],
          )
        ],
      ),
    );
  }

  // -----------------------------------------------
  // Step 1: Confirmation screen
  // -----------------------------------------------
  Widget _buildConfirmation() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          "Confirm Your Vote",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 16),
        // Show user the party they've selected
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              const Text("You're about to cast your vote for:", style: TextStyle(fontSize: 15)),
              const SizedBox(height: 8),
              _buildSelectedPartyWidget(),
              const SizedBox(height: 8),
              const Text(
                "Are you sure you want to proceed?",
                style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () => setState(() => _currentStep = 0),
              child: const Text("Back"),
            ),
            ElevatedButton(
              onPressed: _submitVote,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text("Confirm & Submit"),
            ),
          ],
        )
      ],
    );
  }

  // Builds a mini widget showing the party name / etc.
  Widget _buildSelectedPartyWidget() {
    final p = widget.parties.firstWhere(
      (x) => (x["partyId"] ?? x["id"]) == _selectedPartyId,
      orElse: () => null,
    );
    if (p == null) return const Text("Unknown Party");

    final pname = p["name"] ?? "Unnamed Party";
    final pdesc = p["bio"] ?? "";
    final imageUrl = p["imageUrl"];

    final fullImage = (imageUrl != null && imageUrl.isNotEmpty)
        ? "$BASE_URL/uploads/$imageUrl"
        : "";

    return Row(
      children: [
        if (fullImage.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(
              fullImage,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            ),
          )
        else
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.flag, color: Colors.white70),
          ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(pname, style: const TextStyle(fontWeight: FontWeight.bold)),
              if (pdesc.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(pdesc, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // -----------------------------------------------
  // Step 2: Success screen (once _txHash != null)
  // -----------------------------------------------
  Widget _buildSuccessContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 40),
        const SizedBox(height: 8),
        const Text("Vote Cast Successfully!", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text("Transaction: $_txHash", style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: widget.onClose,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text("Close"),
        ),
      ],
    );
  }

  // -----------------------------------------------
  // Submit Vote to server
  // -----------------------------------------------
  Future<void> _submitVote() async {
    // no party selected?
    if (_selectedPartyId == null) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    final token = await _getToken();
    if (token == null) {
      setState(() {
        _error = "No token found. Please log in.";
        _submitting = false;
      });
      return;
    }

    try {
      final uri = Uri.parse("$BASE_URL/votes/cast");
      final request = http.MultipartRequest("POST", uri);
      request.headers["Authorization"] = "Bearer $token";
      // Using the form fields from the original code
      request.fields["electionId"] = widget.electionId.toString();
      request.fields["partyId"] = _selectedPartyId.toString();
      request.fields["characterName"] = "anonymous";

      final streamed = await request.send();
      final resp = await http.Response.fromStream(streamed);

      if (resp.statusCode == 200) {
        final msg = resp.body;

        // parse transaction hash
        final match = RegExp(r"Transaction Hash:\s*(\S+)").firstMatch(msg);
        final hash = match != null ? match.group(1) : "No hash found";

        setState(() {
          _txHash = hash;
        });

        // Notify the parent
        widget.onVoteCast({"transactionHash": hash, "characterName": "anonymous"});
      } else {
        setState(() {
          _error = "Vote error: ${resp.body}";
        });
      }
    } catch (e) {
      setState(() {
        _error = "$e";
      });
    } finally {
      setState(() {
        _submitting = false;
      });
    }
  }

  // Helper to read the token from SharedPreferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("authToken");
  }
}
