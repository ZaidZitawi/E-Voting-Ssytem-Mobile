// ProfileUserPage.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:e_voting_system/constants.dart' as Constants;
import 'dart:async';
import 'dart:convert';
import 'dart:io';

const BASE_URL = Constants.BASE_URL;

// Simple role mapping for demonstration
const roleMap = {
  1: "User", 
  2: "Candidate",
  4: "Party Manager",
};

class ProfilePage extends StatefulWidget {
  /// If [userId] is null, we fetch the current user's profile (/users/profile).
  /// If [userId] is provided, we fetch /users/profile/{userId}.
  final int? userId;

  const ProfilePage({Key? key, this.userId}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _user;        // The user data from backend
  String? _facultyName;               // Fetched from /faculty-and-department
  String? _departmentName;            // Fetched from /faculty-and-department
  int? _profileElectionId;            // For party manager or candidate
  bool _isOwnProfile = false;         // Determines if we can edit
  bool _loading = true;               // Are we loading data
  String? _error;                     // Error message if any

  // For editing modal
  bool _editModalOpen = false;   
  String _editName = "";
  String _editBio = "";
  File? _editProfilePictureFile;  
  String? _previewProfilePicture;  
  bool _updating = false;    

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  // ----------------------------------------------------------------
  // 1) Fetch user profile from /users/profile or /users/profile/{id}
  // ----------------------------------------------------------------
  Future<void> _fetchUserProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception("No auth token found. Please log in.");
      }

      String url = "$BASE_URL/users/profile";
      if (widget.userId != null) {
        url = "$BASE_URL/users/profile/${widget.userId}";
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        setState(() {
          _user = userData;
        });
        await _fetchFacultyAndDepartment(userData["facultyId"], userData["departmentId"]);

        // Determine if it's the same user
        final loggedInUserId = await _getLoggedInUserId();
        // If no userId was given or userId == loggedInUserId => own profile
        if (widget.userId == null || "${widget.userId}" == loggedInUserId) {
          _isOwnProfile = true;
          // If candidate or party manager, fetch election
          final roleId = userData["roleId"];
          final userIdField = userData["id"] ?? userData["userId"];
          if (roleId == 2) {
            await _fetchElectionIdForCandidate(userIdField);
          } else if (roleId == 4) {
            await _fetchElectionIdForPartyManager(userIdField);
          }
        } else {
          _isOwnProfile = false;
        }
      } else {
        throw Exception("Error fetching user profile: ${response.body}");
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

  // ----------------------------------------------------------------
  // 2) Fetch faculty & department names
  // ----------------------------------------------------------------
  Future<void> _fetchFacultyAndDepartment(dynamic facultyId, dynamic departmentId) async {
    final token = await _getToken();
    if (token == null) return;

    String fName = "N/A";
    String dName = "N/A";

    try {
      if (facultyId != null && "$facultyId" != "null") {
        final fUrl = "$BASE_URL/faculty-and-department/faculties/$facultyId";
        final fRes = await http.get(
          Uri.parse(fUrl),
          headers: {"Authorization": "Bearer $token"},
        );
        if (fRes.statusCode == 200) {
          final fData = jsonDecode(fRes.body);
          fName = fData["facultyName"] ?? "N/A";
        }
      }
      if (departmentId != null && "$departmentId" != "null") {
        final dUrl = "$BASE_URL/faculty-and-department/departments/$departmentId";
        final dRes = await http.get(
          Uri.parse(dUrl),
          headers: {"Authorization": "Bearer $token"},
        );
        if (dRes.statusCode == 200) {
          final dData = jsonDecode(dRes.body);
          dName = dData["departmentName"] ?? "N/A";
        }
      }
    } catch (_) {
      // ignore
    }

    setState(() {
      _facultyName = fName;
      _departmentName = dName;
    });
  }

  // ----------------------------------------------------------------
  // 3) For a Party Manager => fetch election id
  // ----------------------------------------------------------------
  Future<void> _fetchElectionIdForPartyManager(dynamic userId) async {
    try {
      final token = await _getToken();
      if (token == null) return;
      final url = "$BASE_URL/elections/user/$userId/electionId";
      final response = await http.get(Uri.parse(url), headers: {"Authorization": "Bearer $token"});
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        setState(() {
          _profileElectionId = jsonDecode(response.body);
        });
      }
    } catch (_) {
      // ignore
    }
  }

  // ----------------------------------------------------------------
  // 4) For a Candidate => fetch election id
  // ----------------------------------------------------------------
  Future<void> _fetchElectionIdForCandidate(dynamic userId) async {
    try {
      final token = await _getToken();
      if (token == null) return;
      final url = "$BASE_URL/elections/candidate/user/$userId/electionId";
      final response = await http.get(Uri.parse(url), headers: {"Authorization": "Bearer $token"});
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        setState(() {
          _profileElectionId = jsonDecode(response.body);
        });
      }
    } catch (_) {
      // ignore
    }
  }

  // ----------------------------------------------------------------
  // EDITING LOGIC
  // ----------------------------------------------------------------
  void _openEditModal() {
    if (_user != null) {
      _editName = _user!["name"] ?? "";
      _editBio = _user!["bio"] ?? "";
      _editProfilePictureFile = null;
      _previewProfilePicture = null;
    }
    setState(() {
      _error = null;
      _editModalOpen = true;
    });
  }

  void _closeEditModal() {
    setState(() {
      _editModalOpen = false;
    });
  }

  Future<void> _handlePickProfilePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _editProfilePictureFile = File(pickedFile.path);
        _previewProfilePicture = pickedFile.path;
      });
    }
  }

  Future<void> _saveProfileChanges() async {
    if (_user == null) {
      setState(() {
        _error = "User data is not loaded.";
      });
      return;
    }
    setState(() {
      _updating = true;
      _error = null;
    });

    try {
      final token = await _getToken();
      if (token == null) {
        setState(() {
          _error = "Authentication token not found.";
          _updating = false;
        });
        return;
      }

      final userId = _user!["id"] ?? _user!["userId"];
      if (userId == null) {
        setState(() {
          _error = "No user ID in user data.";
          _updating = false;
        });
        return;
      }

      final url = "$BASE_URL/users/update/$userId";
      var request = http.MultipartRequest("PUT", Uri.parse(url));
      request.headers["Authorization"] = "Bearer $token";

      // Name, Bio
      request.fields["name"] = _editName;
      request.fields["bio"] = _editBio;

      // Possibly include something for role if you want user to change role
      // request.fields["roleId"] = "..."  etc.

      if (_editProfilePictureFile != null) {
        // "profilePicture" is the field name from your backend
        request.files.add(
          await http.MultipartFile.fromPath(
            "profilePicture",
            _editProfilePictureFile!.path,
          ),
        );
      }

      final streamed = await request.send();
      final resp = await http.Response.fromStream(streamed);

      if (resp.statusCode == 200) {
        final updatedUser = jsonDecode(resp.body);
        setState(() {
          _user = updatedUser;
          _editModalOpen = false;
        });
      } else {
        setState(() {
          _error = "Failed to update profile: ${resp.body}";
        });
      }
    } catch (e) {
      setState(() {
        _error = "Error: $e";
    });
    } finally {
      setState(() {
        _updating = false;
      });
    }
  }

  // ----------------------------------------------------------------
  // UTIL
  // ----------------------------------------------------------------
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("authToken");
  }

  Future<String?> _getLoggedInUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("userId");
  }

  String _roleToString(int? roleId) {
    if (roleId == null) return "Unknown";
    return roleMap[roleId] ?? "Unknown";
  }

  // ----------------------------------------------------------------
  // BUILD
  // ----------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    // 1) Loading
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Profile")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // 2) Error
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Profile")),
        body: Center(
          child: Text("Error: $_error", style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    // 3) If user is null
    if (_user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Profile")),
        body: const Center(child: Text("User not found.")),
      );
    }

    // Parse user data
    final userName = _user!["name"] ?? "Unknown";
    final userEmail = _user!["email"] ?? "Unknown";
    final userBio = _user!["bio"] ?? "No bio added yet.";
    final roleId = _user!["roleId"];
    final userRole = _roleToString(roleId);
    final profilePic = _user!["profilePicture"];
    final fullProfilePicUrl = (profilePic != null && profilePic.isNotEmpty)
        ? "$BASE_URL/uploads/$profilePic"
        : null;

    // Build main scaffold
    final mainScaffold = Scaffold(
      appBar: AppBar(
        title: Text("$userName's Profile"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // TOP SECTION
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Pic
                ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: fullProfilePicUrl != null
                      ? Image.network(
                          fullProfilePicUrl,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.person, size: 50),
                        ),
                ),
                const SizedBox(width: 16),
                // Name & role & email
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(userRole, style: const TextStyle(fontSize: 14)),
                      ),
                      const SizedBox(height: 8),
                      Text(userEmail, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // BIO
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Bio", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(userBio),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Faculty & Department
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.account_balance, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(_facultyName ?? "N/A"),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.business, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(_departmentName ?? "N/A"),
                      ],
                    ),
                    // If user is Candidate or Party Manager
                    if (roleId == 2 || roleId == 4) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.link, color: Colors.green),
                          const SizedBox(width: 8),
                          _profileElectionId != null
                              ? GestureDetector(
                                  onTap: () {
                                    // e.g., navigate to /details/:id
                                    Navigator.pushNamed(context, "/details/${_profileElectionId}");
                                  },
                                  child: Text(
                                    "Election #$_profileElectionId (Tap to view)",
                                    style: const TextStyle(color: Colors.blue),
                                  ),
                                )
                              : const Text("No election found"),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // If it is own profile, show "Edit" button
            if (_isOwnProfile)
              ElevatedButton(
                onPressed: _openEditModal,
                child: const Text("Edit Profile"),
              ),
          ],
        ),
      ),
    );

    // If edit modal is not open, return the main scaffold
    if (!_editModalOpen) {
      return mainScaffold;
    }

    // If edit modal is open, we wrap the main scaffold in a Stack with an overlay
    return Stack(
      children: [
        mainScaffold,
        GestureDetector(
          onTap: _closeEditModal,
          child: Container(
            color: Colors.black54,
            child: Center(
              child: GestureDetector(
                onTap: () {}, // block tap
                child: _buildEditProfileContent(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Build the content of the edit modal
  Widget _buildEditProfileContent() {
    if (_updating) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          CircularProgressIndicator(),
          SizedBox(height: 8),
          Text("Saving changes..."),
        ],
      );
    }

    return Container(
      width: 350,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Edit Your Profile",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Name
            TextField(
              decoration: const InputDecoration(labelText: "Name"),
              controller: TextEditingController(text: _editName),
              onChanged: (val) => _editName = val,
            ),
            const SizedBox(height: 12),

            // Bio
            TextField(
              decoration: const InputDecoration(labelText: "Bio"),
              minLines: 2,
              maxLines: 4,
              controller: TextEditingController(text: _editBio),
              onChanged: (val) => _editBio = val,
            ),
            const SizedBox(height: 12),

            // Profile Picture
            Row(
              children: [
                if (_previewProfilePicture != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.file(
                      File(_previewProfilePicture!),
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.image, size: 30),
                  ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _handlePickProfilePicture,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Change Picture"),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _closeEditModal,
                  child: const Text("Cancel"),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _saveProfileChanges,
                  child: const Text("Save Changes"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
