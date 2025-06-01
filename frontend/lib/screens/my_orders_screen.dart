import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../colors.dart';
import 'package:geolocator/geolocator.dart';

class MyOrdersScreen extends StatefulWidget {
  final String userId;
  const MyOrdersScreen({super.key, required this.userId});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  List<dynamic> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<String?> getEstimatedTime(Map<String, dynamic> storeLocation) async {
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever)
        return null;

      final userPos = await Geolocator.getCurrentPosition();
      final double storeLat = storeLocation['lat'] ?? storeLocation['latitude'];
      final double storeLng =
          storeLocation['lng'] ?? storeLocation['longitude'];

      final distanceInMeters = Geolocator.distanceBetween(
        userPos.latitude,
        userPos.longitude,
        storeLat,
        storeLng,
      );

      const double avgSpeed = 40 * 1000 / 60; // 40km/h = 666.7 m/min
      final minutes = (distanceInMeters / avgSpeed).round();

      return '$minutes mins away';
    } catch (e) {
      print('⛔ Delivery time error: $e');
      return null;
    }
  }

  Future<void> fetchOrders() async {
    final url = Uri.parse(
      'http://192.168.1.4:3000/api/orders/user/${widget.userId}',
    );
    final res = await http.get(url);

    if (res.statusCode == 200) {
      final List<dynamic> rawOrders = jsonDecode(res.body);

      // Resolve store names from store IDs
      List<dynamic> enrichedOrders = await Future.wait(
        rawOrders.map((order) async {
          final storeId =
              order['storeId'] is Map
                  ? order['storeId']['_id']
                  : order['storeId'];
          String storeName = 'Now Store';

          if (storeId != null) {
            final storeRes = await http.get(
              Uri.parse('http://192.168.1.4:3000/api/stores/basic/$storeId'),
            );
            if (storeRes.statusCode == 200) {
              final storeData = jsonDecode(storeRes.body);
              storeName = storeData['name'] ?? 'Store';

              order['storeImage'] = storeData['image'];
              order['storeLocation'] = storeData['location'];
            }
          }

          order['storeName'] = storeName; // Inject resolved name
          return order;
        }),
      );

      setState(() {
        orders = enrichedOrders;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      print('❌ Failed to fetch orders');
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'Placed':
        return Colors.orange;
      case 'Preparing':
        return Colors.blue;
      case 'Ready':
        return Colors.green;
      case 'Completed':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: green,
        foregroundColor: Colors.white,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : orders.isEmpty
              ? const Center(child: Text('No orders yet.'))
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  final status = order['status'] ?? 'Unknown';
                  final storeName =
                      order['storeName'] != null &&
                              order['storeName'].toString().trim().isNotEmpty
                          ? 'From ${order['storeName']}'
                          : 'From Now Store';
                  final delivery = order['deliveryMethod'] ?? 'Pickup';
                  final date = DateTime.tryParse(order['createdAt'] ?? '');
                  final storeImage = order['storeImage'];
                  final storeLocation = order['storeLocation'];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundImage:
                                    storeImage != null &&
                                            storeImage.toString().startsWith(
                                              'http',
                                            )
                                        ? NetworkImage(storeImage)
                                        : const AssetImage(
                                              'assets/store_placeholder.png',
                                            )
                                            as ImageProvider,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      storeName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    Text('Method: $delivery'),
                                    if (date != null)
                                      Text(
                                        'Date: ${date.toLocal().toString().split('.')[0]}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (storeLocation != null)
                                Column(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.location_on,
                                        color: Colors.red,
                                      ),
                                      tooltip: 'Open in Maps',
                                      onPressed: () {
                                        final lat =
                                            storeLocation['lat'] ??
                                            storeLocation['latitude'];
                                        final lng =
                                            storeLocation['lng'] ??
                                            storeLocation['longitude'];
                                        final url = Uri.parse(
                                          'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
                                        );
                                        launchUrl(url);
                                      },
                                    ),
                                    FutureBuilder<String?>(
                                      future: getEstimatedTime(storeLocation),
                                      builder: (_, snapshot) {
                                        return Text(
                                          snapshot.data ?? '',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          const Divider(height: 20),
                          ...List<Widget>.from(
                            (order['items'] as List<dynamic>).map((item) {
                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(item['name']),
                                  Text('\$${item['price']}'),
                                ],
                              );
                            }),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: getStatusColor(status).withOpacity(0.1),
                              border: Border.all(color: getStatusColor(status)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Status: $status',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: getStatusColor(status),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
