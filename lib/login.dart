// login.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';
import 'home.dart';
import 'signup.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isProcessingLogin = false;
  String? _errorMessage;

  Future<void> _loginUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessingLogin = true;
      _errorMessage = null;
    });

    final Uri url = Uri.parse("http://localhost:8080/auth/login");

    try {
      // 1) Send login request
      final http.Response response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "email": _emailController.text.trim(),
          "password": _passwordController.text.trim(),
        }),
      );

      // 2) Check status
      if (response.statusCode == 200) {
        final String token = response.body; // token from server

        if (token.isEmpty) {
          setState(() {
            _errorMessage = "Invalid login response (no token found).";
          });
        } else {
          // 3) Store token in SharedPreferences
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString("authToken", token);

          // 4) Fetch user profile to get userId, facultyId, etc.
          final fetched = await _fetchUserProfile(token);
          if (!fetched) {
            // If fetching profile fails, show error
            setState(() {
              _errorMessage = "Failed to fetch user profile.";
              _isProcessingLogin = false;
            });
            return;
          }

          // 5) Decode token to find roles
          final Map<String, dynamic> decoded = _decodeJWT(token);
          List<String> roles = <String>[];
          if (decoded.containsKey("roles")) {
            final dynamic rawRoles = decoded["roles"];
            if (rawRoles is List) {
              roles = rawRoles.map((e) => e.toString()).toList();
            }
          }
          await prefs.setStringList("userRoles", roles);

          // 6) Navigate based on roles
          if (roles.contains("ROLE_ADMIN")) {
            // Navigate to admin or home; up to you
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );
          }
        }
      } else {
        setState(() {
          _errorMessage = "Login failed: ${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Login error: $e";
      });
    } finally {
      setState(() {
        _isProcessingLogin = false;
      });
    }
  }

  /// Fetches user profile from `/users/profile` using the token, then
  /// stores userId, facultyId, departmentId, etc. in SharedPreferences.
  Future<bool> _fetchUserProfile(String token) async {
    try {
      final Uri profileUrl = Uri.parse("http://localhost:8080/users/profile");
      final response = await http.get(
        profileUrl,
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Example: { "userId": 12, "email": "...", "facultyId": 3, "departmentId": 4, ... }

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("userId", data["userId"].toString());
        await prefs.setString("email", data["email"] ?? "");
        // If you have facultyId, departmentId
        if (data["facultyId"] != null) {
          await prefs.setString("facultyId", data["facultyId"].toString());
        }
        if (data["departmentId"] != null) {
          await prefs.setString("departmentId", data["departmentId"].toString());
        }

        return true; // success
      } else {
        return false; // not 200
      }
    } catch (e) {
      return false;
    }
  }

  // Decodes the JWT (payload only)
  Map<String, dynamic> _decodeJWT(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        return <String, dynamic>{};
      }
      final payloadBase64 = _normalizeBase64(parts[1]);
      final decodedBytes = base64Url.decode(payloadBase64);
      final decodedString = utf8.decode(decodedBytes);
      return jsonDecode(decodedString) as Map<String, dynamic>;
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  // Fixes base64 padding
  String _normalizeBase64(String str) {
    final missing = (4 - str.length % 4) % 4;
    return str.padRight(str.length + missing, '=');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Container(color: const Color(0xFFFFFBE6)),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: <Widget>[
                  Image.asset('assets/logo.png', height: 100, width: 100),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: GlassContainer(
                        blur: 15,
                        opacity: 0.2,
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                const Text(
                                  'Welcome Back!',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF347928),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                if (_errorMessage != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(color: Colors.red),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                _buildTextField(
                                  controller: _emailController,
                                  label: 'Email',
                                  icon: Icons.email,
                                  validator: (value) =>
                                      (value == null || value.trim().isEmpty)
                                          ? 'Please enter your email'
                                          : null,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: _passwordController,
                                  label: 'Password',
                                  icon: Icons.lock,
                                  obscureText: _obscurePassword,
                                  validator: (value) =>
                                      (value == null || value.trim().isEmpty)
                                          ? 'Please enter your password'
                                          : null,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: const Color(0xFFFCCD2A),
                                    ),
                                    onPressed: () => setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    }),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: _isProcessingLogin ? null : _loginUser,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    backgroundColor: const Color(0xFF347928),
                                  ),
                                  child: _isProcessingLogin
                                      ? const CircularProgressIndicator(color: Colors.white)
                                      : const Text('Login', style: TextStyle(fontSize: 18, color: Colors.white)),
                                ),
                                const SizedBox(height: 16),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const SignUpPage()),
                                    );
                                  },
                                  child: const Text(
                                    "Don't have an account? Sign Up",
                                    style: TextStyle(fontSize: 16, color: Color(0xFF347928)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF347928)),
        prefixIcon: Icon(icon, color: const Color(0xFF347928)),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(style: BorderStyle.none),
        ),
        filled: true,
        fillColor: const Color(0xFFC0EBA6),
      ),
    );
  }
}

class GlassContainer extends StatelessWidget {
  final double blur;
  final double opacity;
  final Widget child;

  const GlassContainer({
    Key? key,
    required this.blur,
    required this.opacity,
    required this.child,
  }) : super(key: key);

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
