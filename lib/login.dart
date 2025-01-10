import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home.dart'; // تأكد من استيراد الصفحة الرئيسية
import 'signup.dart';
import 'dart:ui';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _universityNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isProcessingLogin = false;

  Future<void> _loginUser() async {
    if (_isProcessingLogin) return;

    setState(() {
      _isProcessingLogin = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedUniversityNumber = prefs.getString('universityNumber');
    String? storedPassword = prefs.getString('password');

    if (storedPassword == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No saved credentials found.')),
      );
      setState(() {
        _isProcessingLogin = false;
      });
      return;
    }

    if (_universityNumberController.text.trim() == storedUniversityNumber &&
        _passwordController.text.trim() == storedPassword) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid credentials, please try again!')),
      );
    }

    setState(() {
      _isProcessingLogin = false;
    });
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
                    'assets/logo.png', // مسار اللوجو داخل مجلد assets
                    height: 100, // ارتفاع اللوجو
                    width: 1000, // عرض اللوجو
                  ),
                  const SizedBox(height: 20), // مسافة بين اللوجو والبطاقة
                  Padding(
                    padding: const EdgeInsets.only(top: 20), // مسافة علوية
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
                              children: [
                                const Text(
                                  'Welcome Back!',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF347928), // Primary Color
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                _buildTextField(
                                  controller: _universityNumberController,
                                  label: 'University Number',
                                  icon: Icons.numbers,
                                  validator: (value) => value!.isEmpty
                                      ? 'Please enter your university number'
                                      : null,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: _passwordController,
                                  label: 'Password',
                                  icon: Icons.lock,
                                  obscureText: _obscurePassword,
                                  validator: (value) => value!.isEmpty
                                      ? 'Please enter your password'
                                      : null,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Color(0xFFFCCD2A), // Accent Color
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: _loginUser,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    backgroundColor: const Color(0xFF347928), // Primary Color
                                  ),
                                  child: _isProcessingLogin
                                      ? const CircularProgressIndicator(
                                          color: Colors.white)
                                      : const Text(
                                          'Login',
                                          style: TextStyle(
                                              fontSize: 18, color: Colors.white),
                                        ),
                                ),
                                const SizedBox(height: 16),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => const SignUpPage()),
                                    );
                                  },
                                  child: const Text(
                                    'Don\'t have an account? Sign Up',
                                    style: TextStyle(
                                        fontSize: 16, color: Color(0xFF347928)),
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
        labelStyle: const TextStyle(color: Color(0xFF347928)), // Primary Color
        prefixIcon: Icon(icon, color: const Color(0xFF347928)), // Primary Color
        suffixIcon: suffixIcon,
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
