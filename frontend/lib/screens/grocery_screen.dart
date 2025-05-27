import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:frontend/screens/StoreMapScreen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // ✅ Add this
import 'package:frontend/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class GroceryScreen extends StatefulWidget {
  final String userId;
  const GroceryScreen({super.key, required this.userId});

  @override
  State<GroceryScreen> createState() => _GroceryScreenState();
}

class _GroceryScreenState extends State<GroceryScreen> {
  bool _showSidebar = false;
  final Set<String> availableIngredients = {};
  List<Map<String, dynamic>> groceryItems = [];

  @override
  void initState() {
    super.initState();
    _loadIngredients();
    _loadAvailableIngredients();
  }

  String normalizeIngredientName(String raw) {
    final units = [
      'tsp',
      'tbsp',
      'cup',
      'oz',
      'ounce',
      'ounces',
      'grams',
      'gram',
      'kg',
      'g',
      'ml',
      'ltr',
      'teaspoon',
      'tablespoon',
      'pound',
      'lbs',
    ];

    final parts = raw.toLowerCase().split(RegExp(r'\s+'));

    int index = 0;
    while (index < parts.length &&
        (RegExp(r'^[\d\/.]+$').hasMatch(parts[index]) ||
            units.contains(parts[index]))) {
      index++;
    }

    final nameOnly = parts.sublist(index).join(' ').trim();

    // Capitalize the first letter of each word
    return nameOnly
        .split(' ')
        .map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }

  Future<void> _loadIngredients() async {
    final url = Uri.parse(
      'http://192.168.68.61:3000/api/mealplans/user/${widget.userId}/grocery-list',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> rawItems = jsonDecode(response.body);
      if (rawItems.isEmpty) {
        print('🟡 Grocery list is empty');
      }

      final Map<String, Map<String, dynamic>> ingredientMap = {};

      for (var item in rawItems) {
        final rawName = item is String ? item : item['ingredient'];
        final name = normalizeIngredientName(rawName.toString());
        final recipe = item is Map<String, dynamic> ? item['recipe'] : null;

        DateTime? scheduledTime;
        if (recipe != null && recipe['scheduledTime'] != null) {
          scheduledTime = DateTime.tryParse(recipe['scheduledTime']);
        }

        final timeLeft =
            scheduledTime != null
                ? scheduledTime.difference(DateTime.now())
                : null;

        if (ingredientMap.containsKey(name)) {
          final existing = ingredientMap[name];
          final existingTime = existing?['scheduledTime'] as DateTime?;

          if (scheduledTime != null &&
              (existingTime == null || scheduledTime.isBefore(existingTime))) {
            ingredientMap[name] = {
              'name': name,
              'price': _getPrice(name.toLowerCase()),
              'icon': _getIcon(name.toLowerCase()),
              'source': recipe?['title'],
              'scheduledTime': scheduledTime,
              'timeLeft': timeLeft,
            };
          }
        } else {
          ingredientMap[name] = {
            'name': name,
            'price': _getPrice(name.toLowerCase()),
            'icon': _getIcon(name.toLowerCase()),
            'source': recipe?['title'],
            'scheduledTime': scheduledTime,
            'timeLeft': timeLeft,
          };
        }
      }

      // 🔽 Convert to list and sort by soonest scheduled time
      List<Map<String, dynamic>> sortedItems = ingredientMap.values.toList();
      sortedItems.sort((a, b) {
        final aTime = a['timeLeft'] as Duration?;
        final bTime = b['timeLeft'] as Duration?;

        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return aTime.compareTo(bTime);
      });

      setState(() {
        groceryItems = sortedItems;
      });
    } else {
      print('❌ Failed to load grocery list from backend');
    }
  }

  Future<void> _loadAvailableIngredients() async {
    final url = Uri.parse(
      'http://192.168.68.61:3000/api/users/${widget.userId}/available-ingredients',
    );
    final res = await http.get(url);
    if (res.statusCode == 200) {
      final List<String> fetched = List<String>.from(jsonDecode(res.body));
      setState(() {
        availableIngredients.addAll(fetched);
      });
    }
  }

  Future<void> _saveIngredients() async {
    final url = Uri.parse(
      'http://192.168.68.61:3000/api/users/${widget.userId}/grocery-list',
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

  Future<void> _saveAvailableIngredients() async {
    final ingredientsList = availableIngredients.toList();

    if (ingredientsList.isEmpty) {
      print('ℹ️ Skipping save: no available ingredients');
      return;
    }

    print('📤 Attempting to save available ingredients: $ingredientsList');

    final url = Uri.parse(
      'http://192.168.68.61:3000/api/users/${widget.userId}/available-ingredients',
    );

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'ingredients': ingredientsList}),
      );

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Available ingredients saved to backend');
      } else {
        print('❌ Failed to save available ingredients to backend');
      }
    } catch (e) {
      print('❌ Exception while saving available ingredients: $e');
    }
  }

  Future<void> recordPurchase(String storeId, String ingredient) async {
    final url = Uri.parse(
      'http://192.168.68.61:3000/api/stores/$storeId/purchase',
    );

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': widget.userId, 'ingredient': ingredient}),
    );

    if (response.statusCode == 200) {
      print('✅ Purchase recorded');
    } else {
      print('❌ Failed to record purchase: ${response.body}');
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

  void toggleAvailability(String itemName) async {
    final wasAvailable = availableIngredients.contains(itemName);

    if (!wasAvailable) {
      _showStoreSelection(itemName); // will handle adding and saving
    } else {
      setState(() {
        availableIngredients.remove(itemName);
        _sortGroceryItems(); // 👈 resort after change
      });
      await _saveAvailableIngredients();
    }
  }

  void _sortGroceryItems() {
    setState(() {
      groceryItems.sort((a, b) {
        final aAvailable = availableIngredients.contains(a['name']);
        final bAvailable = availableIngredients.contains(b['name']);
        if (aAvailable && !bAvailable) return 1;
        if (!aAvailable && bAvailable) return -1;
        return 0;
      });
    });
  }

  void _showStoreSelection(String itemName) async {
    final url = Uri.parse(
      'http://192.168.68.61:3000/api/stores?item=${Uri.encodeComponent(itemName)}',
    );
    final response = await http.get(url);

    if (response.statusCode != 200) {
      print('❌ Failed to fetch stores');
      return;
    }

    final List stores = jsonDecode(response.body);
    final List<Map<String, dynamic>> matchedStores =
        stores
            .where(
              (s) => s['items']?.any(
                (i) =>
                    (i['name']?.toString().toLowerCase() ?? '') ==
                    itemName.toLowerCase(),
              ),
            )
            .map<Map<String, dynamic>>(
              (s) => {
                '_id': s['_id'],
                'name': s['name'],
                'image': s['image'],
                'location': s['location'],
              },
            )
            .toList();

    if (matchedStores.isEmpty) {
      print('⚠️ No matching stores found');
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (_) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children:
              matchedStores.map((store) {
                return ListTile(
                  leading:
                      store['image'] != null &&
                              store['image'].toString().startsWith('http')
                          ? Image.network(
                            store['image'],
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          )
                          : const Icon(Icons.store, color: green),
                  title: Text(store['name']),
                  onTap: () async {
                    Navigator.pop(context);
                    setState(() {
                      availableIngredients.add(itemName);
                      _sortGroceryItems();
                    });
                    await _saveAvailableIngredients();

                    // ✅ Add this line
                    await recordPurchase(store['_id'], itemName);

                    print(
                      '🛒 $itemName marked as available from ${store['name']}',
                    );
                  },
                );
              }).toList(),
        );
      },
    );
  }

  void _addAvailableIngredient(String name) async {
    final normalized = normalizeIngredientName(name);

    // Always add to availableIngredients set
    setState(() {
      availableIngredients.add(name);
    });

    // If it's not in groceryItems, do NOT block anything — just don't display it in the list
    final alreadyInList = groceryItems.any(
      (item) => item['name'].toString().toLowerCase() == normalized,
    );

    if (!alreadyInList) {
      print(
        '🔔 "$name" is not in groceryItems – skipping UI addition but still saving as available.',
      );
    }

    await _saveAvailableIngredients(); // Always save regardless of display
  }

  void _showAddIngredientDialog() {
    final TextEditingController _controller = TextEditingController();

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text(
              "Add Available Ingredient",
              style: TextStyle(color: green), // Optional: make title green too
            ),
            content: TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(hintText: "e.g. Tomato"),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: green), // ✅ green cancel button
                ),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: green, // ✅ green background
                  foregroundColor: Colors.white, // ✅ White text/icon
                ),
                child: const Text("Add"),
              ),
            ],
          ),
    );
  }

  Widget _buildAvailableSidebar() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.35,
      color: lightGrey,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: green,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child:
                availableIngredients.isEmpty
                    ? const Center(
                      child: Text(
                        'No items',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                    : ListView(
                      children:
                          availableIngredients.map((ingredient) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Chip(
                                label: Text(
                                  ingredient,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                backgroundColor: green,
                                deleteIcon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                ),
                                onDeleted: () async {
                                  setState(() {
                                    availableIngredients.remove(ingredient);
                                  });
                                  await _saveAvailableIngredients();
                                },
                              ),
                            );
                          }).toList(),
                    ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _showAddIngredientDialog,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Add',
              style: TextStyle(
                color: Colors.white,
              ), // ✅ Set text color to white
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: MediaQuery.of(
            context,
          ).viewInsets.add(const EdgeInsets.all(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Your Available Ingredients',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: green,
                ),
              ),
              const Divider(thickness: 1.5, height: 20),
              if (availableIngredients.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'No ingredients marked as available yet.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children:
                      availableIngredients.map((ingredient) {
                        return Chip(
                          label: Text(
                            ingredient,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          backgroundColor: green,
                          deleteIcon: const Icon(
                            Icons.close,
                            color: Colors.white,
                          ),
                          onDeleted: () async {
                            setState(() {
                              availableIngredients.remove(ingredient);
                            });
                            Navigator.pop(context);
                            _showAvailableIngredientsPanel();
                            await _saveAvailableIngredients();
                          },
                        );
                      }).toList(),
                ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: "Add new ingredient",
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      final newIngredient = _controller.text.trim();
                      Navigator.pop(context);
                      if (newIngredient.isNotEmpty) {
                        _addAvailableIngredient(newIngredient);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      backgroundColor: green,
                      padding: const EdgeInsets.all(12),
                    ),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  String _formatTimeLeft(Duration duration) {
    if (duration.isNegative) return 'Already passed';

    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;

    if (days > 0) return '$days day(s) left';
    if (hours > 0) return '$hours hour(s) left';
    return '$minutes minute(s) left';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGrey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: green),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        title: const Text(
          'Grocery Shop',
          style: TextStyle(color: green, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              setState(() => _showSidebar = !_showSidebar);
            },
            icon: Icon(
              _showSidebar ? Icons.chevron_left : Icons.chevron_right,
              color: green,
            ),
            label: Text(
              _showSidebar
                  ? 'Hide Available Ingredients'
                  : 'Show Available Ingredients',
              style: const TextStyle(color: green, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: green),
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

      body: Row(
        children: [
          if (_showSidebar) _buildAvailableSidebar(),
          if (_showSidebar) const VerticalDivider(width: 1, color: Colors.grey),
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
                      padding: const EdgeInsets.all(16),
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
                              borderRadius: BorderRadius.circular(16),
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            elevation: 3,
                            child: ListTile(
                              leading: Icon(
                                item['icon'],
                                size: 36,
                                color: isAvailable ? Colors.grey : green,
                              ),
                              title: Text(item['name']),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (item['source'] != null)
                                    Text(
                                      'From: ${item['source']}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  if (item['timeLeft'] != null)
                                    Text(
                                      _formatTimeLeft(item['timeLeft']),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.orange,
                                      ),
                                    ),
                                ],
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
                                    icon: const Icon(Icons.store, color: green),
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
                                      color: green,
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
      'http://192.168.68.61:3000/api/stores?item=${Uri.encodeComponent(widget.itemName)}',
    );

    try {
      final res = await http.get(url);

      if (res.statusCode == 200) {
        final List rawStores = jsonDecode(res.body);

        // Get user's current location
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        final Distance distance = const Distance();

        final processed =
            rawStores
                .where((s) {
                  return s['items'] != null &&
                      s['items'].any(
                        (i) =>
                            (i['name']?.toString().toLowerCase() ?? '') ==
                            widget.itemName.toLowerCase(),
                      );
                })
                .map<Map<String, dynamic>>((store) {
                  final item = store['items'].firstWhere(
                    (i) =>
                        (i['name']?.toString().toLowerCase() ?? '') ==
                        widget.itemName.toLowerCase(),
                    orElse: () => null,
                  );

                  final lat = store['location']?['lat'];
                  final lng = store['location']?['lng'];

                  double dist = 999999; // default large distance
                  if (lat != null && lng != null) {
                    dist = distance.as(
                      LengthUnit.Kilometer,
                      LatLng(position.latitude, position.longitude),
                      LatLng(lat, lng),
                    );
                  }

                  return {
                    'store': store['name'],
                    'lat': lat,
                    'lng': lng,
                    'image': store['image'], // ✅ include image here
                    'price': (item?['price'] ?? 0.0).toDouble(),
                    'distance': dist,
                  };
                })
                .toList();

        // Sort by distance ascending
        processed.sort((a, b) => a['distance'].compareTo(b['distance']));

        setState(() {
          storePrices = processed;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        print('❌ Failed to fetch store prices: ${res.statusCode}');
      }
    } catch (e) {
      setState(() => isLoading = false);
      print('❌ Error fetching prices or location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.itemName} Prices'),
        backgroundColor: green,
        foregroundColor: Colors.white,
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
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 0,
                              vertical: 4,
                            ),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child:
                                  store['image'] != null &&
                                          store['image'].toString().startsWith(
                                            'http',
                                          )
                                      ? Image.network(
                                        store['image'],
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (_, __, ___) => Container(
                                              width: 48,
                                              height: 48,
                                              color: Colors.grey[300],
                                              child: const Icon(
                                                Icons.store,
                                                color: green,
                                              ),
                                            ),
                                      )
                                      : Container(
                                        width: 48,
                                        height: 48,
                                        color: Colors.grey[300],
                                        child: const Icon(
                                          Icons.store,
                                          color: green,
                                        ),
                                      ),
                            ),

                            title: Row(
                              children: [
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
                                if (index == 0) // Nearest store
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: green.withOpacity(0.1),
                                      border: Border.all(color: green),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'Nearest Store',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: green,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Text(
                              store['distance'] != null
                                  ? 'Distance: ${store['distance'].toStringAsFixed(2)} km'
                                  : 'Distance: N/A',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            trailing: Text(
                              '\$${(store['price'] ?? 0.0).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: green,
                              ),
                            ),
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
                                  Icon(Icons.map, color: green),
                                  SizedBox(width: 8),
                                  Text(
                                    'View on Map',
                                    style: TextStyle(
                                      color: green,
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
