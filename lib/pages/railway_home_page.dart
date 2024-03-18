import 'dart:async';
import 'package:Wisensor/pages/railway_attention_page.dart';
import 'package:Wisensor/pages/railway_critic_page.dart';
import 'package:Wisensor/pages/railway_page.dart';
import 'package:flutter/material.dart';
import 'custom_page_route.dart';
import 'login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // Método que maneja la acción de retroceso del botón físico o virtual de Android
  Future<bool> _onWillPop() async {
    // Implementación del método _onWillPop()
    return true;
  }

  // Método para manejar el cierre de sesión
  Future<void> _logout(BuildContext context) async {
    // Implementación del método _logout()
  }

  @override
  void initState() {
    super.initState();

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

  Widget _buildCenterButtons() {
    return Container(
      width: double.infinity, // Ancho que abarca toda la pantalla
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3), // Fondo opaco
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 32), // Espacio desde la parte superior de la pantagwithwilla
          ElevatedButton(
            onPressed: () {
              // Lógica para el primer botón
              Navigator.push(
                context,
                CustomPageRoute(child: RailwayPage(idu: widget.idu)),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.withOpacity(0.8),
              padding: EdgeInsets.symmetric(vertical: 20, horizontal: 40), // Ajusta el tamaño del botón
            ),
            child: Text(
              'Alertas activas',
              style: TextStyle(fontSize: 20), // Tamaño de texto del botón
            ),
          ),
          SizedBox(height: 16), // Espacio entre botones
          ElevatedButton(
            onPressed: () {
              // Lógica para el segundo botón
              Navigator.push(
                context,
                CustomPageRoute(child: RailwayCriticPage(idu: widget.idu)),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.8),
              padding: EdgeInsets.symmetric(vertical: 20, horizontal: 40), // Ajusta el tamaño del botón
            ),
            child: Text(
              'Historico criticas',
              style: TextStyle(fontSize: 20), // Tamaño de texto del botón
            ),
          ),
          SizedBox(height: 16), // Espacio entre botones
          ElevatedButton(
            onPressed: () {
              // Lógica para el tercer botón
              Navigator.push(
                context,
                CustomPageRoute(child: RailwayAttentionPage(idu: widget.idu)),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.yellow[600]?.withOpacity(0.8),
              padding: EdgeInsets.symmetric(vertical: 20, horizontal: 40), // Ajusta el tamaño del botón
            ),

            child: Text(
              'Historico atención',
              style: TextStyle(fontSize: 20), // Tamaño de texto del botón
            ),
          ),
          SizedBox(height: 16), // Espacio entre botones
          ElevatedButton(
            onPressed: () {
              // Lógica para el cuarto botón
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.withOpacity(0.8),
              padding: EdgeInsets.symmetric(vertical: 20, horizontal: 40), // Ajusta el tamaño del botón
            ),
            child: Text(
              'Busqueda avanzada',
              style: TextStyle(fontSize: 20), // Tamaño de texto del botón
            ),
          ),
          SizedBox(height: 32), // Espacio desde la parte inferior de la pantalla
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
                padding: const EdgeInsets.all(20.0),
                child: _buildCenterButtons(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
