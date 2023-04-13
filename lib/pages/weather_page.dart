import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../global_data.dart';
import 'login_page.dart';

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

  IconData getIcon(String iconStr) {
    switch (iconStr) {
      case "<i class=\"fas fa-compass\"></i>":
        return Icons.compass_calibration;
      case "<i class=\"fas fa-thermometer-quarter\"></i>":
        return Icons.thermostat;
      case "<i class=\"fas fa-arrows-alt-h\"></i>":
        return Icons.swap_horizontal_circle;
      case "<i class=\"fab fa-creative-commons-sa\"></i>":
        return Icons.directions_boat;
      case "<i class=\"fas fa-map-marked-alt\"></i>":
        return Icons.location_on;
      default:
        return Icons.error;
    }
  }

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
    Map<String, String> headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer ${GlobalData.token}"
    };

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
    } else {
      var errorResponse = jsonDecode(response.body);
      if (errorResponse.containsKey("message")) {
        var errorMessage = errorResponse["message"];
        if (errorMessage == "Unauthenticated.") {
          GlobalData.token = "";
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