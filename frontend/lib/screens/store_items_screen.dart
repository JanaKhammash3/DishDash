import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'store_profile_screen.dart';

class StoreItemsScreen extends StatefulWidget {
  const StoreItemsScreen({super.key});

  @override
  State<StoreItemsScreen> createState() => _StoreItemsScreenState();
}

class _StoreItemsScreenState extends State<StoreItemsScreen> {
  List<dynamic> stores = [];
  final String baseUrl = 'http://192.168.1.4:3000';

  @override
  void initState() {
    super.initState();
    _getUserLocationAndFetchStores();
  }

  Future<void> _getUserLocationAndFetchStores() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return; // show dialog/snackbar to ask user to allow permission
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    fetchStores(position.latitude, position.longitude);
  }

  Future<void> fetchStores(double lat, double lng) async {
    final url = Uri.parse('$baseUrl/api/stores-with-items?lat=$lat&lng=$lng');
    final res = await http.get(url);

    if (res.statusCode == 200) {
      setState(() {
        stores = json.decode(res.body);
      });
    } else {
      print('❌ Failed to fetch stores');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Posts'),
        backgroundColor: green,
        foregroundColor: Colors.white,
      ),
      body:
          stores.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: stores.length,
                itemBuilder: (context, index) {
                  final store = stores[index];
                  final items = store['items'] as List<dynamic>? ?? [];
                  final sampleItems = items
                      .take(2)
                      .map((i) => i['name'])
                      .join(', ');
                  final distance = store['distance'] ?? 2.5; // Placeholder

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StoreProfileScreen(store: store),
                        ),
                      );
                    },
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Colors.grey[200],
                                  backgroundImage:
                                      store['image'] != null
                                          ? NetworkImage(store['image'])
                                          : null,
                                  child:
                                      store['image'] == null
                                          ? const Icon(
                                            Icons.store,
                                            color: Colors.grey,
                                          )
                                          : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        store['name'] ?? 'Unnamed Store',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        store['telephone'] ?? 'No phone',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Distance: ${distance.toStringAsFixed(1)} km',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.blueGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          size: 16,
                                          color: Colors.amber,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          store['avgRating'] != null
                                              ? store['avgRating'].toString()
                                              : 'N/A',
                                          style: const TextStyle(
                                            color: Colors.amber,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'Popular',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.orange,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (sampleItems.isNotEmpty)
                              Row(
                                children: [
                                  const Icon(
                                    Icons.shopping_bag,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Bestsellers: $sampleItems',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
