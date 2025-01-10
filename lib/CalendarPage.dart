import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:google_fonts/google_fonts.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final Map<DateTime, List<String>> _events = {
    DateTime(2024, 1, 23): ['Presidential Primary'],
    DateTime(2024, 2, 18): ['Local City Council Elections'],
    DateTime(2024, 3, 9): ['State Governor Elections'],
    DateTime(2024, 4, 22): ['Mid-Year Senate Elections'],
    DateTime(2024, 5, 15): ['Mayoral Elections'],
    DateTime(2024, 6, 30): ['Regional Referendum Vote'],
    DateTime(2024, 8, 14): ['Education Board Elections'],
    DateTime(2024, 9, 12): ['General Parliamentary Elections'],
    DateTime(2024, 10, 6): ['Local Mayor Runoff'],
    DateTime(2024, 12, 1): ['End-of-Year Special Election'],
  };

  List<String> _selectedEvents = [];

  @override
  void initState() {
    super.initState();
    _selectedEvents = _getEventsForDay(DateTime.now());
  }

  List<String> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  List<Map<String, String>> _getAllEvents() {
    return _events.entries.map((entry) {
      final date = entry.key.toLocal().toString().split(' ')[0];
      final name = entry.value.join(', ');
      return {'date': date, 'name': name};
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final allEvents = _getAllEvents();

    return Scaffold(
      body: Container(
        color: const Color(0xFFFFFBE6), // Background color
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    lastDay: DateTime.utc(2025, 12, 31),
                    eventLoader: _getEventsForDay,
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedEvents = _getEventsForDay(selectedDay);
                      });
                    },
                    calendarStyle: CalendarStyle(
                      todayDecoration: const BoxDecoration(
                        color: Color(0xFF347928), // Primary color
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: const BoxDecoration(
                        color: Color(0xFFFCCD2A), // Accent color
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFFC0EBA6), // Secondary color
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      markerDecoration: const BoxDecoration(
                        color: Color(0xFFFCCD2A), // Accent color
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
                        color: const Color(0xFF347928), // Primary color
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleTextStyle: GoogleFonts.roboto(
                        color: const Color(0xFF347928), // Primary color
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      leftChevronIcon: const Icon(
                        Icons.arrow_back_ios,
                        color: Color(0xFF347928), // Primary color
                      ),
                      rightChevronIcon: const Icon(
                        Icons.arrow_forward_ios,
                        color: Color(0xFF347928), // Primary color
                      ),
                    ),
                    daysOfWeekStyle: DaysOfWeekStyle(
                      weekdayStyle: GoogleFonts.roboto(
                        color: const Color(0xFF347928), // Primary color
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
              Text(
                'All Election Dates',
                style: GoogleFonts.roboto(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF347928), // Primary color
                ),
              ),
              const Divider(color: Color(0xFF347928)), // Primary color
              Expanded(
                child: ListView.builder(
                  itemCount: allEvents.length,
                  itemBuilder: (context, index) {
                    final event = allEvents[index];
                    return ListTile(
                      leading: const Icon(
                        Icons.event,
                        color: Color(0xFFFCCD2A), // Accent color
                      ),
                      title: Text(
                        event['name']!,
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF347928), // Primary color
                        ),
                      ),
                      subtitle: Text(
                        event['date']!,
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF6B6B6B), // Neutral gray
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
