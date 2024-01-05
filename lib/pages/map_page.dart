import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'weather_page.dart';

class MapPage extends StatefulWidget {
  final int idu;

  MapPage({required this.idu});

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late GoogleMapController mapController;
  Set<Marker> markers = {};
  List<int> markersWithAlerts = []; // Cambiado a List<int>
  List<int> markersWithAlerts2 = []; // Cambiado a List<int>
  List<dynamic> _centros = [];
  List<int> _alertCounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCentros().then((centros) {
      setState(() {
        markers = centros.map((centro) {
          final markerId = MarkerId(centro['idc'].toString());
          final position = LatLng(
            centro['latitud'] as double,
            centro['longitud'] as double,
          );
          final infoWindow = InfoWindow(
            title: centro['nombre'].toString(),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WeatherPage(
                    ide: centro['ide'] as int,
                    idu: widget.idu,
                    idc: centro['idc'] as int,
                    nombreCentro: centro['nombre'],
                  ),
                ),
              );
            },
          );

          // Verificar si el marcador debe estar amarillo
          final isMarkerWithAlert = markersWithAlerts.contains(centro['idc']);
          final isMarkerWithAlert2 = markersWithAlerts2.contains(centro['idc']);

          print(centro['idc']);
          final markerIcon = isMarkerWithAlert
              ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)
              : isMarkerWithAlert2
                  ? BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueYellow)
                  : BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueGreen);

          return Marker(
            markerId: markerId,
            position: position,
            icon: markerIcon, // Establecer el icono del marcador
            infoWindow: infoWindow,
          );
        }).toSet();
      });
    }).catchError((error) {
      print('Error al cargar los centros: $error');
    });
  }

  Future<List<Map<String, dynamic>>> fetchCentros() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    if (token == null) {
      throw Exception('Usuario no autenticado');
    }

    final url = Uri.parse(
        'http://201.220.112.247:1880/wisensor/api/centros?idu=${widget.idu}');
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      final centrosData = jsonResponse['data'] as List<dynamic>;

      // Store fetched data in _centros list
      _centros =
          centrosData.map((centro) => centro as Map<String, dynamic>).toList();

      // Call _printAlerts function
      await _printAlerts();

      return centrosData
          .map((centro) => centro as Map<String, dynamic>)
          .toList();
    } else {
      await _printAlerts();
      throw Exception('Error al cargar los centros');
    }
  }

  Future<void> _printAlerts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    Map<String, String> headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer $token"
    };

    // Obtener la cantidad de alertas para cada centro
    List<int> counts = [];
    int cantidad = 0;
    for (var centro in _centros) {
      int ide = centro["ide"];
      int idu = centro["idu"];
      int idc = centro["idc"];

      http.Response response = await http.get(
        Uri.parse(
            "http://201.220.112.247:1880/wisensor/api/centros/alertas?ide=$ide&idu=$idu&idc=$idc"),
        headers: headers,
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        print("Alerts data: ${response.body}");
        cantidad = (jsonResponse["data"].length);
        print(cantidad);
        int count =
            jsonResponse["data"] != null ? jsonResponse["data"].length : 0;
        counts.add(count);

        // Imprimir la severidad de la alerta
        for (var alerta in jsonResponse["data"]) {
          print("Severidad: ${alerta["severidad"]}");
          if (alerta["severidad"] == "Rojo") {
            print("Centro $idc es Rojo ");
            setState(() {
              markersWithAlerts.add(idc); // Agregar el ID del centro a la lista
            });
          } else if (alerta["severidad"] == "Amarillo") {
            print("Centro $idc es amarillo ");
            setState(() {
              markersWithAlerts2
                  .add(idc); // Agregar el ID del centro a la lista
            });
          }
        }
      } else {
        print("Error fetching alerts for centro $idc");
        counts.add(0); // Si hay un error, agregar cero alertas para el centro
      }
    }
    setState(() {
      _alertCounts = counts;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mapa'),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(-41.681928, -72.676070),
          zoom: 8,
        ),
        markers: markers,
        onMapCreated: (GoogleMapController controller) {
          mapController = controller;
          loadAsset('assets/maptheme/wisensor_theme.json').then((value) {
            mapController.setMapStyle(value);
          });
        },
      ),
    );
  }

  Future<String> loadAsset(String path) async {
    return await rootBundle.loadString(path);
  }
}
