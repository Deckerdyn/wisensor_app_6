import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RailwaySearchPage extends StatefulWidget {
  final int idu;

  RailwaySearchPage({
    required this.idu,
  });

  @override
  _RailwaySearchPageState createState() => _RailwaySearchPageState();
}

class _RailwaySearchPageState extends State<RailwaySearchPage> {
  late CalendarFormat _calendarFormat;
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  Map<DateTime, List<dynamic>> _events = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _calendarFormat = CalendarFormat.month;
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _fetchAlerts();
  }

  Future<void> _fetchAlerts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    Map<String, String> headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer $token"
    };
    http.Response response = await http.get(
      Uri.parse(
          "http://201.220.112.247:1880/wisensor/api/efe/criticas?idu=${widget.idu}"),
      headers: headers,
    );

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      List<dynamic> alerts = jsonResponse["data"];

      Map<DateTime, List<dynamic>> events = {};

      for (var alert in alerts) {
        // Convertir la fecha en formato ISO 8601 a objeto DateTime
        DateTime date = DateTime.parse(alert["fecha"]);

        // Crear una nueva fecha sin la parte de la hora
        DateTime eventDate = DateTime(date.year, date.month, date.day);

        // Agregar el evento al mapa de eventos
        events[eventDate] = events[eventDate] ?? [];
        events[eventDate]!.add(alert);
      }

      setState(() {
        _events = events;
        _isLoading = false;
      });
    }
  }

  void _onFormatChanged(CalendarFormat format) {
    setState(() {
      _calendarFormat = format;
    });
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Alertas de Ferrocarril',
          style: TextStyle(fontSize: 20.0),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2024, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(_focusedDay, day);
            },

            onFormatChanged: _onFormatChanged,
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            eventLoader: (day) {
              return _events[day] ?? [];
            },
            calendarStyle: CalendarStyle(
              // Estilo del calendario
              todayDecoration: BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekendStyle: TextStyle(color: Colors.red),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false, // Oculta el botón de formato
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                final eventDate = DateTime(date.year, date.month, date.day);
                if (_events[eventDate] != null) {
                  return Container(
                    child: Positioned(
                      bottom: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        width: 8.0,
                        height: 8.0,
                      ),
                    ),
                  );
                }
                return Container(); // Devuelve un contenedor vacío si no hay eventos
              },

            ),
            onDaySelected: _onDaySelected,
          ),
        ],
      ),
    );
  }
}
