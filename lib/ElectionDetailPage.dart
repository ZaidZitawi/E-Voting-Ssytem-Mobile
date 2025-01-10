import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'CandidateProfilePage .dart';

class ElectionDetailPage extends StatefulWidget {
  final String electionTitle;

  const ElectionDetailPage({
    super.key,
    required this.electionTitle,
  });

  @override
  _ElectionDetailPageState createState() => _ElectionDetailPageState();
}

class _ElectionDetailPageState extends State<ElectionDetailPage> {
  final List<Map<String, String>> candidates = [
    {
      'name': 'الكتلة الاسلامية',
      'email': 'alice.johnson@example.com',
      'image': 'assets/aalkhutla.png',
    },
    {
      'name': 'حركة الشبيبة الطلابية',
      'email': 'bob.brown@example.com',
      'image': 'assets/bob_brown.jpg',
    },
    {
      'name': 'كتلة الوحدة الطلابية',
      'email': 'unity.students@example.com',
      'image': 'assets/unity.jpg',
    },
    {
      'name': 'كتلة اتحاد الطلبة',
      'email': 'union.students@example.com',
      'image': 'assets/union.jpg',
    },
  ];

  final List<double> votes = [35, 28, 17, 20];

  late Timer _timer;
  Duration _remainingTime = const Duration(hours: 2, minutes: 30); // الوقت المتبقي

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
        // يمكن تنفيذ منطق انتهاء التصويت هنا
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.electionTitle),
        backgroundColor: const Color(0xFF347928),
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
                  color: const Color(0xFFFCCD2A),
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
                    const Icon(Icons.timer, color: Colors.white),
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
                  child: Image.asset('assets/Maglis.jpg'),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Real-time Voting Results',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF347928),
                ),
              ),
              const SizedBox(height: 8),
              _buildBarChart(candidates, votes),
              const SizedBox(height: 16),
              const Text(
                'Candidates',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF347928),
                ),
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: candidates.length,
                itemBuilder: (context, index) {
                  return _buildCandidateCard(context, candidates[index]);
                },
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: () => _showVotingDialog(context, candidates),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFCCD2A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    elevation: 5,
                    shadowColor: Colors.grey.withOpacity(0.4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.how_to_vote, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Vote Now',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart(List<Map<String, String>> candidates, List<double> votes) {
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          barGroups: List.generate(candidates.length, (index) {
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: votes[index],
                  color: const Color.fromARGB(255, 218, 31, 40),
                  width: 20,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() < candidates.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        candidates[value.toInt()]['name']!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF347928),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  Widget _buildCandidateCard(BuildContext context, Map<String, String> candidate) {
    return Card(
      color: const Color(0xFFC0EBA6),
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: AssetImage(candidate['image']!),
        ),
        title: Text(
          candidate['name']!,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF347928),
          ),
        ),
        subtitle: Text(
          candidate['email']!,
          style: const TextStyle(
            color: Color(0xFF4A4A4A),
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CandidateProfilePage(
                name: candidate['name']!,
                email: candidate['email']!,
                image: candidate['image']!,
              ),
            ),
          );
        },
      ),
    );
  }

  void _showVotingDialog(BuildContext context, List<Map<String, String>> candidates) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Select a Candidate',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF347928),
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: candidates.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 30,
                      backgroundImage: AssetImage(candidates[index]['image']!),
                    ),
                    title: Text(
                      candidates[index]['name']!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF347928),
                      ),
                    ),
                    subtitle: Text(
                      candidates[index]['email']!,
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.how_to_vote,
                      color: Color(0xFFFCCD2A),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'You voted for ${candidates[index]['name']}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor: const Color(0xFF347928),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
