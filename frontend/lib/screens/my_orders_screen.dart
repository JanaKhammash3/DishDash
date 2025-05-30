import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../colors.dart';

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
              storeName = storeData['name'] ?? 'Store'; // ✅ Correct
              final storeImage =
                  storeData['image']; // optional if you want to show it
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
                          Text(
                            storeName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Method: $delivery'),
                          if (date != null)
                            Text(
                              'Date: ${date.toLocal().toString().split('.')[0]}',
                            ),
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
