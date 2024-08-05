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
    // Actualiza los datos aquí
    await _fetchCentros();
    await _fetchAlertCounts();
    setState(() {
      _isLoading = false;
    });
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
    if (!_isMounted) return;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    int? idu = prefs.getInt("idu");

    if (token == null || idu == null) {
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

  Future<void> _fetchAlertCounts() async {
    if (!_isMounted) return;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    Map<String, String> headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer $token"
    };

    List<int> counts = [];
    List<String> updatedMarkersWithAlerts = [];
    List<String> updatedMarkersWithAlerts2 = [];

    for (var centro in _centros) {
      String emp = centro["codigo_empresa"];
      String dref = centro["mongodb"];
      String cce = centro["codigo_centro"];

      http.Response response2 = await http.get(
        Uri.parse("http://201.220.112.247:1880/wisensor/api/centros/alertas2?emp=$emp&dref=$dref&cce=$cce"),
        headers: headers,
      );
      // Verificar si ya se ha suscrito al tópico correspondiente
/*
      if (!idEmpresas.contains(centro["emp"])) {
        switch (emp) {
          case 006:
            print("CALETABAY...");
            FirebaseMessaging.instance.subscribeToTopic("CALETABAY");
            idEmpresas.add(006);
            break;
          default:
          // Manejar otros casos si es necesario
            print("no suscrito a nada...");
            break;
        }
      }
      */
      if (response2.statusCode == 200) {
        var jsonResponse = jsonDecode(response2.body);
        int count = jsonResponse["data"] != null ? jsonResponse["data"].length : 0;
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

    if (_isMounted) {
      setState(() {
        _isLoading = false;
        _alertCounts = counts;
        markersWithAlerts = updatedMarkersWithAlerts;
        markersWithAlerts2 = updatedMarkersWithAlerts2;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchCentros();

    _timer = Timer.periodic(Duration(seconds: 60), (timer) {
      _fetchCentros();
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
          title: Text('Alertas de Seguridad', style: TextStyle(fontSize: 20.0)),
          centerTitle: true,
          leading: canPop ? null : IconButton(
            icon: Icon(Icons.settings, color: Colors.white, size: 36),
            onPressed: () {
              //Navigator.pop(context);
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
                        final hasRedAlert = markersWithAlerts.contains(_centros[index]['codigo_centro']);
                        final hasYellowAlert = markersWithAlerts2.contains(_centros[index]['codigo_centro']);

                        return Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                gradient:  hasRedAlert
                                    ? LinearGradient(
                                  colors: [Colors.red.withOpacity(0.7), Colors.redAccent.withOpacity(0.7)],
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
                                  colors: [Colors.lightGreen.withOpacity(0.8), Colors.green.withOpacity(0.8)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
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
                                        emp: _centros[index]["codigo_empresa"],
                                        dref: _centros[index]["mongodb"],
                                        nombreCentro: _centros[index]["nombre"],
                                        cce: _centros[index]["codigo_centro"],
                                      ),
                                    ),
                                  );
                                },
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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

  Future getDeviceToken() async {
    FirebaseMessaging _firebaseMessage = FirebaseMessaging.instance;
    String? deviceToken = await _firebaseMessage.getToken();
    return (deviceToken == null) ? "" : deviceToken;
  }
}
