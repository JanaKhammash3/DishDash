import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../colors.dart';

class StoreProfileScreen extends StatefulWidget {
  final Map<String, dynamic> store;

  const StoreProfileScreen({super.key, required this.store});

  @override
  State<StoreProfileScreen> createState() => _StoreProfileScreenState();
}

class _StoreProfileScreenState extends State<StoreProfileScreen> {
  LatLng? userLocation;
  LatLng? storeLocation;
  Timer? _countdownTimer;
  Duration? _timeToClose;
  double _currentRating = 0.0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _setStoreLocation();
    _fetchUserLocation();
    _startClosingCountdown();
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Vegetables':
        return Icons.grass;
      case 'Fruits':
        return Icons.apple;
      case 'Dairy':
        return Icons.icecream;
      case 'Meat':
        return Icons.set_meal;
      case 'Grains & Pasta':
        return Icons.rice_bowl;
      case 'Condiments':
        return Icons.soup_kitchen;
      case 'Canned Goods':
        return Icons.lunch_dining;
      case 'Frozen Food':
        return Icons.ac_unit;
      default:
        return Icons.category;
    }
  }

  void _setStoreLocation() {
    final location = widget.store['location'];
    debugPrint('📦 Full location value: $location');

    double? lat;
    double? lng;

    try {
      lat = (location?['lat'] as num?)?.toDouble();
      lng = (location?['lng'] as num?)?.toDouble();
    } catch (e) {
      debugPrint('❌ Error parsing lat/lng: $e');
    }

    if (lat != null && lng != null) {
      storeLocation = LatLng(lat, lng);
      debugPrint('✅ storeLocation set: $storeLocation');
    } else {
      debugPrint('❌ Could not extract lat/lng.');
    }

    setState(() {});
  }

  Map<String, List<Map<String, dynamic>>> _groupItemsByCategory(List items) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var item in items) {
      final category = item['category']?.toString() ?? 'Other';
      grouped.putIfAbsent(category, () => []).add(item as Map<String, dynamic>);
    }

    return grouped;
  }

  Future<void> _fetchUserLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever)
      return;

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      userLocation = LatLng(position.latitude, position.longitude);
    });
  }

  void _launchWhatsApp(String phone) async {
    final url = Uri.parse('https://wa.me/$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _openMapExternal(double lat, double lng) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _startClosingCountdown() {
    final openHours = _getParsedOpenHours();
    if (openHours == null || openHours['to'] == null) return;

    final now = DateTime.now();
    final format = DateFormat('HH:mm');

    try {
      final closeTimeParsed = format.parse(openHours['to']);
      final todayClose = DateTime(
        now.year,
        now.month,
        now.day,
        closeTimeParsed.hour,
        closeTimeParsed.minute,
      );

      if (todayClose.isBefore(now)) {
        _timeToClose = Duration.zero;
      } else {
        _timeToClose = todayClose.difference(now);

        _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          final remaining = todayClose.difference(DateTime.now());
          if (remaining.isNegative || remaining.inSeconds == 0) {
            _countdownTimer?.cancel();
            setState(() => _timeToClose = Duration.zero);
          } else {
            setState(() => _timeToClose = remaining);
          }
        });
      }
    } catch (_) {
      _timeToClose = null;
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  bool _isStoreOpen(dynamic rawOpenHours) {
    // 🔒 Handle null: use default hours
    if (rawOpenHours == null) {
      debugPrint("⚠️ openHours is missing, using default");
      rawOpenHours = {"from": "08:00", "to": "22:00"};
    }

    // 📦 If it's a string, try decoding
    if (rawOpenHours is String) {
      try {
        rawOpenHours = jsonDecode(rawOpenHours);
      } catch (e) {
        debugPrint("❌ Failed to parse openHours string: $e");
        return false;
      }
    }

    final from = rawOpenHours['from'];
    var to = rawOpenHours['to'];

    if (from == null || to == null) {
      debugPrint("❌ 'from' or 'to' missing");
      return false;
    }

    if (to == "24:00") to = "23:59"; // ✅ Fix Dart's invalid 24:00

    try {
      final now = DateTime.now();
      final format = DateFormat('HH:mm');
      final fromTime = format.parse(from);
      final toTime = format.parse(to);

      final fromMinutes = fromTime.hour * 60 + fromTime.minute;
      final toMinutes = toTime.hour * 60 + toTime.minute;
      final nowMinutes = now.hour * 60 + now.minute;

      // 🌙 Handle overnight hours (e.g., 22:00 to 06:00)
      if (fromMinutes > toMinutes) {
        return nowMinutes >= fromMinutes || nowMinutes <= toMinutes;
      }

      return nowMinutes >= fromMinutes && nowMinutes <= toMinutes;
    } catch (e) {
      debugPrint("❌ Time parse error: $e");
      return false;
    }
  }

  Future<void> sendNotification({
    required String recipientId,
    required String recipientModel,
    required String senderId,
    required String senderModel,
    required String type,
    required String message,
    String? relatedId,
  }) async {
    final url = Uri.parse('http://192.168.1.4:3000/api/notifications');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'recipientId': recipientId,
          'recipientModel': recipientModel,
          'senderId': senderId,
          'senderModel': senderModel,
          'type': type,
          'message': message,
          'relatedId': relatedId,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        debugPrint('❌ Failed to send notification: ${response.body}');
      } else {
        debugPrint('✅ Notification sent');
      }
    } catch (e) {
      debugPrint('❌ Notification error: $e');
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours h $minutes m';
    } else if (minutes > 0) {
      return '$minutes m $seconds s';
    } else {
      return '$seconds s';
    }
  }

  dynamic _getParsedOpenHours() {
    dynamic raw = widget.store['openHours'];
    if (raw is String) {
      try {
        return jsonDecode(raw);
      } catch (_) {
        return null;
      }
    }
    return raw;
  }

  Widget _buildStatusChip(String? status) {
    Color bgColor;
    String label;

    switch (status) {
      case 'Available':
        bgColor = Colors.green;
        label = 'Available';
        break;
      case 'Out of Stock':
        bgColor = Colors.red;
        label = 'Out of Stock';
        break;
      case 'Will be Available Soon':
        bgColor = Colors.orange;
        label = 'Coming Soon';
        break;
      default:
        bgColor = Colors.grey;
        label = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: bgColor,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  void _showMenuDrawer() {
    _searchController.clear(); // reset search
    _searchQuery = '';

    final grouped = _groupItemsByCategory(widget.store['items'] ?? []);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.9,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Center(
                        child: Container(
                          width: 50,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Store Menu',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 🔍 Search Bar
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search item...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (value) {
                          setModalState(() {
                            _searchQuery = value.toLowerCase();
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      // 📋 Filtered List
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          children: _buildFilteredMenuItems(),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  List<Widget> _buildFilteredMenuItems() {
    final grouped = _groupItemsByCategory(widget.store['items'] ?? []);

    return grouped.entries.map((entry) {
      final category = entry.key;
      final items =
          entry.value.where((item) {
            final name = item['name']?.toString().toLowerCase() ?? '';
            return name.contains(_searchQuery);
          }).toList();

      if (items.isEmpty) return const SizedBox();

      return ExpansionTile(
        initiallyExpanded: false,
        leading: Icon(_getCategoryIcon(category), color: green),
        title: Text(
          category,
          style: const TextStyle(fontWeight: FontWeight.bold, color: green),
        ),
        children:
            items.map((item) {
              return ListTile(
                title: Text(item['name']),
                subtitle: Row(children: [_buildStatusChip(item['status'])]),
                trailing: Text(
                  '\$${item['price']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: green,
                  ),
                ),
              );
            }).toList(),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.store['items'] as List<dynamic>? ?? [];
    final rating = widget.store['avgRating']?.toString() ?? 'N/A';
    print('🕒 raw openHours from widget: ${widget.store['openHours']}');
    final openHours = _getParsedOpenHours();

    final isOpen = _isStoreOpen(openHours);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.store['name']),
        backgroundColor: green,
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: _showMenuDrawer,
            icon: const Icon(Icons.restaurant_menu, color: Colors.white),
            label: const Text("Menu", style: TextStyle(color: Colors.white)),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(widget.store['image'] ?? ''),
              backgroundColor: Colors.grey[200],
            ),
            const SizedBox(height: 12),
            Text(
              widget.store['name'],
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              widget.store['telephone'] ?? '',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 18),
                const SizedBox(width: 4),
                Text(
                  rating,
                  style: const TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  isOpen ? Icons.circle : Icons.circle_outlined,
                  color: isOpen ? Colors.green : Colors.red,
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  isOpen ? 'Open Now' : 'Closed',
                  style: TextStyle(color: isOpen ? Colors.green : Colors.red),
                ),
              ],
            ),
            if (openHours != null) ...[
              const SizedBox(height: 6),
              Text(
                'Hours: ${openHours['from']} - ${openHours['to']}', // ✅ now safe
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ],

            if (isOpen && _timeToClose != null) ...[
              const SizedBox(height: 6),
              Text(
                "Closes in ${_formatDuration(_timeToClose!)}",
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ],
            const SizedBox(height: 8),
            const Text("Rate this store:"),
            RatingBar.builder(
              initialRating: _currentRating,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemPadding: const EdgeInsets.symmetric(horizontal: 2.0),
              itemBuilder:
                  (context, _) => const Icon(Icons.star, color: Colors.amber),
              onRatingUpdate: (rating) async {
                setState(() {
                  _currentRating = rating;
                });

                final prefs = await SharedPreferences.getInstance();
                final userId = prefs.getString('userId');

                if (userId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Login required to rate")),
                  );
                  return;
                }

                try {
                  final response = await http.post(
                    Uri.parse(
                      'http://192.168.1.4:3000/api/stores/${widget.store['_id']}/rate',
                    ),

                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({'userId': userId, 'value': rating}),
                  );

                  print('📦 Response status: ${response.statusCode}');
                  print('📦 Response body: ${response.body}'); // <-- ADD THIS

                  if (response.statusCode == 200) {
                    final result = jsonDecode(response.body);
                    setState(() {
                      _currentRating = rating;
                      widget.store['avgRating'] = result['avgRating'];
                    });

                    await sendNotification(
                      recipientId: widget.store['_id'],
                      recipientModel: 'Store',
                      senderId: userId,
                      senderModel: 'User',
                      type: 'rating',
                      message:
                          'rated your store ${widget.store['name']} ${rating.toStringAsFixed(1)} stars.',
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Thanks for your rating!')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to submit rating')),
                    );
                  }
                } catch (e) {
                  debugPrint("❌ Rating error: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error submitting rating')),
                  );
                }
              },
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: green),
                  ),
                  child: TextButton.icon(
                    onPressed: () => _launchWhatsApp(widget.store['telephone']),
                    icon: const Icon(Icons.chat, color: green),
                    label: const Text(
                      "WhatsApp",
                      style: TextStyle(color: green),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: green),
                  ),
                  child: TextButton.icon(
                    onPressed: () {
                      if (storeLocation != null) {
                        _openMapExternal(
                          storeLocation!.latitude,
                          storeLocation!.longitude,
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Store location not available"),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.navigation, color: green),
                    label: const Text(
                      "Directions",
                      style: TextStyle(color: green),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (storeLocation != null) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Location",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: green,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 220,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: storeLocation!,
                      initialZoom: 14,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                        subdomains: ['a', 'b', 'c'],
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: storeLocation!,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.store,
                              size: 36,
                              color: green,
                            ),
                          ),
                          if (userLocation != null)
                            Marker(
                              point: userLocation!,
                              width: 40,
                              height: 40,
                              child: const Icon(
                                Icons.person_pin_circle,
                                size: 36,
                                color: Colors.blue,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Menu",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: green,
                ),
              ),
            ),
            const Divider(),
            ..._groupItemsByCategory(items).entries.map((entry) {
              final category = entry.key;
              final categoryItems = entry.value;

              return Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  initiallyExpanded: false,
                  title: Row(
                    children: [
                      Icon(_getCategoryIcon(category), color: green),
                      const SizedBox(width: 8),
                      Text(
                        category,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: green,
                        ),
                      ),
                    ],
                  ),
                  children:
                      categoryItems.map((item) {
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          leading: const Icon(
                            Icons.shopping_cart_outlined,
                            color: Colors.black54,
                          ),
                          title: Text(item['name']),
                          subtitle: Row(
                            children: [_buildStatusChip(item['status'])],
                          ),
                          trailing: Text(
                            '\$${item['price']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: green,
                            ),
                          ),
                        );
                      }).toList(),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
