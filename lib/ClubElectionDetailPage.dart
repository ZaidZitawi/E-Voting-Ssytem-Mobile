import 'dart:async';
import 'package:flutter/material.dart';
import 'GroupProfilePage.dart';

class ClubElectionDetailPage extends StatefulWidget {
  final String clubName;

  const ClubElectionDetailPage({super.key, required this.clubName});

  @override
  _ClubElectionDetailPageState createState() => _ClubElectionDetailPageState();
}

class _ClubElectionDetailPageState extends State<ClubElectionDetailPage> {
  final List<Map<String, String>> candidates = [
    {'name': 'Group 1', 'image': 'assets/candidate1.png'},
    {'name': 'Group 2', 'image': 'assets/candidate2.png'},
    {'name': 'Group 3', 'image': 'assets/candidate3.png'},
    {'name': 'Group 4', 'image': 'assets/candidate4.png'},
  ];

  late Timer _timer;
  Duration _remainingTime = const Duration(hours: 2, minutes: 30);

  String? _selectedCandidate; // تخزين المجموعة المنتخبة

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime.inSeconds > 0) {
        setState(() {
          _remainingTime -= const Duration(seconds: 1);
        });
      } else {
        _timer.cancel();
        // منطق انتهاء التصويت
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  void _showVotingDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Vote for a Group',
            style: TextStyle(color: Color(0xFF0D47A1)),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: candidates.map((candidate) {
                return RadioListTile<String>(
                  title: Text(
                    candidate['name']!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF347928),
                    ),
                  ),
                  value: candidate['name'] ?? '',
groupValue: _selectedCandidate ?? '',

                  onChanged: (value) {
                    setState(() {
                      _selectedCandidate = value;
                    });
                    Navigator.of(context).pop(); // إغلاق الحوار بعد الاختيار
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF0D47A1)),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.clubName),
        backgroundColor: const Color(0xFF347928),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timer widget
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.timer, color: Colors.white, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Time Remaining: ${_formatDuration(_remainingTime)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // College image
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 3,
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/Engineering and Technology.png',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 200,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Candidates Section
              const Text(
                'Candidate Groups:',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D47A1),
                ),
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: candidates.length,
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GroupProfilePage(
                              groupName: candidates[index]['name']!,
                              clubName: widget.clubName,
                              groupImage: candidates[index]['image']!,
                              groupBio: "This is a brief description of the group.",
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundImage: AssetImage(candidates[index]['image']!),
                              radius: 40,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                candidates[index]['name']!,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0D47A1),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Vote Button
              Center(
                child: ElevatedButton(
                  onPressed: _showVotingDialog,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: const Color(0xFF347928),
                  ),
                  child: const Text(
                    'Vote Now',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              if (_selectedCandidate != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Center(
                    child: Text(
                      'You voted for: $_selectedCandidate',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D47A1),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
