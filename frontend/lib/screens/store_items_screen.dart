import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/colors.dart';

class StoreItemsScreen extends StatefulWidget {
  const StoreItemsScreen({super.key});

  @override
  State<StoreItemsScreen> createState() => _StoreItemsScreenState();
}

class _StoreItemsScreenState extends State<StoreItemsScreen> {
  List<dynamic> stores = [];
  final String baseUrl = 'http://192.168.68.60:3000';

  @override
  void initState() {
    super.initState();
    fetchStoresWithItems();
  }

  Future<void> fetchStoresWithItems() async {
    final res = await http.get(Uri.parse('$baseUrl/api/stores-with-items'));

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
        title: const Text('Stores & Items'),
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
                  final List items = store['items'] ?? [];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (store['image'] != null &&
                                  store['image'].toString().startsWith('http'))
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    store['image'],
                                    height: 160,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (_, __, ___) => const Icon(
                                          Icons.image_not_supported,
                                        ),
                                  ),
                                )
                              else
                                Container(
                                  height: 160,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.storefront,
                                    size: 60,
                                    color: Colors.grey,
                                  ),
                                ),
                              const SizedBox(height: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    store['name'] ?? 'Unnamed Store',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.phone,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        store['telephone'] ?? 'No contact info',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),
                          ...items.map((item) {
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.shopping_bag),
                              title: Text(item['name']),
                              trailing: Text(
                                '\$${item['price'].toString()}',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
