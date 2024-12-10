import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:Wisensor/modules/security_module.dart';
import 'dart:convert';
import '../modules/setting_module.dart';
import 'custom_page_route.dart';
import 'login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

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
  List<String> markersWithAlerts = [];
  List<String> markersWithAlerts2 = [];
  Timer? _timer;
  bool _isMounted = true;

  Future<void> _handleRefresh() async {
    await _fetchAlertCounts();
    if (_isMounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove("token");
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  Future<void> _confirmLogout() async {
    bool confirmLogout = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Cerrar Sesión'),
          content: Text('¿Está seguro que desea cerrar sesión?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
                print("se ha desuscrito de GMT");
                FirebaseMessaging.instance.unsubscribeFromTopic("GMT");
                print("se ha desuscrito de MOWI");
                FirebaseMessaging.instance.unsubscribeFromTopic("MOWI");
                print("se ha desuscrito de AQUACHILE");
                FirebaseMessaging.instance.unsubscribeFromTopic("AQUACHILE");
                print("se ha desuscrito de SALMONESAUSTRAL");
                FirebaseMessaging.instance.unsubscribeFromTopic("SALMONESAUSTRAL");
                print("se ha desuscrito de CALETABAY...");
                FirebaseMessaging.instance.unsubscribeFromTopic("CALETABAY");
              },
              child: Text('Aceptar'),
            ),
          ],
        );
      },
    );

    if (confirmLogout) {
      await _logout(context);
    }
  }

  Future<bool> _onWillPop() async {
    if (Navigator.of(context).canPop()) {
      return true;
    } else {
      bool confirmLogout = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Cerrar Aplicación'),
            content: Text('¿Está seguro que desea salir de la aplicación?'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                child: Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                child: Text('Aceptar'),
              ),
            ],
          );
        },
      );

      return confirmLogout == true;
    }
  }

  Future<void> _fetchCentros() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    if (token == null) {
      _logout(context);
      return;
    }

    Map<String, String> headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer $token"
    };

    http.Response response = await http.get(
      Uri.parse("http://201.220.112.247:1880/wisensor/api/centros?idu=${widget.idu}"),
      headers: headers,
    );

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      if (_isMounted) {
        setState(() {
          _centros = jsonResponse["data"];
          _message = jsonResponse["message"];
        });
        await _fetchAlertCounts();

        // Ordenar la lista _centros colocando primero los que tienen alertas
        _centros.sort((a, b) {
          bool aHasAlert = markersWithAlerts.contains(a['codigo_centro']) || markersWithAlerts2.contains(a['codigo_centro']);
          bool bHasAlert = markersWithAlerts.contains(b['codigo_centro']) || markersWithAlerts2.contains(b['codigo_centro']);
          if (aHasAlert && !bHasAlert) return -1;
          if (!aHasAlert && bHasAlert) return 1;
          return 0;
        });
      }
    } else {
      await _handleErrorResponse(response);
    }
  }


  Future<void> _handleErrorResponse(http.Response response) async {
    var errorResponse = jsonDecode(response.body);
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (errorResponse.containsKey("message")) {
      var errorMessage = errorResponse["message"];
      if (errorMessage == "Unauthenticated.") {
        prefs.remove("token");
        _logout(context);
      }
    }
  }

  Future<void> _fetchAlertCounts() async {
    if (!_isMounted) return;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    Map<String, String> headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer $token"
    };

    List<Future<void>> futures = [];

    for (var centro in _centros) {
      String emp = centro["codigo_empresa"];
      String dref = centro["mongodb"];
      String cce = centro["codigo_centro"];

      futures.add(
        http
            .get(
          Uri.parse(
              "http://201.220.112.247:1880/wisensor/api/centros/alertas2?emp=$emp&dref=$dref&cce=$cce"),
          headers: headers,
        )
            .then((response2) {
          if (response2.statusCode == 200) {
            var jsonResponse = jsonDecode(response2.body);
            int count = jsonResponse["data"]?.length ?? 0;

            if (_isMounted) {
              setState(() {
                centro["alert_count"] = count;

                if (jsonResponse["data"].any((alerta) =>
                alerta["modulo"] != null ||
                    alerta["zona"] == "INTERIOR" ||
                    alerta["zona"] == "INTERIOR100" ||
                    alerta["zona"] == "INTERIOR200")) {
                  markersWithAlerts.add(cce);
                } else if (jsonResponse["data"].any((alerta) =>
                alerta["zona"] == "EXTERIOR" ||
                    alerta["zona"] == "EXTERIOR100" ||
                    alerta["zona"] == "EXTERIOR200")) {
                  markersWithAlerts2.add(cce);
                }
              });
            }
          } else {
            // Manejar errores de estado HTTP
            print("Error en la solicitud para $cce: ${response2.statusCode}");
          }
        }).catchError((e) {
          // Manejar excepciones de red
          print("Excepción para $cce: $e");
        }),
      );

    }

    // Esperar que todas las solicitudes finalicen
    await Future.wait(futures);

    if (_isMounted) {
      setState(() {
        _isLoading = false;

        // Ordenar centros con alertas primero
        _centros.sort((a, b) {
          bool aHasAlert = markersWithAlerts.contains(a['codigo_centro']) || markersWithAlerts2.contains(a['codigo_centro']);
          bool bHasAlert = markersWithAlerts.contains(b['codigo_centro']) || markersWithAlerts2.contains(b['codigo_centro']);
          if (aHasAlert && !bHasAlert) return -1;
          if (!aHasAlert && bHasAlert) return 1;
          return 0;
        });
      });
    }
  }



  @override
  void initState() {
    super.initState();
    _fetchCentros();

    _timer = Timer.periodic(Duration(minutes: 2), (timer) {
      //_fetchCentros();
      _isMounted = true;
      _fetchAlertCounts();
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
    bool canPop = Navigator.of(context).canPop();

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Alertas de Seguridad',
            style: TextStyle(
              fontSize: 20.0,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          leading: canPop
              ? null
              : IconButton(
            icon: Icon(Icons.settings, color: Colors.white, size: 36),
            onPressed: () {
              Navigator.push(
                context,
                CustomPageRoute(child: SettingModule()),
              );
            },
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.exit_to_app, color: Colors.white, size: 36),
              onPressed: () async {
                await _confirmLogout();
              },
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _handleRefresh,
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : Stack(
            children: [
              // Fondo
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
                  color: Color.fromRGBO(0, 0, 0, 0.3), // Fondo con menos opacidad
                ),
              ),
              AnimationLimiter(
                child: ListView.builder(
                  itemCount: _centros.length,
                  itemBuilder: (context, index) {
                    final hasRedAlert = markersWithAlerts.contains(
                      _centros[index]['codigo_centro'],
                    );
                    final hasYellowAlert = markersWithAlerts2.contains(
                      _centros[index]['codigo_centro'],
                    );

                    // Gradiente personalizado
                    final gradient = hasRedAlert
                        ? LinearGradient(
                      colors: [
                        Colors.red.shade700,
                        Colors.red.shade400,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                        : hasYellowAlert
                        ? LinearGradient(
                      colors: [
                        Colors.amber.shade700,
                        Colors.amber.shade400,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                        : LinearGradient(
                      colors: [
                        Colors.green.shade700,
                        Colors.green.shade400,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    );

                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 500),
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                            child: Material(
                              color: Colors.transparent, // Permite ver el gradiente debajo
                              child: Ink(
                                decoration: BoxDecoration(
                                  gradient: hasRedAlert
                                      ? LinearGradient(
                                    colors: [
                                      Colors.red.withOpacity(0.7),
                                      Colors.redAccent.withOpacity(0.7)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                      : hasYellowAlert
                                      ? LinearGradient(
                                    colors: [
                                      Colors.yellow.withOpacity(0.8),
                                      Colors.amber.withOpacity(0.8)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                      : LinearGradient(
                                    colors: [
                                      Colors.lightGreen.withOpacity(0.8),
                                      Colors.green.withOpacity(0.8)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12.0),
                                  border: Border.all(color: Colors.black, width: 2.0),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12.0),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      CustomPageRoute(
                                        child: SecurityModule(
                                          emp: _centros[index]["codigo_empresa"],
                                          dref: _centros[index]["mongodb"],
                                          nombreCentro: _centros[index]["nombre"],
                                          cce: _centros[index]["codigo_centro"],
                                        ),
                                      ),
                                    );
                                  },
                                  splashColor: Colors.blue.withOpacity(0.3),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: hasRedAlert
                                          ? Colors.red
                                          : hasYellowAlert
                                          ? Colors.orange
                                          : Colors.green,
                                      child: Icon(
                                        Icons.warning,
                                        color: Colors.white,
                                      ),
                                    ),
                                    title: Text(
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
                                    trailing: Stack(
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
                                              color: hasRedAlert || hasYellowAlert
                                                  ? Colors.red
                                                  : Colors.black54,
                                              shape: BoxShape.circle,
                                            ),
                                            constraints: BoxConstraints(
                                              minWidth: 18,
                                              minHeight: 18,
                                            ),
                                            child: Text(
                                              '${_centros[index]["alert_count"] ?? 0}',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                          ),
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




  Future getDeviceToken() async {
    FirebaseMessaging _firebaseMessage = FirebaseMessaging.instance;
    String? deviceToken = await _firebaseMessage.getToken();
    return (deviceToken == null) ? "" : deviceToken;
  }
}