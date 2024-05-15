import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';  // Importar la biblioteca intl

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
  List<dynamic> _selectedEvents = [];
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
        DateTime date = DateTime.parse(alert["fecha"]);
        DateTime eventDate = DateTime(date.year, date.month, date.day);

        if (!events.containsKey(eventDate)) {
          events[eventDate] = [];
        }
        events[eventDate]!.add(alert);
      }

      setState(() {
        _events = events;
        _selectedEvents = _events[_selectedDay] ?? [];
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar los datos')),
      );
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
      final selectedEventsKey = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
      _selectedEvents = _events[selectedEventsKey] ?? [];
    });
  }

  String _formatTime(String dateString) {
    final dateTime = DateTime.parse(dateString);
    return DateFormat.Hm().format(dateTime); // Formato de hora y minutos
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Busqueda avanzada',
          style: TextStyle(fontSize: 20.0),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TableCalendar(
            locale: 'es_ES', // Establecer el idioma a español
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2024, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onFormatChanged: _onFormatChanged,
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            eventLoader: (day) {
              return _events[DateTime(day.year, day.month, day.day)] ?? [];
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekendStyle: TextStyle(color: Colors.red),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                final eventDate = DateTime(date.year, date.month, date.day);
                if (_events[eventDate] != null) {
                  return Positioned(
                    bottom: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      width: 8.0,
                      height: 8.0,
                    ),
                  );
                }
                return Container();
              },
            ),
            onDaySelected: _onDaySelected,
          ),
          const SizedBox(height: 50.0),
          Expanded(
            child: _selectedEvents.isNotEmpty
                ? ListView.builder(
              itemCount: _selectedEvents.length,
              itemBuilder: (context, index) {
                var event = _selectedEvents[index];
                return Card(
                  color: Colors.grey,
                  child: ListTile(
                    title: Text(
                      event["nombre_sensor"] ?? 'Sin título',
                      style: TextStyle(color: Colors.black),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Alerta Crítica",
                          style: TextStyle(color: Colors.black),
                        ),
                        Text(
                          "Motivo de revisión: ${event["motivo_revision"]}",
                          style: TextStyle(color: Colors.black),
                        ),
                        Text(
                          "Hora: ${_formatTime(event["fecha"])}",
                          style: TextStyle(color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
                : Center(
              child: Center(
                child: Text(
                  'No hubo alertas críticas este día',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.0, // Ajusta este valor según tus necesidades
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
