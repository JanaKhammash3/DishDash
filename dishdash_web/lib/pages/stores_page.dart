import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class StoresPage extends StatefulWidget {
  const StoresPage({super.key});

  @override
  State<StoresPage> createState() => _StoresPageState();
}

class _StoresPageState extends State<StoresPage> {
  List<dynamic> stores = [];
  String searchQuery = '';
  Timer? _debounce;
  String sortBy = 'name'; // default sort

  @override
  void initState() {
    super.initState();
    fetchStores();
  }

  Future<void> fetchStores() async {
    final uri = Uri.http('192.168.68.60:3000', '/api/stores', {
      'search': searchQuery,
      'sort': sortBy,
    });

    final res = await http.get(uri);
    if (res.statusCode == 200) {
      setState(() {
        stores = jsonDecode(res.body);
      });
    } else {
      print('❌ Failed to load stores');
    }
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        searchQuery = value;
      });
      fetchStores();
    });
  }

  ImageProvider getImage(String? image) {
    if (image == null || image.isEmpty) {
      return const AssetImage('assets/store_placeholder.png');
    }
    if (image.startsWith('http')) return NetworkImage(image);
    if (image.startsWith('/9j')) return MemoryImage(base64Decode(image));
    return NetworkImage('http://192.168.68.60:3000/images/$image');
  }

  Widget buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔍 SEARCH BAR
          TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, color: Color(0xFF304D30)),
              hintText: 'Search by name or email',
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            style: const TextStyle(color: Colors.black),
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 16),

          // 🧭 SORTING DROPDOWN
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonFormField<String>(
              value: sortBy,
              decoration: const InputDecoration(
                border: InputBorder.none,
                labelText: 'Sort By',
                labelStyle: TextStyle(color: Color(0xFF304D30)),
              ),
              style: const TextStyle(
                color: Color(0xFF304D30),
                fontWeight: FontWeight.w600,
              ),
              dropdownColor: Colors.white,
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF304D30)),
              items: const [
                DropdownMenuItem(value: 'name', child: Text('A-Z')),
                DropdownMenuItem(
                  value: 'rating',
                  child: Text('Highest Rating'),
                ),
              ],
              onChanged: (val) {
                setState(() {
                  sortBy = val!;
                });
                fetchStores();
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // ✅ Removes back icon
        backgroundColor: const Color(0xFF304D30),
        title: const Text(
          'All Stores',
          style: TextStyle(
            color: Colors.white, // ✅ Makes title text white
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),

      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          buildFilterSection(),
          Expanded(
            child:
                stores.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: stores.length,
                      itemBuilder: (_, index) {
                        final store = stores[index];
                        final name = store['name'] ?? 'Unknown';
                        final email = store['email'] ?? 'N/A';
                        final telephone = store['telephone'] ?? 'No phone';
                        final image = store['image'];
                        final purchases =
                            (store['purchases'] as List?)?.length ?? 0;
                        final ratings = store['ratings'] ?? [];
                        final avgRating =
                            ratings.isNotEmpty
                                ? ratings
                                        .map((r) => (r['value'] ?? 0) as num)
                                        .reduce((a, b) => a + b) /
                                    ratings.length
                                : 0;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 6,
                          shadowColor: Colors.green.withOpacity(
                            0.2,
                          ), // ✅ soft green shadow
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 32,
                                  backgroundImage: getImage(image),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        email,
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      Text(
                                        "📞 $telephone",
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 10,
                                        children: [
                                          Material(
                                            elevation: 2,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            color: Colors.green[50],
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons.shopping_cart,
                                                    size: 18,
                                                    color: Colors.green,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    '$purchases purchases',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Colors.green,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Material(
                                            elevation: 2,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            color: Colors.orange[50],
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons.star,
                                                    size: 18,
                                                    color: Colors.orange,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    '${avgRating.toStringAsFixed(1)} rating',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Colors.orange,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () async {
                                    final confirm = await showDialog(
                                      context: context,
                                      builder:
                                          (_) => AlertDialog(
                                            title: const Text(
                                              "Confirm Deletion",
                                            ),
                                            content: const Text(
                                              "Are you sure you want to delete this store?",
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed:
                                                    () => Navigator.pop(
                                                      context,
                                                      false,
                                                    ),
                                                child: const Text("Cancel"),
                                              ),
                                              TextButton(
                                                onPressed:
                                                    () => Navigator.pop(
                                                      context,
                                                      true,
                                                    ),
                                                child: const Text("Delete"),
                                              ),
                                            ],
                                          ),
                                    );

                                    if (confirm == true) {
                                      final storeId = store['_id'];
                                      final res = await http.delete(
                                        Uri.parse(
                                          'http://192.168.68.60:3000/api/stores/$storeId',
                                        ),
                                      );
                                      if (res.statusCode == 200) {
                                        setState(() => stores.removeAt(index));
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text("✅ Store deleted"),
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              "❌ Failed: ${res.body}",
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ],
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
