import 'dart:convert';
import 'package:dishdash_web/colors.dart';
import 'package:dishdash_web/pages/Store_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:dishdash_web/pages/StoreMapScreen.dart';

class UserStoresPage extends StatefulWidget {
  final String? storeId; // ✅ make it nullable

  const UserStoresPage({super.key, this.storeId});

  @override
  State<UserStoresPage> createState() => _UserStoresPageState();
}

class _UserStoresPageState extends State<UserStoresPage>
    with SingleTickerProviderStateMixin {
  List<dynamic> stores = [];
  List<dynamic> filteredStores = [];
  final String baseUrl = 'http://192.168.68.61:3000';
  String searchQuery = '';
  Position? userPosition;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _getUserLocationAndFetchStores();
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      _applyTabFilter();
    });
  }

  bool _isStoreOpen(dynamic openHours) {
    if (openHours == null) {
      debugPrint("❌ openHours is null, skipping store open logic.");
      return false;
    }

    if (openHours is String) {
      try {
        openHours = jsonDecode(openHours);
      } catch (e) {
        return false;
      }
    }

    final from = openHours['from'];
    var to = openHours['to'];

    if (from == null || to == null) return false;
    if (to == "24:00") to = "23:59";

    try {
      final now = DateTime.now();
      final format = DateFormat('HH:mm');
      final fromTime = format.parse(from);
      final toTime = format.parse(to);

      final fromMinutes = fromTime.hour * 60 + fromTime.minute;
      final toMinutes = toTime.hour * 60 + toTime.minute;
      final nowMinutes = now.hour * 60 + now.minute;

      if (fromMinutes > toMinutes) {
        return nowMinutes >= fromMinutes || nowMinutes <= toMinutes;
      }

      return nowMinutes >= fromMinutes && nowMinutes <= toMinutes;
    } catch (_) {
      return false;
    }
  }

  Future<void> _getUserLocationAndFetchStores() async {
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever)
      return;

    userPosition = await Geolocator.getCurrentPosition();
    fetchStores(userPosition!.latitude, userPosition!.longitude);
  }

  Future<void> fetchStores(double lat, double lng) async {
    final url = Uri.parse('$baseUrl/api/stores-with-items?lat=$lat&lng=$lng');
    final res = await http.get(url);

    if (res.statusCode == 200) {
      final allStores = json.decode(res.body);
      stores = allStores; // fetch and display all stores
      _applyTabFilter();
    }
  }

  void _filterStores(String query) {
    searchQuery = query;
    _applyTabFilter();
  }

  void _applyTabFilter() {
    setState(() {
      filteredStores =
          stores.where((store) {
            final name = store['name']?.toLowerCase() ?? '';
            final matchesSearch = name.contains(searchQuery.toLowerCase());

            return matchesSearch; // Allow all results, we’ll sort below
          }).toList();

      if (_tabController.index == 1) {
        // Sort by distance for Nearby tab
        filteredStores.sort(
          (a, b) => (a['distance'] ?? 999).compareTo(b['distance'] ?? 999),
        );
        filteredStores = filteredStores.take(5).toList(); // Take top 5
      } else if (_tabController.index == 2) {
        // Sort by rating for Top Rated tab
        filteredStores.sort(
          (a, b) => (b['avgRating'] ?? 0).compareTo(a['avgRating'] ?? 0),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stores'),
        backgroundColor: green,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: green, // 👈 makes TabBar background white
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Nearby'),
                Tab(text: 'Top Rated'),
              ],
            ),
          ),
        ),
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search stores...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onChanged: _filterStores,
            ),
          ),
          Expanded(
            child:
                filteredStores.isEmpty
                    ? const Center(child: Text('No stores found.'))
                    : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: filteredStores.length,
                      itemBuilder: (context, index) {
                        final store = filteredStores[index];
                        final items = store['items'] as List<dynamic>? ?? [];
                        final sampleItems = items
                            .take(2)
                            .map((i) => i['name'])
                            .join(', ');
                        final distance = store['distance'] ?? 2.5;
                        dynamic openHours = store['openHours'];
                        if (openHours is String) {
                          try {
                            openHours = jsonDecode(openHours);
                          } catch (e) {
                            openHours = null;
                          }
                        }
                        final isOpen = _isStoreOpen(openHours);

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StoreProfilePage(store: store),
                              ),
                            );
                          },
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            elevation: 6,
                            margin: const EdgeInsets.only(bottom: 16),
                            shadowColor: Colors.black26,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 32,
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
                                                  size: 30,
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
                                            Text(
                                              store['telephone'] ?? 'No phone',
                                              style: const TextStyle(
                                                color: Colors.grey,
                                              ),
                                            ),
                                            Text(
                                              'Distance: ${distance.toStringAsFixed(1)} km',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.blueGrey,
                                              ),
                                            ),
                                            Text(
                                              isOpen ? 'Open now' : 'Closed',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    isOpen
                                                        ? Colors.green
                                                        : Colors.red,
                                              ),
                                            ),
                                            if (openHours != null)
                                              Text(
                                                'Hours: ${openHours['from']} - ${openHours['to']}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black54,
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
                                                    ? (double.tryParse(
                                                              store['avgRating']
                                                                  .toString(),
                                                            ) ??
                                                            0.0)
                                                        .toStringAsFixed(1)
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
                                              borderRadius:
                                                  BorderRadius.circular(12),
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
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
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
                                        const SizedBox(height: 12),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: .9,
                                          ), // slightly up
                                          child: Align(
                                            alignment: Alignment.centerRight,
                                            child: OutlinedButton.icon(
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: green,
                                                side: BorderSide(
                                                  color: green,
                                                  width: 1.2,
                                                ),
                                                visualDensity:
                                                    VisualDensity.compact,
                                                tapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 6,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                              ),
                                              icon: const Icon(
                                                Icons.person_outline,
                                                size: 14,
                                              ),
                                              label: const Text(
                                                'Profile',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder:
                                                        (_) => StoreProfilePage(
                                                          store: store,
                                                        ),
                                                  ),
                                                );
                                              },
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
          ),
        ],
      ),
    );
  }
}
