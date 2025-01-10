import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:e_voting_system/login.dart';
import 'package:e_voting_system/verification.dart';
import 'dart:ui';


class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _universityNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // حفظ البيانات في SharedPreferences
  Future<void> _saveUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setString('username', _usernameController.text);
    await prefs.setString('universityNumber', _universityNumberController.text);
    await prefs.setString('email', _emailController.text);
    await prefs.setString('password', _passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // الخلفية
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFFFFBE6), // لون الخلفية
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // اللوجو
                  Image.asset(
                    'assets/logo.png', // مسار اللوجو
                    height: 100,
                    width: 100,
                  ),
                  const SizedBox(height: 20),
                  // البطاقة الزجاجية
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: GlassContainer(
                      blur: 15,
                      opacity: 0.2,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Create an Account',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF347928), // Primary Color
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              _buildTextField(
                                controller: _usernameController,
                                label: 'Username',
                                icon: Icons.person,
                                validator: (value) =>
                                    value!.isEmpty ? 'Please enter your username' : null,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _universityNumberController,
                                label: 'University Number',
                                icon: Icons.numbers,
                                validator: (value) => value!.isEmpty || value.length != 7
                                    ? 'Enter a valid 7-digit university number'
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _emailController,
                                label: 'University Email',
                                icon: Icons.email,
                                validator: (value) => value!.isEmpty ||
                                        !value.contains('@student.birzeit.edu')
                                    ? 'Enter a valid university email'
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _passwordController,
                                label: 'Password',
                                icon: Icons.lock,
                                obscureText: true,
                                validator: (value) =>
                                    value!.isEmpty ? 'Please enter your password' : null,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    _saveUserData(); // حفظ البيانات
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => const VerificationPage()),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  backgroundColor: const Color(0xFF347928), // Primary Color
                                ),
                                child: const Text(
                                  'Next',
                                  style: TextStyle(fontSize: 18, color: Colors.white),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Already have an account? ',
                                    style:
                                        TextStyle(fontSize: 16, color: Color(0xFF347928)), // Primary
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => const LoginPage()),
                                      );
                                    },
                                    child: const Text(
                                      'Login',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF5E82FF), // Secondary Color
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
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

  // الحقل النصي
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
        labelStyle: const TextStyle(color: Color(0xFF347928)), // Primary Color
        prefixIcon: Icon(icon, color: const Color(0xFF347928)), // Primary Color
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: const Color(0xFFC0EBA6), // Secondary Color
      ),
    );
  }
}

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
