import 'package:Wisensor/pages/map_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:Wisensor/modules/biomass_module.dart';
import 'package:Wisensor/modules/energy_module.dart';
import 'package:Wisensor/modules/iot_module.dart';
import 'package:Wisensor/modules/network_module.dart';
import 'package:Wisensor/modules/security_module.dart';
import 'package:Wisensor/pages/weather_page.dart';
import 'dart:convert';
import '../modules/setting_module.dart';
import 'custom_page_route.dart';
import 'login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  final int idu;

  HomePage({required this.idu});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> _centros = [];
  List<int> _alertCounts = [];
  bool _isLoading = true;
  String _message = "";
  List<int> markersWithAlerts = []; // Cambiado a List<int>
  List<int> markersWithAlerts2 = []; // Cambiado a List<int>

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
            title: Text('Cerrar Sesión'),
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

      return confirmLogout == true; // Si confirmLogout es true, permitir cerrar sesión
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
      Uri.parse("http://201.220.112.247:1880/wisensor/api/centros?idu=${widget.idu}"),
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
      var jsonResponse = jsonDecode(response.body);
      print(jsonResponse["message"]);
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

    // Obtener la cantidad de alertas para cada centro
    List<int> counts = [];
    for (var centro in _centros) {
      int ide = centro["ide"];
      int idu = centro["idu"];
      int idc = centro["idc"];

      http.Response response = await http.get(
        Uri.parse("http://201.220.112.247:1880/wisensor/api/centros/alertas?ide=$ide&idu=$idu&idc=$idc"),
        headers: headers,
      );

      if (response.statusCode == 200) {

        //print(";D");
        var jsonResponse = jsonDecode(response.body);
        print(jsonResponse["message"]);
        int count = jsonResponse["data"] != null ? jsonResponse["data"].length : 0;
        counts.add(count);
        // Imprimir la severidad de la alerta
        for (var alerta in jsonResponse["data"]) {
          //print("Severidad: ${alerta["severidad"]}");
          if(alerta["severidad"] == "Rojo"){
            //print("Centro $idc es Rojo ");
            setState(() {
              markersWithAlerts.add(idc); // Agregar el ID del centro a la lista
            });
          } else if(alerta["severidad"] == "Amarillo"){
            //print("Centro $idc es amarillo ");
            setState(() {
              markersWithAlerts2.add(idc); // Agregar el ID del centro a la lista
            });
          }
        }
        //_isLoading = false;
      } else {

        //print("IDE: $ide");
        //print("IDU: $idu");
        //print("IDC: $idc");
        var jsonResponse = jsonDecode(response.body);

        print(jsonResponse["message"]);

        counts.add(0); // Si hay un error, agregar cero alertas para el centro
      }
    }

    setState(() {
      _isLoading = false;
      _alertCounts = counts;
    });
  }

  // Método para manejar el cierre de sesión
  Future<void> _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    print("erroneo");
    prefs.remove("token");
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchCentros();
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
          title: Text('Alertas Generales', style: TextStyle(fontSize: 20.0)),
          centerTitle: true,
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              AppBar(
                title: const Text('Módulos'),
                leading: const BackButton(),
              ),
              ListTile(
                leading: const Icon(
                  FontAwesomeIcons.fish,
                ),
                title: const Text('Biomasa'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    CustomPageRoute(child: BiomassModule()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.sunny,
                ),
                title: const Text('Clima'),
                onTap: () {
                  Navigator.pop(context);
                  /*
                  Navigator.push(
                    context,
                    CustomPageRoute(child: WeatherModule()),
                  );
                   */
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.shield,
                ),
                title: const Text('Seguridad'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    CustomPageRoute(child: SecurityModule()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.touch_app,
                ),
                title: const Text('IoT'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    CustomPageRoute(child: IotModule()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.battery_5_bar_rounded,
                ),
                title: const Text('Energía'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    CustomPageRoute(child: EnergyModule()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.network_wifi_outlined,
                ),
                title: const Text('Estado de Red'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    CustomPageRoute(child: NetworkModule()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.travel_explore,
                ),
                title: const Text('Mapa'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MapPage(idu: widget.idu),
                    ),
                  );
                },
              ),
              Divider(),
              ListTile(
                leading: const Icon(
                  Icons.settings,
                ),
                title: const Text('Configuraciones'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    CustomPageRoute(child: SettingModule()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.directions_run,
                ),
                title: const Text('Cerrar Sesión'),
                onTap: () {
                  _logout(context);
                },
              ),
              const SizedBox(height: 150.0),
              Container(
                margin: EdgeInsets.fromLTRB(85, 60, 0, 0),
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
                margin: const EdgeInsets.fromLTRB(90, 0, 0, 0),
                child: const Text(
                  'V 1.0',
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

                        final hasRedAlert= markersWithAlerts.contains(_centros[index]['idc']);
                        final hasYellowAlert = markersWithAlerts2.contains(_centros[index]['idc']);

                        return Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: hasRedAlert
                                    ? Colors.red.withOpacity(0.7)
                                    : hasYellowAlert
                                    ? Colors.yellow[600]!.withOpacity(0.8)
                                    : Colors.green[600]!.withOpacity(0.8),
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
                                      child: WeatherPage(
                                        ide: _centros[index]["ide"],
                                        idu: _centros[index]["idu"],
                                        idc: _centros[index]["idc"],
                                        nombreCentro: _centros[index]["nombre"], // Pasar el nombre del centro
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
                                          color: hasRedAlert ? Colors.blueAccent[100] : hasYellowAlert ? Colors.black : Colors.white,
                                        ),
                                        Positioned(
                                          top: 0,
                                          right: 0,
                                          child: Container(
                                            padding: EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              color: hasYellowAlert ? Colors.red : Colors.black54,
                                              shape: BoxShape.circle,
                                            ),
                                            constraints: BoxConstraints(
                                              minWidth: 18,
                                              minHeight: 18,
                                            ),
                                            child: Text(
                                              _alertCounts.length > index ? '${_alertCounts[index]}' : '0',
                                              style: TextStyle(
                                                color: hasYellowAlert ? Colors.grey[300] : Colors.grey[300],
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
