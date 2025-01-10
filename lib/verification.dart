import 'package:flutter/material.dart';
import 'dart:ui';
import 'specialization.dart';

class VerificationPage extends StatefulWidget {
  const VerificationPage({super.key});

  @override
  _VerificationPageState createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  final _formKey = GlobalKey<FormState>();

  // قائمة للتحكم بالمربعات
  final List<TextEditingController> _controllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _handleInputChange(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      // الانتقال إلى المربع التالي
      FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
    } else if (value.isEmpty && index > 0) {
      // الرجوع إلى المربع السابق
      FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
    }
  }

  String _getCode() {
    return _controllers.map((controller) => controller.text).join();
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
                    'assets/logo.png', // تأكد من وجود صورة اللوجو هنا
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
                                'Enter Verification Code',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF347928), // Primary Color
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: List.generate(
                                  6,
                                  (index) => SizedBox(
                                    width: 50,
                                    child: TextFormField(
                                      controller: _controllers[index],
                                      focusNode: _focusNodes[index],
                                      textAlign: TextAlign.center,
                                      keyboardType: TextInputType.number,
                                      maxLength: 1,
                                      decoration: InputDecoration(
                                        counterText: "",
                                        filled: true,
                                        fillColor: const Color(0xFFC0EBA6), // Secondary Color
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                      onChanged: (value) =>
                                          _handleInputChange(index, value),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return '';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 30),
                              ElevatedButton(
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    final code = _getCode();
                                    if (code.length == 6) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const SpecializationPage(),
                                        ),
                                      );
                                    }
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
