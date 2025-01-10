import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui'; // لتفعيل تأثير الزجاج
import 'home.dart'; // Import the HomePage

class SpecializationPage extends StatefulWidget {
  const SpecializationPage({super.key});

  @override
  _SpecializationPageState createState() => _SpecializationPageState();
}

class _SpecializationPageState extends State<SpecializationPage> {
  final _formKey = GlobalKey<FormState>();
  final _departmentController = TextEditingController();
  final _specializationController = TextEditingController();

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
                    'assets/logo.png', // تأكد من وجود صورة اللوجو
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
                                'Enter Department and Specialization',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF347928), // Primary Color
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              _buildTextField(
                                controller: _departmentController,
                                label: 'Department',
                                icon: Icons.business,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Enter your department';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _specializationController,
                                label: 'Specialization',
                                icon: Icons.subject,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Enter your specialization';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    // حفظ البيانات
                                    _saveUserData();
                                    // الانتقال إلى الصفحة الرئيسية
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const HomePage(),
                                      ),
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
                                  'Submit',
                                  style: TextStyle(fontSize: 18, color: Colors.white),
                                ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
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
      validator: validator,
    );
  }

  Future<void> _saveUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('College', _departmentController.text);
    await prefs.setString('Specialization', _specializationController.text);
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
