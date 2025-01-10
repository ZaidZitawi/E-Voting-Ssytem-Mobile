import 'package:flutter/material.dart';
import 'login.dart';
import 'signup.dart';
import 'verification.dart';
import 'specialization.dart';
import 'home.dart'; // Import the HomePage
import 'ProfileUserPage.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      theme: ThemeData(
        primarySwatch: Colors.green, // Set a primary color for the theme
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      routes: {
        '/': (context) => const HomePage(),
        '/signup': (context) => const SignUpPage(),
        '/verification': (context) => const VerificationPage(),
        '/specialization': (context) => const SpecializationPage(),
        '/home': (context) => const HomePage(),
        '/profile': (context) => const ProfilePage(), // Added Profile route
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
            builder: (context) => const LoginPage()); // Fallback route
      },
    );
  }
}
