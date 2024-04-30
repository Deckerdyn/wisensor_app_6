import 'dart:async';
import 'dart:convert';
import 'package:Wisensor/pages/railway_attention_page.dart';
import 'package:Wisensor/pages/railway_critic_page.dart';
import 'package:Wisensor/pages/railway_page.dart';
import 'package:Wisensor/pages/railway_search_page.dart';
import 'package:flutter/material.dart';
import '../modules/railway_module.dart';
import 'custom_page_route.dart';
import 'login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class RailwayHomePage extends StatefulWidget {
  final int idu;

  RailwayHomePage({
    required this.idu,
  });

  @override
  _RailwayHomePageState createState() => _RailwayHomePageState();
}

class _RailwayHomePageState extends State<RailwayHomePage> {
  Timer? _timer;
  List<dynamic> _alerts = [];
  bool _isLoading = true;
  String _message = "";
  //Timer? _timer;
  Map<String, double> _weatherValues =
  {}; // Mapa para almacenar valores de clima por alerta
  bool _isMounted = true; // Add this variable to track widget's mounting status

  // Método para manejar el cierre de sesión
  Future<void> _logout(BuildContext context) async {
    // Implementación del método _logout()
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove("token");
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchAlerts();
    // Configurar el temporizador para actualizar alertas cada 10 minutos
    _timer = Timer.periodic(Duration(minutes: 10), (timer) {
      // Lógica para actualizar alertas (no incluida en este código modificado)
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancelar el temporizador para evitar fugas de memoria
    super.dispose();
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
      if (_isMounted) {
        var jsonResponse = jsonDecode(response.body);
        setState(() {
          _alerts = jsonResponse["data"];
          _isLoading = false;
          _message = jsonResponse["message"];
        });
      }

    } else if (response.statusCode == 401) {
      if (_isMounted) {
        var errorResponse = jsonDecode(response.body);
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

  Widget _buildCenterButtons() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 0.0),
          SizedBox(
            width: 270,
            child: ElevatedButton.icon(
              onPressed: () {
                // Lógica para el primer botón
                Navigator.push(
                  context,
                  CustomPageRoute(child: RailwayPage(idu: widget.idu)),
                );
              },
              icon: Icon(Icons.notifications_active),
              label: Text(
                'Alertas activas',
                style: TextStyle(fontSize: 20),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.withOpacity(0.8),
                padding: EdgeInsets.symmetric(vertical: 20),
              ),
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            width: 270,
            child: ElevatedButton.icon(
              onPressed: () {
                // Lógica para el segundo botón
                Navigator.push(
                  context,
                  CustomPageRoute(child: RailwayCriticPage(idu: widget.idu)),
                );
              },
              icon: Icon(Icons.history),
              label: Text(
                'Histórico críticas',
                style: TextStyle(fontSize: 20),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.8),
                padding: EdgeInsets.symmetric(vertical: 20),
              ),
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            width: 270,
            child: ElevatedButton.icon(
              onPressed: () {
                // Lógica para el tercer botón
                Navigator.push(
                  context,
                  CustomPageRoute(child: RailwayAttentionPage(idu: widget.idu)),
                );
              },
              icon: Icon(Icons.history),
              label: Text(
                'Histórico atención',
                style: TextStyle(fontSize: 20),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow[600]?.withOpacity(0.8),
                padding: EdgeInsets.symmetric(vertical: 20),
              ),
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            width: 270,
            child: ElevatedButton.icon(
              onPressed: () {
                // Lógica para el cuarto botón
                Navigator.push(
                  context,
                  CustomPageRoute(child: RailwaySearchPage(idu: widget.idu)),
                );
              },
              icon: Icon(Icons.search),
              label: Text(
                'Busqueda avanzada',
                style: TextStyle(fontSize: 20),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlue.withOpacity(0.8),
                padding: EdgeInsets.symmetric(vertical: 20),
              ),
            ),
          ),
          SizedBox(height: 32),
        ],
      ),
    );
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
                  ],
                ),
              ),
              Divider(),
              ListTile(
                leading: const Icon(
                  Icons.exit_to_app, // Agregamos un icono de salida
                  color: Colors.red, // Cambiamos el color del icono
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
                  'V 1.3.3',
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
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/xd.png"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(0.0),
                child: _buildCenterButtons(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
//commit de prueba