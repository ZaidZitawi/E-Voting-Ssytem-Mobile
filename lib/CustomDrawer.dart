import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomDrawer extends StatelessWidget {
  final Function(int) onItemTapped;
  final VoidCallback onNavigateToFacebook;

  const CustomDrawer({
    super.key,
    required this.onItemTapped,
    required this.onNavigateToFacebook,
  });

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
         SizedBox(
  height: 117, // تحديد ارتفاع أصغر للمساحة الخضراء
  child: DrawerHeader(
    decoration: const BoxDecoration(
      color: Color(0xFF347928), // Primary Color
    ),
    child: const Text(
      'Navigation',
      style: TextStyle(
        color: Colors.white,
        fontSize: 20, // تقليل حجم الخط إذا أردت
      ),
    ),
  ),
),

          ListTile(
            leading: const Icon(Icons.home, color: Color(0xFF347928)),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
              onItemTapped(0);
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today, color: Color(0xFF347928)),
            title: const Text('Calendar'),
            onTap: () {
              Navigator.pop(context);
              onItemTapped(1);
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications, color: Color(0xFF347928)),
            title: const Text('Notifications'),
            onTap: () {
              Navigator.pop(context);
              onItemTapped(2);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person, color: Color(0xFF347928)),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              onItemTapped(3);
            },
          ),
          ListTile(
            leading: const Icon(Icons.school, color: Color(0xFF347928)),
            title: const Text('University Page'),
            onTap: () {
              Navigator.pop(context);
              _launchURL(
                'https://www.facebook.com/BirzeitUniversity',
              );
            },
          ),
        ],
      ),
    );
  }
}
