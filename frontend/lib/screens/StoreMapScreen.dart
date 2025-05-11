import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../colors.dart';

class StoreMapScreen extends StatelessWidget {
  final String storeName;
  final double lat;
  final double lng;

  const StoreMapScreen({
    super.key,
    required this.storeName,
    required this.lat,
    required this.lng,
  });

  @override
  Widget build(BuildContext context) {
    final storeLocation = LatLng(lat, lng);

    return Scaffold(
      appBar: AppBar(
        title: Text(storeName),
        backgroundColor: Colors.white,
        foregroundColor: maroon,
      ),
      body: FlutterMap(
        mapController: MapController(),
        options: MapOptions(initialCenter: storeLocation, initialZoom: 15.0),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
          ),
          MarkerLayer(
            markers: [
              Marker(
                width: 40,
                height: 40,
                point: storeLocation,
                rotate: false,
                child: const Icon(Icons.store, size: 40, color: maroon),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
