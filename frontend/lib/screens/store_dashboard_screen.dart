import 'package:flutter/material.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

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
  File? _pickedImage;
  String? storeImageUrl;
  final ImagePicker picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    fetchStoreItems();
  }

  Future<void> pickAndUploadImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) {
      print('📷 No image selected');
      return;
    }

    final bytes = await pickedFile.readAsBytes(); // ✅ Works on web
    final fileName = pickedFile.name;

    final uri = Uri.parse(
      'http://192.168.1.4:3000/api/stores/${widget.storeId}/image',
    );
    final request = http.MultipartRequest('PUT', uri);

    request.files.add(
      http.MultipartFile.fromBytes('image', bytes, filename: fileName),
    );

    try {
      final response = await request.send();
      print('📶 Upload status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final data = json.decode(respStr);
        final uploadedUrl = data['image'];

        print('✅ Uploaded image URL: $uploadedUrl');

        setState(() {
          storeImageUrl = uploadedUrl;
        });

        await fetchStoreItems();

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('✅ Image uploaded')));
      } else {
        print('❌ Upload failed: ${response.statusCode}');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('❌ Upload failed')));
      }
    } catch (e) {
      print('❌ Exception during upload: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('❌ Upload error')));
    }
  }

  Future<void> fetchStoreItems() async {
    final url = Uri.parse(
      'http://192.168.1.4:3000/api/stores/${widget.storeId}',
    );

    print('🌐 Fetching store: $url');

    try {
      final response = await http.get(url);
      print('📥 Fetch status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawItems = data['items'] ?? [];

        setState(() {
          items = List<Map<String, dynamic>>.from(rawItems);
          storeImageUrl = data['image'];
        });

        print('✅ Image from DB: $storeImageUrl');
      } else {
        print('❌ Failed to fetch items. Status: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to fetch items (${response.statusCode})'),
          ),
        );
      }
    } catch (e) {
      print('❌ Fetch exception: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('❌ Failed to load store')));
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

  void handleMenuSelection(String value) {
    if (value == 'logout') {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } else if (value == 'info') {
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text('Store Info'),
              content: Text(
                'Store ID: ${widget.storeId}\nContact: (e.g. from DB)',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
      );
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
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings, color: Colors.white),
            onSelected: handleMenuSelection,
            itemBuilder:
                (context) => [
                  const PopupMenuItem(value: 'info', child: Text('Info')),
                  const PopupMenuItem(value: 'logout', child: Text('Logout')),
                ],
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: green,
        onPressed: showAddItemModal,
        child: const Icon(Icons.add, color: Colors.white), // ✅ white +
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (storeImageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(storeImageUrl!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                )
              else
                Container(
                  height: 180,
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
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: pickAndUploadImage,
                icon: const Icon(Icons.image),
                label: const Text('Upload/Change Store Photo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              items.isEmpty
                  ? const Text('No items added yet.')
                  : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
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
                              color: green.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.fastfood,
                              color: green,
                              size: 24,
                            ),
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text('Price: \$${price}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => deleteItem(name),
                          ),
                        ),
                      );
                    },
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
