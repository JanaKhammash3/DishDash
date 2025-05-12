import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../colors.dart';

class StoreDashboardScreen extends StatefulWidget {
  final String storeId;

  const StoreDashboardScreen({super.key, required this.storeId});

  @override
  State<StoreDashboardScreen> createState() => _StoreDashboardScreenState();
}

class _StoreDashboardScreenState extends State<StoreDashboardScreen> {
  List<Map<String, dynamic>> items = [];
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchStoreItems();
  }

  Future<void> fetchStoreItems() async {
    final url = Uri.parse(
      'http://192.168.1.4:3000/api/stores/${widget.storeId}',
    );
    final response = await http.get(url);

    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final rawItems = data['items'] ?? [];

      setState(() {
        items = List<Map<String, dynamic>>.from(rawItems);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to fetch items (${response.statusCode})'),
        ),
      );
    }
  }

  Future<void> addItem() async {
    final name = nameController.text.trim();
    final price = double.tryParse(priceController.text.trim());

    if (name.isEmpty || price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid name and price')),
      );
      return;
    }

    final url = Uri.parse(
      'http://192.168.1.4:3000/api/stores/${widget.storeId}/items',
    );
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'price': price}),
    );

    if (response.statusCode == 200) {
      nameController.clear();
      priceController.clear();
      Navigator.pop(context); // Close modal
      fetchStoreItems();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to add item')));
    }
  }

  Future<void> deleteItem(String itemName) async {
    final url = Uri.parse(
      'http://192.168.1.4:3000/api/stores/${widget.storeId}/items/$itemName',
    );
    final response = await http.delete(url);

    if (response.statusCode == 200) {
      fetchStoreItems();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to delete item')));
    }
  }

  void showAddItemModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add New Item',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Item Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Price'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: addItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  minimumSize: const Size.fromHeight(45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Add Item',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: green,
        title: const Text(
          'Store Dashboard',
          style: TextStyle(color: Colors.white),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: green,
        onPressed: showAddItemModal,
        child: const Icon(Icons.add, color: Colors.white), // ✅ white +
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child:
            items.isEmpty
                ? const Center(child: Text('No items added yet.'))
                : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (_, index) {
                    final item = items[index];
                    final name = item['name'] ?? 'Unnamed';
                    final price = item['price']?.toStringAsFixed(2) ?? '0.00';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: green.withOpacity(
                              0.2,
                            ), // Maroon-tinted circle
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.fastfood,
                            color: green, // Maroon/green icon
                            size: 24,
                          ),
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          'Price: \$${price}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deleteItem(name),
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
