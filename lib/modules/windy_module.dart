import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WindyModule extends StatefulWidget {
  const WindyModule({Key? key}) : super(key: key);

  @override
  State<WindyModule> createState() => _WindyModuleState();
}

class _WindyModuleState extends State<WindyModule> {
  List<dynamic> _forecastData = [];

  @override
  void initState() {
    super.initState();

    String apiKey = 'uoWdTyqz7ekUxx8e3k2apUxswXIVy2hn';
    String apiUrl = 'https://api.map-forecast.com/forecast/$apiKey/-41.4711/-72.9366';

    http.get(Uri.parse(apiUrl)).then((response) {
      setState(() {
        _forecastData = json.decode(response.body);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_forecastData.isEmpty) {
      print('No se recibieron datos de la API');
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Estación metereológica', style: TextStyle(fontSize: 20.0)),
        centerTitle: true,
      ),// Agrega un Scaffold para envolver el widget WindyModule
      body: FlutterMap(
        options: MapOptions(
          center: LatLng(-41.4711, -72.9366),
          zoom: 10.0,
        ),
        layers: [
          TileLayerOptions(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: ['a', 'b', 'c'],
          ),
          MarkerLayerOptions(
            markers: [
              Marker(
                width: 80.0,
                height: 80.0,
                point: LatLng(-41.4711, -72.9366),
                builder: (ctx) => Container(
                  child: IconButton(
                    icon: Icon(Icons.location_on),
                    color: Colors.red,
                    onPressed: () {},
                  ),
                ),
              ),
              Marker(
                width: 80.0,
                height: 80.0,
                point: LatLng(-41.47278, -72.92912),
                builder: (ctx) => Container(
                  child: IconButton(
                    icon: Icon(Icons.location_on),
                    color: Colors.red,
                    onPressed: () {},
                  ),
                ),
              ),
            ],
          ),
          if (_forecastData.isNotEmpty)
            PolylineLayerOptions(
              polylines: [
                Polyline(
                  points: _forecastData.map((data) => LatLng(data['lat'], data['lon'])).toList(),
                  strokeWidth: 4.0,
                  color: Colors.blue,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
