// signup.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login.dart';
import 'dart:ui';
import 'package:e_voting_system/constants.dart' as Constants;

const BASE_URL = Constants.BASE_URL;
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // --- Controllers ---
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _verificationCodeController = TextEditingController();

  // --- Step 3: Faculty/Department ---
  List<Map<String, dynamic>> _faculties = [];
  List<Map<String, dynamic>> _departments = [];
  String? _selectedFaculty;
  String? _selectedDepartment;

  // --- State flags & data ---
  bool _isProcessing = false;
  String? _errorMessage;
  String? _authToken;
  int _step = 1; // We start at Step 1

  @override
  void initState() {
    super.initState();
  }

  // -----------------------------
  // STEP 1: Register the user
  // -----------------------------
  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    final url = Uri.parse("$BASE_URL/auth/register");

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "name": _nameController.text.trim(),
          "email": _emailController.text.trim(),
          "password": _passwordController.text.trim(),
          "confirmPassword": _confirmPasswordController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        // Backend typically returns a success message
        // We move to Step 2: Verification
        setState(() {
          _step = 2;
        });
      } else {
        setState(() {
          _errorMessage = "Signup failed: ${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error: $e";
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // -----------------------------
  // STEP 2: Verify code
  // -----------------------------
  Future<void> _verifyCode() async {
    if (_verificationCodeController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = "Please enter the verification code.";
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    final url = Uri.parse("$BASE_URL/auth/verify");
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "email": _emailController.text.trim(),
          "verificationCode": _verificationCodeController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        // The backend might return a token string
        final token = response.body;
        _authToken = token;

        // Save token in SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("authToken", token);

        // Move to Step 3: Select Faculty & Department
        setState(() {
          _step = 3;
        });

        // Immediately fetch faculties
        await _fetchFaculties();
      } else {
        setState(() {
          _errorMessage = "Invalid verification code: ${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error verifying code: $e";
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // -----------------------------------------------
  // STEP 3: Fetch faculties, fetch departments, etc
  // -----------------------------------------------
  Future<void> _fetchFaculties() async {
    setState(() {
      _isProcessing = true;
    });

    final url = Uri.parse("$BASE_URL/faculty-and-department/faculties");
    try {
      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $_authToken"},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _faculties = data
              .map((e) => {"id": e["facultyId"], "name": e["facultyName"]})
              .toList();
        });
      } else {
        setState(() {
          _errorMessage = "Failed to fetch faculties: ${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error fetching faculties: $e";
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _fetchDepartments(String facultyId) async {
    setState(() {
      _isProcessing = true;
      _departments = [];
      _selectedDepartment = null;
    });

    final url = Uri.parse("$BASE_URL/faculty-and-department/faculties/$facultyId/departments");
    try {
      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $_authToken"},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _departments = data
              .map((e) => {"id": e["departmentId"], "name": e["departmentName"]})
              .toList();
        });
      } else {
        setState(() {
          _errorMessage = "Failed to fetch departments: ${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error fetching departments: $e";
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // Complete the registration
  Future<void> _completeRegistration() async {
    if (_selectedFaculty == null || _selectedDepartment == null) {
      setState(() {
        _errorMessage = "Please select both Faculty and Department.";
      });
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    final url = Uri.parse(
      "$BASE_URL/auth/complete-registration?email=${Uri.encodeComponent(_emailController.text.trim())}"
    );

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          "Authorization": "Bearer $_authToken"
        },
        body: jsonEncode({
          "facultyId": int.parse(_selectedFaculty!),
          "departmentId": int.parse(_selectedDepartment!),
        }),
      );

      if (response.statusCode == 200) {
        // Registration done: Go to login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      } else {
        setState(() {
          _errorMessage = "Failed to complete registration: ${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Something went wrong: $e";
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // --------------------------------------------------------------------------------
  // UI Building
  // --------------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Color
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFFFFBE6),
            ),
          ),
          // GlassContainer with steps
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  Image.asset(
                    'assets/logo.png',
                    height: 100,
                    width: 100,
                  ),
                  const SizedBox(height: 20),
                  // Glass Container
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: GlassContainer(
                      blur: 15,
                      opacity: 0.2,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: _buildStepForm(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Render different steps
  Widget _buildStepForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _stepTitle(),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF347928), // Primary Color
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          // Show any error message
          if (_errorMessage != null) ...[
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
          ],

          // Step-specific fields
          if (_step == 1) _buildStep1Fields(),
          if (_step == 2) _buildStep2Fields(),
          if (_step == 3) _buildStep3Fields(),

          const SizedBox(height: 24),
          // Step Action Button
          _buildStepButton(),

          const SizedBox(height: 20),
          // Already have an account?
          _buildLoginLink(),
        ],
      ),
    );
  }

  // -------------------------------
  // STEP 1 Fields: Name, Email, PW
  // -------------------------------
  Widget _buildStep1Fields() {
    return Column(
      children: [
        _buildTextField(
          controller: _nameController,
          label: 'Full Name',
          icon: Icons.person,
          validator: (val) {
            if (val == null || val.trim().length < 3) {
              return "Name must be at least 3 characters.";
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _emailController,
          label: 'University Email',
          icon: Icons.email,
          validator: (val) {
            if (val == null ||
                !RegExp(r"^[0-9]+@student\.birzeit\.edu$")
                    .hasMatch(val.trim())) {
              return "Email must be studentnumber@student.birzeit.edu";
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _passwordController,
          label: 'Password',
          icon: Icons.lock,
          obscureText: true,
          validator: (val) {
            if (val == null || val.trim().length < 8) {
              return "Password must be at least 8 characters.";
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _confirmPasswordController,
          label: 'Confirm Password',
          icon: Icons.lock_outline,
          obscureText: true,
          validator: (val) {
            if (val != _passwordController.text) {
              return "Passwords do not match.";
            }
            return null;
          },
        ),
      ],
    );
  }

  // -------------------------------
  // STEP 2 Fields: Verification Code
  // -------------------------------
  Widget _buildStep2Fields() {
    return Column(
      children: [
        _buildTextField(
          controller: _verificationCodeController,
          label: 'Verification Code',
          icon: Icons.verified,
          validator: (val) {
            if (val == null || val.isEmpty) {
              return "Please enter your verification code.";
            }
            return null;
          },
        ),
      ],
    );
  }

  // -------------------------------
  // STEP 3 Fields: Faculty/Dept
  // -------------------------------
  Widget _buildStep3Fields() {
    return Column(
      children: [
        // Faculty Dropdown
        DropdownButtonFormField<String>(
          decoration: _buildDropdownDecoration("Select Faculty", Icons.account_balance),
          value: _selectedFaculty,
          items: _faculties.map((f) {
            return DropdownMenuItem(
              value: f["id"].toString(),
              child: Text(f["name"]),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              _selectedFaculty = val;
            });
            if (val != null) {
              _fetchDepartments(val);
            }
          },
        ),
        const SizedBox(height: 16),
        // Department Dropdown
        DropdownButtonFormField<String>(
          decoration: _buildDropdownDecoration("Select Department", Icons.account_tree_outlined),
          value: _selectedDepartment,
          items: _departments.map((d) {
            return DropdownMenuItem(
              value: d["id"].toString(),
              child: Text(d["name"]),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              _selectedDepartment = val;
            });
          },
        ),
      ],
    );
  }

  // Step Title
  String _stepTitle() {
    switch (_step) {
      case 1:
        return "Create an Account";
      case 2:
        return "Verify Your Email";
      case 3:
        return "Complete Registration";
      default:
        return "";
    }
  }

  // Step Button
  Widget _buildStepButton() {
    if (_isProcessing) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (_step) {
      case 1:
        return ElevatedButton(
          onPressed: _registerUser,
          style: _elevatedButtonStyle(),
          child: const Text("Next", style: TextStyle(fontSize: 18, color: Colors.white)),
        );
      case 2:
        return ElevatedButton(
          onPressed: _verifyCode,
          style: _elevatedButtonStyle(),
          child: const Text("Next", style: TextStyle(fontSize: 18, color: Colors.white)),
        );
      case 3:
        return ElevatedButton(
          onPressed: _completeRegistration,
          style: _elevatedButtonStyle(),
          child: const Text("Finish", style: TextStyle(fontSize: 18, color: Colors.white)),
        );
      default:
        return Container();
    }
  }

  // "Already have an account?"
  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Already have an account? ',
          style: TextStyle(fontSize: 16, color: Color(0xFF347928)),
        ),
        GestureDetector(
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          },
          child: const Text(
            'Login',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5E82FF),
            ),
          ),
        ),
      ],
    );
  }

  // Reusable TextField
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF347928)),
        prefixIcon: Icon(icon, color: const Color(0xFF347928)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: const Color(0xFFC0EBA6),
      ),
    );
  }

  // Reusable Dropdown Input Decoration
  InputDecoration _buildDropdownDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF347928)),
      prefixIcon: Icon(icon, color: Color(0xFF347928)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: const Color(0xFFC0EBA6),
    );
  }

  // ElevatedButton style
  ButtonStyle _elevatedButtonStyle() {
    return ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      backgroundColor: const Color(0xFF347928),
    );
  }
}

// ------------------------------------------------
// GlassContainer from your original design
// ------------------------------------------------
class GlassContainer extends StatelessWidget {
  final double blur;
  final double opacity;
  final Widget child;

  const GlassContainer({
    required this.blur,
    required this.opacity,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
            borderRadius: BorderRadius.circular(30),
          ),
          child: child,
        ),
      ),
    );
  }
}
