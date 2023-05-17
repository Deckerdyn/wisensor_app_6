import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../global_data.dart';
import 'login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WeatherPage extends StatefulWidget {
  final int idu;
  final int idc;

  WeatherPage({required this.idu, required this.idc});

  @override
  _WeatherPageState createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  List<dynamic> _alerts = [];
  bool _isLoading = true;
  String _message = "";

  FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Timer? _timer;


  IconData parseIconData(String icon) {
    switch (icon) {
      case "<i class=\"fab fa-creative-commons-sa\"></i>":
        return FontAwesomeIcons.creativeCommonsSa;
      case "<i class=\"fas fa-arrows-alt-h\"></i>":
        return FontAwesomeIcons.arrowsAltH;
      case "<i class=\"fas fa-compass\"></i>":
        return FontAwesomeIcons.compass;
      case "<i class=\"fas fa-thermometer-quarter\"></i>":
        return FontAwesomeIcons.thermometerQuarter;
      case "<i class=\"fas fa-map-marked-alt\"></i>":
        return FontAwesomeIcons.mapMarkedAlt;
      default:
        return FontAwesomeIcons.question;
    }
  }

  Future<void> _fetchAlerts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    Map<String, String> headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer $token"
    };
    Future<void> _showNotification(Map<String, dynamic> alert) async {
      var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'channel_id',
        'channel_name',
        //'channel_description',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
        styleInformation: BigTextStyleInformation(
          alert['valor_encontrado'],
          htmlFormatContent: true,
          htmlFormatTitle: true,
          summaryText: alert['centro'],
        ),
      );
      //var iOSPlatformChannelSpecifics = IOSNotificationDetails();
      var platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        //iOS: iOSPlatformChannelSpecifics,
      );
      await _flutterLocalNotificationsPlugin.show(
        0,
        alert['variable'],
        alert['valor_encontrado'],
        platformChannelSpecifics,
        payload: alert['fecha'],
      );
    }

    http.Response response = await http.get(
      Uri.parse(
          "https://wisensor.cl/api/app/centro/alertas/clima?idu=${widget
              .idu}&idc=${widget.idc}"),
      headers: headers,
    );

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      setState(() {
        _alerts = jsonResponse["data"];
        _isLoading = false;
        _message = jsonResponse["message"];
      });
      for (var alert in _alerts) {
        _showNotification(alert);
      }
    } else {
      var errorResponse = jsonDecode(response.body);
      if (errorResponse.containsKey("message")) {
        var errorMessage = errorResponse["message"];
        if (errorMessage == "Unauthenticated.") {
          prefs.remove("token");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginPage()),
          );
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchAlerts();
    var initializationSettingsAndroid =
    AndroidInitializationSettings('app_icon');
    var initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
    );

    // Configure the timer to fetch alerts every msecondsinute
    _timer = Timer.periodic(Duration(minutes: 1), (timer) {
      _fetchAlerts();
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer to avoid memory leaks
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Alertas de Clima', style: TextStyle(fontSize: 20.0)),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Stack(
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/fondo_olas.PNG"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Color.fromRGBO(0, 0, 0, 0.5),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _message,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18.0,
                  ),
                ),
              ),
              Divider(
                height: 1,
                color: Colors.grey,
                thickness: 1,
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _alerts.length,
                  itemBuilder: (BuildContext context, int index) {
                    String iconDataString = _alerts[index]["icon"];
                    IconData iconData = parseIconData(iconDataString);
                    return Column(
                      children: [
                        ListTile(
                          title: Text(
                            _alerts[index]["variable"],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 21.0,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(
                                    fontSize: 20.0, color: Colors.white),
                                children: [
                                  TextSpan(
                                    text: 'Valor: ',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18
                                    ),
                                  ),
                                  TextSpan(
                                      text: '${_alerts[index]["valor_encontrado"]}\n',
                                      style: TextStyle(fontSize: 16)
                                  ),
                                  TextSpan(
                                    text: 'Fecha: ',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18
                                    ),
                                  ),
                                  TextSpan(
                                      text: '${_alerts[index]["fecha"]}',
                                      style: TextStyle(fontSize: 16)
                                  ),
                                ],
                              ),
                            ),
                          ),
                          trailing: Padding(
                            padding: const EdgeInsets.fromLTRB(8, 15, 8, 8),
                            child: Icon(
                              iconData,
                              color: _alerts[index]["severidad"] == "Rojo"
                                  ? Colors.red
                                  : _alerts[index]["severidad"] == "Amarillo"
                                  ? Colors.amber
                                  : Colors.green,
                              size: 26,
                            ),
                          ),
                        ),
                        Divider(height: 1, color: Colors.grey),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}