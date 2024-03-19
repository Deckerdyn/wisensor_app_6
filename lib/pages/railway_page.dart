import 'dart:async';
import 'package:Wisensor/modules/railway_module.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class RailwayPage extends StatefulWidget {
  final int idu;

  RailwayPage({

    required this.idu,
  });

  @override
  _RailwayPageState createState() => _RailwayPageState();
}

String parseDate(String inputDate) {
  List<String> parts = inputDate.split(' ');
  List<String> dateParts = parts[0].split('-');
  List<String> timeParts = parts[1].split(':');
  String formattedDate =
      '${dateParts[2]}-${dateParts[1]}-${dateParts[0]} ${timeParts[0]}:${timeParts[1]}';
  return formattedDate;
}

class _RailwayPageState extends State<RailwayPage> {
  List<dynamic> _alerts = [];
  bool _isLoading = true;
  String _message = "";
  Timer? _timer;
  Map<String, double> _weatherValues =
      {}; // Mapa para almacenar valores de clima por alerta
  bool _isMounted = true; // Add this variable to track widget's mounting status

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
        return FontAwesomeIcons.train;
    }
  }
// Método que maneja la acción de retroceso del botón físico o virtual de Android
  Future<bool> _onWillPop() async {
    // Verificar si hay una página anterior en la ruta del Navigator
    if (Navigator.of(context).canPop()) {
      return true; // Permitir retroceder si hay una página anterior
    } else {
      // Mostrar un diálogo para confirmar si el usuario desea cerrar sesión
      bool confirmLogout = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Cerrar Aplicación'),
            content: Text('¿Estás seguro que deseas cerrar la aplicación?'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false); // No cerrar sesión
                },
                child: Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true); // Cerrar sesión
                },
                child: Text('Aceptar'),
              ),
            ],
          );
        },
      );

      return confirmLogout ==
          true; // Si confirmLogout es true, permitir cerrar sesión
    }
  }
  Future<void> _fetchAlerts() async {
    if (!_isMounted) return; // Check if the widget is still mounted
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    int? idu = prefs.getInt("idu");

    if (token == null || idu == null) {
      // El token no existe, el usuario no está autenticado
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
      return;
    }
    Map<String, String> headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer $token"
    };
    http.Response response = await http.get(
      Uri.parse(
          "http://201.220.112.247:1880/wisensor/api/efe?idu=${widget.idu}"),
      headers: headers,
    );
    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      if (_isMounted) {
        setState(() {
          _alerts = jsonResponse["data"];
          _isLoading = false;
          _message = jsonResponse["message"];
        });
      }

    } else if (response.statusCode == 401) {
      var errorResponse = jsonDecode(response.body);
      if (_isMounted) {
        setState(() {
          _isLoading = false;
          _message = errorResponse["message"];
        });
      }
    } else if (response.statusCode == 403) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => RailwayModule()),
      );
    } else {
      var errorResponse = jsonDecode(response.body);
      if (errorResponse.containsKey("message")) {
        //print(errorResponse);
        var errorMessage = errorResponse["message"];
        if (errorMessage == "Unauthenticated.") {
          //prefs.remove("token");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => RailwayModule()),
          );
        }
      }
    }
  }

  Future<void> _handleRefresh() async {
    await _fetchAlerts();
    if (_isMounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Método para manejar el cierre de sesión
  Future<void> _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    //prefs.remove("token");
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchAlerts();

    // Configure the timer to fetch alerts every 10 minutes
    _timer = Timer.periodic(Duration(minutes: 10), (timer) {
      _fetchAlerts();
    });
  }

  @override
  void dispose() {
    _isMounted = false; // Set to false when the widget is disposed
    _timer?.cancel(); // Cancel the timer to avoid memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Alertas de Ferrocarril',
            style: TextStyle(fontSize: 20.0),
          ),
          centerTitle: true,
          backgroundColor: Colors.blue,
        ),
        /*
        drawer: Drawer(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    AppBar(
                      title: const Text('Módulos'),
                      leading: const BackButton(),
                      backgroundColor: Colors.blue,
                    ),

                    // ... (otros elementos del Drawer)
                  ],
                ),
              ),
              Divider(),
              ListTile(
                leading: const Icon(
                  Icons.directions_run,
                ),
                title: const Text('Cerrar Sesión'),
                onTap: () {
                  _logout(context);
                },
              ),
              Container(
                margin: EdgeInsets.fromLTRB(0, 60, 0, 0),
                child: const Text(
                  'Wisensor',
                  style: TextStyle(
                    fontSize: 30.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(0, 0, 0, 20),
                child: const Text(
                  'V 1.2.2',
                  style: TextStyle(
                    fontSize: 10.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.start,
                ),
              ),
            ],
          ),
        ),
*/
        body: RefreshIndicator(
          onRefresh: _handleRefresh,
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : Stack(
                  children: <Widget>[
                    Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage("assets/images/xd.png"),
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
                              String iconDataString =
                                  _alerts[index]["nombre_sensor"];
                              IconData iconData = parseIconData(iconDataString);

                              // Obtener la fecha y hora en formato DateTime
                              DateTime utcDateTime =
                                  DateTime.parse(_alerts[index]["fecha"]);

                              // Ajustar la fecha y hora a la zona horaria de Chile (UTC-3)
                              DateTime chileDateTime =
                                  utcDateTime.subtract(Duration(hours: 3));

                              // Formatear la fecha y hora
                              String formattedDateTime = DateFormat.yMd()
                                  .add_Hms()
                                  .format(chileDateTime);

                              return Column(
                                children: [
                                  ListTile(
                                    title: Text(
                                      _alerts[index]["nombre_sensor"],
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
                                                  text: '$formattedDateTime',
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
                                              /*
                                        children: [
                                          TextSpan(
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                            text: "???"
                                          ),

                                        ],
                                        */
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
                                        color: _alerts[index]["tipo_alerta"] ==
                                                "critica"
                                            ? Colors.red
                                            : _alerts[index]["tipo_alerta"] ==
                                                    "atencion"
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
      ),
    );
  }
}
