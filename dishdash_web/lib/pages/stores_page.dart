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
  String sortBy = 'name';
  int minRating = 0;
  int minPurchases = 0;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    fetchStores();
  }

  Future<void> fetchStores() async {
    final uri = Uri.http('192.168.68.60:3000', '/api/stores', {
      'search': searchQuery,
      'sort': sortBy,
      'minRating': '$minRating',
      'minPurchases': '$minPurchases',
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search by name or email',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: sortBy,
                  decoration: const InputDecoration(labelText: 'Sort by'),
                  items: const [
                    DropdownMenuItem(value: 'name', child: Text('Name')),
                    DropdownMenuItem(value: 'rating', child: Text('Rating')),
                  ],
                  onChanged: (val) {
                    setState(() {
                      sortBy = val!;
                    });
                    fetchStores();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: minRating,
                  decoration: const InputDecoration(labelText: 'Min Rating'),
                  items:
                      List.generate(6, (i) => i)
                          .map(
                            (r) =>
                                DropdownMenuItem(value: r, child: Text('$r ⭐')),
                          )
                          .toList(),
                  onChanged: (val) {
                    setState(() {
                      minRating = val!;
                    });
                    fetchStores();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: minPurchases,
                  decoration: const InputDecoration(labelText: 'Min Purchases'),
                  items:
                      [0, 10, 20, 50, 100]
                          .map(
                            (p) =>
                                DropdownMenuItem(value: p, child: Text('$p+')),
                          )
                          .toList(),
                  onChanged: (val) {
                    setState(() {
                      minPurchases = val!;
                    });
                    fetchStores();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Stores'),
        backgroundColor: const Color(0xFF304D30),
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
                          elevation: 4,
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
                                        spacing: 8,
                                        children: [
                                          Chip(
                                            label: Text(
                                              '🛒 $purchases purchases',
                                            ),
                                            backgroundColor: Colors.green[100],
                                          ),
                                          Chip(
                                            label: Text(
                                              '⭐ ${avgRating.toStringAsFixed(1)} rating',
                                            ),
                                            backgroundColor: Colors.orange[100],
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
                                  onPressed: () {
                                    // TODO: Handle delete
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
