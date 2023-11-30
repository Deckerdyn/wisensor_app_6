import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
//import 'login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../pages/login_page.dart';

class SecurityModule extends StatefulWidget {
  //final int ide;
  //final int idu;
  //final int idc;
  //final String nombreCentro; // Agregar el nuevo parámetro
  final String emp;
  final String cce;
  final String dref;
  final String nombreCentro; // Agregar el nuevo parámetro

  SecurityModule({required this.emp,required this.cce, required this.dref,required this.nombreCentro,
    });

  @override
  _SecurityModuleState createState() => _SecurityModuleState();
}
/*
String parseDate(String inputDate) {
  List<String> parts = inputDate.split(' ');
  List<String> dateParts = parts[0].split('-');
  List<String> timeParts = parts[1].split(':');
  String formattedDate = '${dateParts[2]}-${dateParts[1]}-${dateParts[0]} ${timeParts[0]}:${timeParts[1]}';
  return formattedDate;
}
*/
class _SecurityModuleState extends State<SecurityModule> {
  List<dynamic> _alerts = [];
  bool _isLoading = true;
  String _message = "";
  Timer? _timer;
  Map<String, double> _weatherValues = {}; // Mapa para almacenar valores de clima por alerta


  IconData parseIconData(String clasificacion) {
    switch (clasificacion) {
      case "person":
        return Icons.nordic_walking;
      case "boatMedium":
        return FontAwesomeIcons.ship;
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
    http.Response response = await http.get(
      Uri.parse(
          "http://201.220.112.247:1880/wisensor/api/centros/alertas2?emp=${widget
              .emp}&cce=${widget
              .cce}&dref=${widget.dref}"),
      headers: headers,
    );
    if (response.statusCode == 200) {
      print("si");
      var jsonResponse = jsonDecode(response.body);
      setState(() {
        _alerts = jsonResponse["data"];
        _isLoading = false;
        _message = jsonResponse["message"];
/*
        if (_alerts.isNotEmpty) {
          _nombreCentro = _alerts[0]["nombre_centro"];
        }

 */
      });


    } else if(response.statusCode == 401){
      print("no");
      var errorResponse = jsonDecode(response.body);
      setState(() {
        _isLoading = false;
        _message = errorResponse["message"];

      });
    }
    else {
      //print(_message);
      //print("NOOOO");
      //print(response.statusCode);
      var errorResponse = jsonDecode(response.body);
      if (errorResponse.containsKey("message")) {
        //print(errorResponse);
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

  Future<void> _handleRefresh() async {


    await _fetchAlerts();

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchAlerts();

    // Configure the timer to fetch alerts every msecondsinute
    _timer = Timer.periodic(Duration(seconds: 30), (timer) {
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
        title: Text(
          'Alertas de Seguridad - ${widget.nombreCentro}',
          style: TextStyle(fontSize: 20.0),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: _isLoading
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

                      //int index = _alerts.length - index - 1; // Calcula el índice invertido
                      String iconDataString = _alerts[index]["clasificacion"];
                      IconData iconData = parseIconData(iconDataString);
                      //String iconDataString = _alerts[index]["icono"];
                      //IconData iconData = parseIconData(iconDataString);
                      return Column(
                        children: [
                          ListTile(
                            title: Text(
                              _alerts[index]["clasificacion"] == "person" ? "Persona" : "Embarcación",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 21.0,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Row(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      style: TextStyle(
                                        fontSize: 20.0,
                                        color: Colors.white,
                                      ),
                                      children: [
                                        TextSpan(
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                        TextSpan(
                                          text:
                                          '${_alerts[index]["fecha"] + " "}',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                        TextSpan(
                                          text:
                                          '${_alerts[index]["hora"]}',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  RichText(
                                    text: TextSpan(
                                      style: TextStyle(
                                        fontSize: 20.0,
                                        color: Colors.white,
                                      ),
                                      children: [
                                        if (_alerts[index]["zona"] != null)
                                          TextSpan(
                                            text: 'Zona ${_alerts[index]["zona"]}',
                                            style: TextStyle(fontSize: 16),
                                          ),
                                        if (_alerts[index]["zona"] != null && _alerts[index]["modulo"] != null)
                                          TextSpan(
                                            text: ' ',
                                            style: TextStyle(fontSize: 16),
                                          ),
                                        if (_alerts[index]["modulo"] != null)
                                          TextSpan(
                                            text: 'Modulo ${_alerts[index]["modulo"]}',
                                            style: TextStyle(fontSize: 16),
                                          ),
                                      ],
                                    ),
                                  ),



                                ],
                              ),
                            ),
                            trailing: Padding(
                              padding:
                              const EdgeInsets.fromLTRB(8, 15, 8, 8),
                              child: Icon(
                                iconData,
                                color: (_alerts[index]["modulo"] != null || _alerts[index]["zona"] == "INTERIOR")
                                    ? Colors.red
                                    : _alerts[index]["zona"] == "EXTERIOR"
                                    ? Colors.amber
                                    : Colors.orange,
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
      ),
    );
  }

}