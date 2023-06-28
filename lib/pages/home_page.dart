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
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> _centros = [];
  bool _isLoading = true;
  String _message = "";

  // Método que maneja la acción de retroceso del botón físico o virtual de Android
  Future<bool> _onWillPop() async {
    // Verificar si hay una página anterior en la ruta del Navigator
    if (Navigator.of(context).canPop()) {
      return true; // Permitir retroceder si hay una página anterior
    } else {
      return false; // Deshabilitar el retroceso si no hay una página anterior
    }
  }

  Future<void> _fetchCentros() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    if (token == null) {
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
      Uri.parse("https://wisensor.cl/api/app/user/centros"),
      headers: headers,
    );

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      setState(() {
        _centros = jsonResponse["data"];
        _isLoading = false;
        _message = jsonResponse["message"];
      });
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

  Future<void> _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    if (token == null) {
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
    http.Response response = await http.post(
      Uri.parse("https://wisensor.cl/api/app/logout"),
      headers: headers,
    );
    if (response.statusCode == 200) {
      prefs.remove("token");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
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
    init();
    super.initState();
    _fetchCentros();
  }

  init() async{
    String deviceToken = await getDeviceToken();
    print("##### PRINT DEVICE TOKEN TO USE FOR PUSH NOTIFICATION #####");
    print(deviceToken);
    print("###########################################################");
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop, // Asignar el método _onWillPop como el controlador de retroceso
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
                title: const Text('Estación metereológica'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    CustomPageRoute(child: MapPage()),
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

        body: _isLoading
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
                Divider(height: 1, color: Colors.grey, thickness: 1,),
                Expanded(
                  child: ListView.builder(
                    itemCount: _centros.length,
                    itemBuilder: (BuildContext context, int index) {
                      bool isRed = 0 == 0; //cambia el color dependiendo de la severidad de la alerta
                      return Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isRed ? Colors.red : Colors.yellow, // Cambia el color del contorno a rojo si es true
                                width: 2.0, // Ajusta el ancho del contorno según tus preferencias
                              ),
                            ),
                            child: ListTile(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  CustomPageRoute(
                                    child: WeatherPage(
                                      idu: _centros[index]["idu"],
                                      idc: _centros[index]["idc"],
                                    ),
                                  ),
                                );
                              },
                              title: Text(
                                _centros[index]["nombre"],
                                style: TextStyle(
                                  fontSize: 21.0,
                                  fontWeight: FontWeight.bold,
                                  color: isRed ? Colors.red : Colors.yellow, // Cambia el color a rojo si es true
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      fontSize: 20.0,
                                      color: isRed ? Colors.red : Colors.yellow, // Cambia el color a rojo si es true
                                    ),
                                    children: [
                                      TextSpan(
                                        text: '09/06/2023 ',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
                                      ),
                                      TextSpan(text: '4.5°',style: TextStyle(fontSize: 17)),
                                      WidgetSpan(
                                        child: Icon(
                                          Icons.thermostat,
                                          size: 19,
                                          color: isRed ? Colors.red : Colors.yellow, // Cambia el color a rojo si es true
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              trailing: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: SizedBox(
                                  width: 40.0,
                                  height: 40.0,
                                  child: Icon(
                                    Icons.keyboard_arrow_right,
                                    color: isRed ? Colors.red : Colors.yellow, // Cambia el color a rojo si es true
                                    size: 60.0,
                                  ),
                                ),
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

  //get device token to use for push notification
  Future getDeviceToken() async {
    FirebaseMessaging _firebaseMessage = FirebaseMessaging.instance;
    String? deviceToken = await _firebaseMessage.getToken();
    return (deviceToken == null) ? "" : deviceToken;
  }
}