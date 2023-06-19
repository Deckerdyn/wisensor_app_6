import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MapPage extends StatefulWidget {
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late GoogleMapController mapController;
  Set<Marker> markers = {};

  Future<List<Map<String, dynamic>>> fetchCentros() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    if (token == null) {
      // El token no existe, el usuario no está autenticado
      throw Exception('Usuario no autenticado');
    }

    final url = Uri.parse('https://wisensor.cl/api/app/user/centros');
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      final centrosData = jsonResponse['data'] as List<dynamic>;
      return centrosData.map((centro) => centro as Map<String, dynamic>).toList();
    } else {
      throw Exception('Error al cargar los centros');
    }
  }

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
          final infoWindow = InfoWindow(title: centro['nombre'].toString());
          return Marker(markerId: markerId, position: position, infoWindow: infoWindow);
        }).toSet();
      });
    }).catchError((error) {
      print('Error al cargar los centros: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Estación meteorológica'),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(-41.681928, -72.676070),
          zoom: 13,
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
