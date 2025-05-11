import 'package:flutter/material.dart';
import 'package:frontend/screens/StoreMapScreen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // ✅ Add this
import 'package:frontend/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GroceryScreen extends StatefulWidget {
  final String userId;
  const GroceryScreen({super.key, required this.userId});

  @override
  State<GroceryScreen> createState() => _GroceryScreenState();
}

class _GroceryScreenState extends State<GroceryScreen> {
  final Set<String> availableIngredients = {};
  List<Map<String, dynamic>> groceryItems = [];

  @override
  void initState() {
    super.initState();
    _loadIngredients();
  }

  Future<void> _loadIngredients() async {
    final url = Uri.parse(
      'http://192.168.1.4:3000/api/users/${widget.userId}/grocery-list',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<String> ingredients = List<String>.from(
        jsonDecode(response.body),
      );
      if (ingredients.isEmpty) {
        print('🟡 Grocery list is empty');
      }
      setState(() {
        groceryItems =
            ingredients
                .toSet()
                .map(
                  (name) => {
                    'name': name,
                    'price': _getPrice(name.toLowerCase()),
                    'icon': _getIcon(name.toLowerCase()),
                  },
                )
                .toList();
      });
    } else {
      print('❌ Failed to load grocery list from backend');
    }
  }

  Future<void> _saveIngredients() async {
    final url = Uri.parse(
      'http://192.168.1.4:3000/api/users/${widget.userId}/grocery-list',
    );
    final ingredients =
        groceryItems.map((item) => item['name'] as String).toList();

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'ingredients': ingredients}),
    );

    if (response.statusCode != 200) {
      print('❌ Failed to save grocery list to backend');
    }
  }

  void _removeIngredient(String name) {
    setState(() {
      groceryItems.removeWhere((item) => item['name'] == name);
      availableIngredients.remove(name);
    });
    _saveIngredients();
  }

  void _clearAllIngredients() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('groceryIngredients');
    setState(() {
      groceryItems.clear();
      availableIngredients.clear();
    });
  }

  double _getPrice(String name) {
    switch (name) {
      case 'tomato':
        return 1.50;
      case 'onion':
        return 0.80;
      case 'potato':
        return 0.90;
      case 'carrot':
        return 0.70;
      case 'peppers':
      case 'pepper':
        return 1.20;
      case 'eggplant':
        return 1.10;
      default:
        return 1.00;
    }
  }

  IconData _getIcon(String name) {
    switch (name) {
      case 'tomato':
        return Icons.local_pizza;
      case 'onion':
        return Icons.restaurant;
      case 'potato':
        return Icons.eco;
      case 'carrot':
        return Icons.spa;
      case 'pepper':
      case 'peppers':
        return Icons.whatshot;
      case 'eggplant':
        return Icons.grass;
      default:
        return Icons.shopping_bag;
    }
  }

  void toggleAvailability(String itemName) {
    setState(() {
      if (availableIngredients.contains(itemName)) {
        availableIngredients.remove(itemName);
      } else {
        availableIngredients.add(itemName);
      }
    });
  }

  void _addAvailableIngredient(String name) {
    final normalized = name.toLowerCase();
    final alreadyInList = groceryItems.any(
      (item) => item['name'].toString().toLowerCase() == normalized,
    );

    if (!alreadyInList) {
      setState(() {
        groceryItems.add({
          'name': name,
          'price': _getPrice(normalized),
          'icon': _getIcon(normalized),
        });
        availableIngredients.add(name);
      });
      _saveIngredients(); // Update backend
    } else {
      setState(() {
        availableIngredients.add(name);
      });
    }
  }

  void _showAddIngredientDialog() {
    final TextEditingController _controller = TextEditingController();

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Add Available Ingredient"),
            content: TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(hintText: "e.g. Tomato"),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  final newIngredient = _controller.text.trim();
                  Navigator.pop(context);
                  if (newIngredient.isNotEmpty) {
                    setState(() {
                      _addAvailableIngredient(newIngredient);
                    });
                  }
                },
                child: const Text("Add"),
              ),
            ],
          ),
    );
  }

  void _showAvailableIngredientsPanel() {
    final TextEditingController _controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: MediaQuery.of(
            context,
          ).viewInsets.add(const EdgeInsets.all(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Available Ingredients',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: maroon,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children:
                    availableIngredients.map((ingredient) {
                      return Chip(
                        label: Text(ingredient),
                        onDeleted: () {
                          setState(() {
                            availableIngredients.remove(ingredient);
                          });
                          Navigator.pop(context);
                          _showAvailableIngredientsPanel(); // reopen updated
                        },
                      );
                    }).toList(),
              ),
              const SizedBox(height: 20),

              const SizedBox(height: 20),
              Center(
                child: FloatingActionButton(
                  backgroundColor: maroon,
                  onPressed: () {
                    Navigator.pop(context);
                    _showAddIngredientDialog();
                  },
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGrey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: maroon),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        title: const Text(
          'Grocery Shop',
          style: TextStyle(color: maroon, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: maroon),
            tooltip: 'Clear All',
            onPressed:
                groceryItems.isEmpty
                    ? null
                    : () {
                      showDialog(
                        context: context,
                        builder:
                            (_) => AlertDialog(
                              title: const Text("Clear All?"),
                              content: const Text(
                                "This will remove all ingredients.",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Cancel"),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _clearAllIngredients();
                                  },
                                  child: const Text("Clear All"),
                                ),
                              ],
                            ),
                      );
                    },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check_circle, color: Colors.white),
              style: ElevatedButton.styleFrom(
                backgroundColor: maroon,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _showAvailableIngredientsPanel,
              label: const Text(
                'Manage Available Ingredients',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          Expanded(
            child:
                groceryItems.isEmpty
                    ? const Center(
                      child: Text(
                        'No ingredients found in your meal plan.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                    : ListView.builder(
                      itemCount: groceryItems.length,
                      itemBuilder: (context, index) {
                        final item = groceryItems[index];
                        final isAvailable = availableIngredients.contains(
                          item['name'],
                        );

                        return Opacity(
                          opacity: isAvailable ? 0.4 : 1.0,
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            elevation: 3,
                            child: ListTile(
                              leading: Icon(
                                item['icon'],
                                size: 36,
                                color: isAvailable ? Colors.grey : maroon,
                              ),
                              title: Text(
                                item['name'],
                                style: const TextStyle(color: Colors.black),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Checkbox(
                                    shape: const CircleBorder(),
                                    value: isAvailable,
                                    activeColor: Colors.green,
                                    onChanged:
                                        (_) => toggleAvailability(item['name']),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.store,
                                      color: maroon,
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => StorePriceScreen(
                                                itemName: item['name'],
                                              ),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: maroon,
                                    ),
                                    onPressed:
                                        () => _removeIngredient(item['name']),
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

class StorePriceScreen extends StatefulWidget {
  final String itemName;
  const StorePriceScreen({super.key, required this.itemName});

  @override
  State<StorePriceScreen> createState() => _StorePriceScreenState();
}

class _StorePriceScreenState extends State<StorePriceScreen> {
  List<Map<String, dynamic>> storePrices = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchStorePrices();
  }

  Future<void> fetchStorePrices() async {
    final url = Uri.parse(
      'http://192.168.1.4:3000/api/stores?item=${Uri.encodeComponent(widget.itemName)}',
    );

    final res = await http.get(url);

    if (res.statusCode == 200) {
      final List rawStores = jsonDecode(res.body);
      final filtered =
          rawStores
              .where(
                (s) =>
                    s['items'] != null &&
                    s['items'].any(
                      (i) =>
                          (i['name']?.toString().toLowerCase() ?? '') ==
                          widget.itemName.toLowerCase(),
                    ),
              )
              .map<Map<String, dynamic>>((store) {
                final item = store['items'].firstWhere(
                  (i) =>
                      (i['name']?.toString().toLowerCase() ?? '') ==
                      widget.itemName.toLowerCase(),
                  orElse: () => null,
                );

                return {
                  'store': store['name']?.toString() ?? 'Unknown Store',
                  'lat': store['location']?['lat'],
                  'lng': store['location']?['lng'],
                  'price':
                      item != null && item['price'] != null
                          ? (item['price'] as num).toDouble()
                          : 0.0,
                };
              })
              .toList();

      setState(() {
        storePrices = filtered;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      print('❌ Failed to fetch store prices: ${res.statusCode} - ${res.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.itemName} Prices'),
        backgroundColor: Colors.white,
        foregroundColor: maroon,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : storePrices.isEmpty
              ? const Center(child: Text('No stores found for this item.'))
              : ListView.builder(
                itemCount: storePrices.length,
                itemBuilder: (context, index) {
                  final store = storePrices[index];
                  final lat = store['lat'];
                  final lng = store['lng'];
                  final price = (store['price'] ?? 0.0).toStringAsFixed(2);

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.store, color: maroon, size: 32),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  store['store'],
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              Text(
                                '\$$price',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: maroon,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (lat != null && lng != null)
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => StoreMapScreen(
                                          storeName: store['store'],
                                          lat: lat,
                                          lng: lng,
                                        ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Row(
                                children: const [
                                  Icon(Icons.map, color: maroon),
                                  SizedBox(width: 8),
                                  Text(
                                    'View on Map',
                                    style: TextStyle(
                                      color: maroon,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            const Text(
                              'Location not available',
                              style: TextStyle(color: Colors.grey),
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
