import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Display the notifications
            Expanded(
              child: ListView.builder(
                itemCount: 5,  // Placeholder, replace with your data count
                itemBuilder: (context, index) {
                  return _buildNotificationCard(
                    title: 'Notification #${index + 1}',
                    content: 'This is the content of notification #${index + 1}.',
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build notification card widget
  Widget _buildNotificationCard({required String title, required String content}) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(content),
          ],
        ),
      ),
    ); 
  }
}
