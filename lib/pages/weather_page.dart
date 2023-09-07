import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WeatherPage extends StatefulWidget {
  final int ide;
  final int idu;
  final int idc;
  final String nombreCentro; // Agregar el nuevo parámetro

  WeatherPage({required this.ide,required this.idu, required this.idc,
    required this.nombreCentro,});

  @override
  _WeatherPageState createState() => _WeatherPageState();
}

String parseDate(String inputDate) {
  List<String> parts = inputDate.split(' ');
  List<String> dateParts = parts[0].split('-');
  List<String> timeParts = parts[1].split(':');
  String formattedDate = '${dateParts[2]}-${dateParts[1]}-${dateParts[0]} ${timeParts[0]}:${timeParts[1]}';
  return formattedDate;
}

class _WeatherPageState extends State<WeatherPage> {
  List<dynamic> _alerts = [];
  bool _isLoading = true;
  String _message = "";
  //Timer? _timer;
  Map<String, double> _weatherValues = {}; // Mapa para almacenar valores de clima por alerta


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
    http.Response response = await http.get(
      Uri.parse(
          "http://201.220.112.247:1880/wisensor/api/centros/alertas?ide=${widget
              .ide}&idu=${widget
              .idu}&idc=${widget.idc}"),
      headers: headers,
    );
    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      setState(() {
        _alerts = jsonResponse["data"];
        //_isLoading = false;
        _message = jsonResponse["message"];
/*
        if (_alerts.isNotEmpty) {
          _nombreCentro = _alerts[0]["nombre_centro"];
        }

 */
      });

      // Obtener la cantidad de alertas para cada centro
      await _fetchWeather();
    } else if(response.statusCode == 401){
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
    await _fetchWeather();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchWeather() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    Map<String, String> headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer $token"
    };

    for (int index = 0; index < _alerts.length; index++) {
      var weather = _alerts[index];
      String cli = weather["clima_id"];
      String emp = weather["codigo_empresa"];
      String cce = weather["codigo_centro"];
      String nr = weather["nombre_real"];
      String dref = weather["mongodb"];
      double lat = weather["latitud"];
      double lng = weather["longitud"];
      dynamic hdi = weather["heading_inicial"]; // Usar dynamic en lugar de double

      String key = "${emp}_${cce}_${cli}_${nr}_${dref}_${lat}_${lng}_${hdi}";

      http.Response response = await http.get(
        Uri.parse("http://201.220.112.247:1880/wisensor/api/centros/alertas/clima?cli=$cli&emp=$emp&cce=$cce&nr=$nr&dref=$dref&lat=$lat&lng=$lng&hdi=$hdi"),
        headers: headers,
      );

      if (response.statusCode == 200) {
        _isLoading = false;
        var jsonResponse = jsonDecode(response.body);
        dynamic weatherValue = jsonResponse["data"]["valor"];

        // Convertir a double si es un entero
        if (weatherValue is int) {
          weatherValue = weatherValue.toDouble();
        }

        _weatherValues[key] = weatherValue;
      } else {
        var errorResponse = jsonDecode(response.body);
        setState(() {
          _isLoading = false;
          _message = errorResponse["message"];
        });
      }
    }

    setState(() {
      _isLoading = false;
    });
  }




  @override
  void initState() {
    super.initState();
    _fetchAlerts();
    /*
    // Configure the timer to fetch alerts every msecondsinute
    _timer = Timer.periodic(Duration(minutes: 1), (timer) {
      _fetchAlerts();
    });
    */
  }

  @override
  void dispose() {
    //_timer?.cancel(); // Cancel the timer to avoid memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Alertas de Clima - ${widget.nombreCentro}',
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
                      _alerts.sort((a, b) {
                        DateTime dateA = DateTime.parse(parseDate(a["fecha"]));
                        DateTime dateB = DateTime.parse(parseDate(b["fecha"]));
                        return dateB.compareTo(dateA); // Reversed order for descending
                      });

                      //int index = _alerts.length - index - 1; // Calcula el índice invertido
                      String iconDataString = _alerts[index]["icono"];
                      IconData iconData = parseIconData(iconDataString);
                      //String iconDataString = _alerts[index]["icono"];
                      //IconData iconData = parseIconData(iconDataString);
                      return Column(
                        children: [
                          ListTile(
                            title: Text(
                              _alerts[index]["nombre_visible"],
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
                                          '${_alerts[index]["fecha"]}',
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
                                        TextSpan(
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                          text: _weatherValues[
                                          "${_alerts[index]["codigo_empresa"]}_${_alerts[index]["codigo_centro"]}_${_alerts[index]["clima_id"]}_${_alerts[index]["nombre_real"]}_${_alerts[index]["mongodb"]}_${_alerts[index]["latitud"]}_${_alerts[index]["longitud"]}_${_alerts[index]["heading_inicial"]}"
                                          ] != null
                                              ? _weatherValues[
                                          "${_alerts[index]["codigo_empresa"]}_${_alerts[index]["codigo_centro"]}_${_alerts[index]["clima_id"]}_${_alerts[index]["nombre_real"]}_${_alerts[index]["mongodb"]}_${_alerts[index]["latitud"]}_${_alerts[index]["longitud"]}_${_alerts[index]["heading_inicial"]}"
                                          ]!.toStringAsFixed(1)
                                              : 'N/A',
                                        ),


                                        TextSpan(
                                          text: '${_alerts[index]["simbolo"]}',
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
                                color: _alerts[index]["severidad"] ==
                                    "Rojo"
                                    ? Colors.red
                                    : _alerts[index]["severidad"] ==
                                    "Amarillo"
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
      ),
    );
  }

}