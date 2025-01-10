import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String username = '';
  String universityNumber = '';
  String email = '';
  String department = '';
  String specialization = '';
  String password = '';
  String bio = ''; // حقل السيرة الذاتية
  List<String> historyVote = []; // قائمة العمليات الانتخابية
  File? userImage;
  final bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
      username = prefs.getString('username') ?? 'Unknown';
      universityNumber = prefs.getString('universityNumber') ?? 'Unknown';
      email = prefs.getString('email') ?? 'Unknown';
      department = prefs.getString('department') ?? 'Not Set';
      specialization = prefs.getString('specialization') ?? 'Not Set';
      password = prefs.getString('password') ?? 'Unknown';
      bio = prefs.getString('bio') ?? 'Add a short bio about yourself';
      historyVote = prefs.getStringList('historyVote') ?? []; // تحميل قائمة historyVote
      String? imagePath = prefs.getString('userImage');
      if (imagePath != null) {
        userImage = File(imagePath);
      } else {
        userImage = null; // or handle this case as needed
      }
    });
  }

  Future<void> _updateField(String field, String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      switch (field) {
        case 'username':
          username = value;
          prefs.setString('username', value);
          break;
        case 'password':
          password = value;
          prefs.setString('password', value);
          break;
        case 'bio':
          bio = value;
          prefs.setString('bio', value);
          break;
      }
    });
  }

  Future<void> _editField(String field, String label, String currentValue) async {
    String? newValue = await _showEditDialog(context, label, currentValue);
    if (newValue != null && newValue.isNotEmpty) {
      _updateField(field, newValue);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        userImage = File(pickedFile.path);
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userImage', pickedFile.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // الجزء العلوي
          Container(
            width: 300,
            height: 200,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF347928), Color(0xFF65A30D)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(30),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    backgroundImage:
                        userImage != null ? FileImage(userImage!) : null,
                    child: userImage == null
                        ? const Icon(Icons.camera_alt, size: 40, color: Colors.grey)
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  username,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  bio,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // معلومات المستخدم + العمليات الانتخابية
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // معلومات المستخدم
                _buildProfileTile(
                  icon: Icons.person,
                  label: 'Username',
                  value: username,
                  field: 'username',
                ),
                _buildProfileTile(
                  icon: Icons.school,
                  label: 'University Number',
                  value: universityNumber,
                ),
                _buildProfileTile(
                  icon: Icons.email,
                  label: 'Email',
                  value: email,
                ),
                _buildProfileTile(
                  icon: Icons.business,
                  label: 'Department',
                  value: department,
                ),
                _buildProfileTile(
                  icon: Icons.work,
                  label: 'Specialization',
                  value: specialization,
                ),
                _buildProfileTile(
                  icon: Icons.text_snippet,
                  label: 'Bio',
                  value: bio,
                  field: 'bio',
                ),
                _buildProfileTile(
                  icon: Icons.lock,
                  label: 'Password',
                  value: '••••••••',
                  isPassword: true,
                  field: 'password',
                ),
                const SizedBox(height: 20),

                // العمليات الانتخابية
                const Text(
                  'History Vote',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF347928),
                  ),
                ),
                const SizedBox(height: 10),
                ...historyVote.map((election) => Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      child: ListTile(
                        leading: const Icon(Icons.how_to_vote, color: Color(0xFF347928)),
                        title: Text(
                          election,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTile({
    required IconData icon,
    required String label,
    required String value,
    bool isPassword = false,
    String? field,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF347928)),
        title: Text(label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(value,
            style: const TextStyle(fontSize: 14, color: Colors.black54)),
        trailing: field != null
            ? IconButton(
                icon: const Icon(Icons.edit, color: Colors.yellow),
                onPressed: () {
                  _editField(field, label, value);
                },
              )
            : null,
      ),
    );
  }

  Future<String?> _showEditDialog(
      BuildContext context, String label, String currentValue) {
    TextEditingController controller = TextEditingController(text: currentValue);

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit $label'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.yellow),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
