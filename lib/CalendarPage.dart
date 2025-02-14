// CalendarPage.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:e_voting_system/constants.dart' as Constants;

const BASE_URL = Constants.BASE_URL;

class CalendarPage extends StatefulWidget {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final Map<DateTime, List<String>> _events = {};

  List<String> _selectedEvents = [];

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAllElectionsForCalendar();
  }

  Future<void> _fetchAllElectionsForCalendar() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception("No auth token found. Please log in.");
      }

      final Uri url = Uri.parse("$BASE_URL/elections/filter?page=0&size=9999");
      final response = await http.get(url, headers: {"Authorization": "Bearer $token"});

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final content = parsed["content"];
        if (content is List) {
          for (var e in content) {
            final startStr = e["startDatetime"];
            final title = e["title"] ?? "Untitled Election";
            if (startStr != null) {
              try {
                final dt = DateTime.parse(startStr);
                final dayKey = DateTime(dt.year, dt.month, dt.day);
                _events.putIfAbsent(dayKey, () => []).add(title);
              } catch (_) {

              }
            }
          }
        }

        final now = DateTime.now();
        final todayKey = DateTime(now.year, now.month, now.day);
        _selectedEvents = _events[todayKey] ?? [];
      } else {
        throw Exception("Failed to load elections: ${response.body}");
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  List<String> _getEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _events[key] ?? [];
  }

  List<Map<String, String>> _getAllEvents() {
    final all = <Map<String, String>>[];
    for (final entry in _events.entries) {
      final day = entry.key;
      final dayStr = "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
      for (final t in entry.value) {
        all.add({"date": dayStr, "name": t});
      }
    }
    all.sort((a, b) => a["date"]!.compareTo(b["date"]!));
    return all;
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("authToken");
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Text("Error: $_error", style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    final allEvents = _getAllEvents();

    return Scaffold(
      body: Container(
        color: const Color(0xFFFFFBE6), 
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // The Calendar
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TableCalendar(
                    focusedDay: DateTime.now(),
                    firstDay: DateTime.utc(2020, 01, 01),
                    lastDay: DateTime.utc(2030, 12, 31),
                    eventLoader: _getEventsForDay,
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedEvents = _getEventsForDay(selectedDay);
                      });
                    },
                    calendarStyle: CalendarStyle(
                      todayDecoration: const BoxDecoration(
                        color: Color(0xFF347928),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: const BoxDecoration(
                        color: Color(0xFFFCCD2A),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFFC0EBA6),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      markerDecoration: const BoxDecoration(
                        color: Color(0xFFFCCD2A),
                        shape: BoxShape.circle,
                      ),
                      weekendTextStyle: GoogleFonts.lato(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                      todayTextStyle: GoogleFonts.lato(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      defaultTextStyle: GoogleFonts.lato(
                        color: const Color(0xFF347928),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleTextStyle: GoogleFonts.roboto(
                        color: const Color(0xFF347928),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      leftChevronIcon: const Icon(
                        Icons.arrow_back_ios,
                        color: Color(0xFF347928),
                      ),
                      rightChevronIcon: const Icon(
                        Icons.arrow_forward_ios,
                        color: Color(0xFF347928),
                      ),
                    ),
                    daysOfWeekStyle: DaysOfWeekStyle(
                      weekdayStyle: GoogleFonts.roboto(
                        color: const Color(0xFF347928),
                        fontWeight: FontWeight.w500,
                      ),
                      weekendStyle: GoogleFonts.roboto(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title for the full list
              Text(
                'All Election Dates',
                style: GoogleFonts.roboto(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF347928),
                ),
              ),
              const Divider(color: Color(0xFF347928)),

              Expanded(
                child: ListView.builder(
                  itemCount: allEvents.length,
                  itemBuilder: (context, index) {
                    final event = allEvents[index];
                    return ListTile(
                      leading: const Icon(
                        Icons.event,
                        color: Color(0xFFFCCD2A),
                      ),
                      title: Text(
                        event['name']!,
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF347928),
                        ),
                      ),
                      subtitle: Text(
                        event['date']!,
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF6B6B6B),
                        ),
                      ),
                    );
                  },
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
