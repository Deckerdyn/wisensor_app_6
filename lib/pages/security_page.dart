import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:Wisensor/modules/security_module.dart';
import 'dart:convert';
import 'custom_page_route.dart';
import 'login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityPage extends StatefulWidget {
  final int idu;

  SecurityPage({required this.idu});

  @override
  _SecurityPageState createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  Set<String> subscribedTopics = Set<String>();
  List<int> idEmpresas = [];
  List<dynamic> _centros = [];
  List<int> _alertCounts = [];
  bool _isLoading = true;
  String _message = "";
  List<String> markersWithAlerts = []; // Cambiado a List<String>
  List<String> markersWithAlerts2 = []; // Cambiado a List<String>
  Timer? _timer;

  Future<void> _handleRefresh() async {
    // Actualiza los datos aquí
    await _fetchCentros();
    await _fetchAlertCounts();
    setState(() {
      _isLoading = false;
    });
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

  Future<void> _fetchCentros() async {
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
          "http://201.220.112.247:1880/wisensor/api/centros?idu=${widget.idu}"),
      headers: headers,
    );

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      setState(() {
        _centros = jsonResponse["data"];
        //_isLoading = false;
        _message = jsonResponse["message"];
        //print(_centros);
      });

      // Obtener la cantidad de alertas para cada centro
      await _fetchAlertCounts();
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

  Future<void> _fetchAlertCounts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    Map<String, String> headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer $token"
    };

    List<int> counts = [];
    List<String> updatedMarkersWithAlerts =
        []; // Nueva lista para IDs de centros con alertas "Rojo"
    List<String> updatedMarkersWithAlerts2 =
        []; // Nueva lista para IDs de centros con alertas "Amarillo"

    for (var centro in _centros) {
      String emp = centro["codigo_empresa"];
      //String nce = centro["nombre"];
      String dref = centro["mongodb"];
      String cce = centro["codigo_centro"];

      http.Response response2 = await http.get(
        Uri.parse(
            "http://201.220.112.247:1880/wisensor/api/centros/alertas2?emp=$emp&dref=$dref&cce=$cce"),
        headers: headers,
      );

      if (response2.statusCode == 200) {
        var jsonResponse = jsonDecode(response2.body);
        int count =
            jsonResponse["data"] != null ? jsonResponse["data"].length : 0;
        counts.add(count);

        for (var alerta in jsonResponse["data"]) {
          if (alerta["modulo"] != null || alerta["zona"] == "INTERIOR" || alerta["zona"] == "INTERIOR100" || alerta["zona"] == "INTERIOR200") {
            updatedMarkersWithAlerts.add(cce);
          } else if (alerta["zona"] != null && (alerta["zona"] == "EXTERIOR" || alerta["zona"] == "EXTERIOR100" || alerta["zona"] == "EXTERIOR200")) {
            updatedMarkersWithAlerts2.add(cce);
          }
        }
      } else {
        counts.add(0);
      }
    }

    setState(() {
      _isLoading = false;
      _alertCounts = counts;
      markersWithAlerts =
          updatedMarkersWithAlerts; // Actualizar la lista de IDs con alertas "Rojo"
      markersWithAlerts2 =
          updatedMarkersWithAlerts2; // Actualizar la lista de IDs con alertas "Amarillo"
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchCentros();

    // Configure the timer to fetch alerts every msecondsinute
    _timer = Timer.periodic(Duration(seconds: 60), (timer) {
      _fetchCentros();
      _fetchAlertCounts();
    });
    // Llama a la función para obtener el token del dispositivo al iniciar la página
    init();
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer to avoid memory leaks
    super.dispose();
  }

  init() async {
    String deviceToken = await getDeviceToken();
    print("##### PRINT DEVICE TOKEN TO USE FOR PUSH NOTIFICATION #####");
    print(deviceToken);
    print("###########################################################");
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Alertas de Seguridad', style: TextStyle(fontSize: 20.0)),
          centerTitle: true,
        ),
        body: RefreshIndicator(
          onRefresh: _handleRefresh,
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : Stack(
                  children: [
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
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            _message,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18.0,
                              color: Colors.white,
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
                            itemCount: _centros.length,
                            itemBuilder: (BuildContext context, int index) {
                              //bool isRed = _alertCounts[index] > 0;

                              final hasRedAlert = markersWithAlerts
                                  .contains(_centros[index]['codigo_centro']);
                              final hasYellowAlert = markersWithAlerts2
                                  .contains(_centros[index]['codigo_centro']);

                              return Column(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: hasRedAlert
                                          ? Colors.red.withOpacity(0.7)
                                          : hasYellowAlert
                                              ? Colors.yellow[600]!
                                                  .withOpacity(0.8)
                                              : Colors.green[600]!
                                                  .withOpacity(0.8),
                                      border: Border.all(
                                        color: Colors.black,
                                        width: 2.0,
                                      ),
                                    ),
                                    child: ListTile(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          CustomPageRoute(
                                            child: SecurityModule(
                                              emp: _centros[index]
                                                  ["codigo_empresa"],
                                              dref: _centros[index]["mongodb"],
                                              nombreCentro: _centros[index]
                                                  ["nombre"],
                                              cce: _centros[index]
                                                  ["codigo_centro"],
                                            ),
                                          ),
                                        );
                                      },
                                      title: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                _centros[index]["nombre"],
                                                style: TextStyle(
                                                  fontSize: 21.0,
                                                  fontWeight: FontWeight.w500,
                                                  color: hasRedAlert
                                                      ? Colors.grey[200]
                                                      : hasYellowAlert
                                                          ? Colors.black87
                                                          : Colors.grey[200],
                                                ),
                                              ),
                                            ],
                                          ),
                                          Stack(
                                            children: [
                                              Icon(
                                                Icons.directions_boat,
                                                size: 30.0,
                                                color: hasRedAlert
                                                    ? Colors.black54
                                                    : hasYellowAlert
                                                        ? Colors.black
                                                        : Colors.white70,
                                              ),
                                              Positioned(
                                                top: 0,
                                                right: 0,
                                                child: Container(
                                                  padding: EdgeInsets.all(2),
                                                  decoration: BoxDecoration(
                                                    color: hasRedAlert ||
                                                            hasYellowAlert
                                                        ? Colors.red
                                                        : Colors.black54,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  constraints: BoxConstraints(
                                                    minWidth: 18,
                                                    minHeight: 18,
                                                  ),
                                                  child: Text(
                                                    _alertCounts.length > index
                                                        ? '${_alertCounts[index]}'
                                                        : '0',
                                                    style: TextStyle(
                                                      color: hasYellowAlert
                                                          ? Colors.white
                                                          : Colors.white,
                                                      fontSize: 12,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
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

  //get device token to use for push notification
  Future getDeviceToken() async {
    FirebaseMessaging _firebaseMessage = FirebaseMessaging.instance;
    String? deviceToken = await _firebaseMessage.getToken();
    return (deviceToken == null) ? "" : deviceToken;
  }
}
