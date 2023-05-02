import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show MapType, CameraPosition, Marker, MarkerId, BitmapDescriptor, Set, LatLng, InfoWindow, GoogleMap, mapTypeNone;
import 'package:flutter/services.dart' show rootBundle;

class MapPage extends StatefulWidget {
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  // Define los marcadores como una lista de tipo Set<Marker>
  Set<Marker> markers = {};

  @override
  void initState() {
    super.initState();
    // Agrega los dos marcadores a la lista
    markers.add(
      Marker(
        markerId: MarkerId('Marker1'),
        position: LatLng(-41.681928, -72.676070),
        infoWindow: InfoWindow(title: 'Centro 01'),
      ),
    );

    markers.add(
      Marker(
        markerId: MarkerId('Marker2'),
        position: LatLng(-41.650173, -72.688269),
        infoWindow: InfoWindow(title: 'Centro 02'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Estación metereologica'),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(-41.681928, -72.676070),
          zoom: 14,
        ),
        markers: markers, // Agrega los marcadores a la vista del mapa
      ),
    );
  }
}
