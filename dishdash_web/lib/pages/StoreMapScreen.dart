import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../colors.dart';

class StoreMapScreen extends StatefulWidget {
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
  State<StoreMapScreen> createState() => _StoreMapScreenState();
}

class _StoreMapScreenState extends State<StoreMapScreen> {
  late final MapController _mapController;
  late final LatLng _storeLocation;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _storeLocation = LatLng(widget.lat, widget.lng);
  }

  void _centerMap() {
    _mapController.move(_storeLocation, 15.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.storeName),
        backgroundColor: Colors.white,
        foregroundColor: green,
        elevation: 1,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _storeLocation,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _storeLocation,
                    width: 60,
                    height: 60,
                    child: Column(
                      children: const [
                        Icon(Icons.location_on, size: 40, color: Colors.red),
                        Text(
                          "Store",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: _centerMap,
              backgroundColor: green,
              child: const Icon(Icons.center_focus_strong),
            ),
          ),
        ],
      ),
    );
  }
}
