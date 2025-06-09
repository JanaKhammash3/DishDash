import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:frontend/screens/StoreMapScreen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // ✅ Add this
import 'package:frontend/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:frontend/screens/generate_byavailable.dart';

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
  List<Map<String, dynamic>> cartItems = [];
  @override
  void initState() {
    super.initState();
    _loadIngredients();
    _loadAvailableIngredients();
    _loadCartFromPrefs();
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

  Future<void> _saveCartToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(cartItems);
    await prefs.setString(
      'cartItems_${widget.userId}',
      encoded,
    ); // ✅ key includes userId
  }

  Future<void> _loadCartFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(
      'cartItems_${widget.userId}',
    ); // ✅ match key
    if (encoded != null) {
      setState(() {
        cartItems = List<Map<String, dynamic>>.from(jsonDecode(encoded));
      });
    }
  }

  void _showCartModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (context) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Cart',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Divider(),
                ...cartItems.map(
                  (item) => ListTile(
                    title: Text(item['name']),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          cartItems.remove(item);
                          _saveCartToPrefs();
                        });
                        Navigator.pop(context);
                        _showCartModal();
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed:
                      cartItems.isEmpty ? null : _placeOrderFirstThenPayment,
                  child: const Text('Order'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _placeOrderFirstThenPayment() async {
    if (cartItems.isEmpty) return;

    final result = await _promptStoreSelection();
    if (result == null) return;

    final storeId = result['storeId'];
    final storePrices = result['storePrices']; // Map<String, double>
    for (var item in cartItems) {
      final name = item['name'];

      setState(() {
        availableIngredients.add(name);
      });

      await _saveAvailableIngredients();
      await recordPurchase(storeId, name);
    }

    Navigator.pop(context);
    _proceedToFakePayment(storeId, storePrices); // ✅ Correct
    // ✅ PASS STORE ID FORWARD
  }

  void _proceedToFakePayment(String storeId, Map<String, dynamic> storePrices) {
    String selectedMethod = 'Pickup';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose Delivery Method',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              RadioListTile<String>(
                title: const Text('Pickup'),
                value: 'Pickup',
                groupValue: selectedMethod,
                onChanged: (value) {
                  selectedMethod = value!;
                  Navigator.pop(context);
                  _showCardInputDialog(
                    selectedMethod,
                    storeId,
                    storePrices,
                  ); // ✅ pass
                },
              ),
              RadioListTile<String>(
                title: const Text('Delivery'),
                value: 'Delivery',
                groupValue: selectedMethod,
                onChanged: (value) {
                  selectedMethod = value!;
                  Navigator.pop(context);
                  _showCardInputDialog(
                    selectedMethod,
                    storeId,
                    storePrices,
                  ); // ✅ pass
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCardInputDialog(
    String method,
    String storeId,
    Map<String, dynamic> storePrices,
  ) {
    final cardNumberController = TextEditingController();
    final expiryDateController = TextEditingController();
    final cvvController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter Card Information'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: cardNumberController,
                  decoration: const InputDecoration(labelText: 'Card Number'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: expiryDateController,
                  decoration: const InputDecoration(labelText: 'Expiry Date'),
                ),
                TextField(
                  controller: cvvController,
                  decoration: const InputDecoration(labelText: 'CVV'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog
                await _placeOrder(
                  method,
                  storeId,
                  Map<String, double>.from(storePrices),
                );

                if (!mounted)
                  return; // ✅ Prevent setState if widget is disposed

                setState(() {
                  cartItems.clear();
                });

                await _saveCartToPrefs();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Order placed successfully!')),
                );
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm Payment'),
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _promptStoreSelection() async {
    final response = await http.get(
      Uri.parse('http://192.168.1.4:3000/api/stores-with-items'),
    );

    if (response.statusCode != 200) {
      print('❌ Failed to fetch stores');
      return null;
    }

    final List stores = jsonDecode(response.body);
    final List<String> itemNames =
        cartItems.map((i) => i['name'].toString().toLowerCase()).toList();

    final List<Map<String, dynamic>> storeOptions = [];

    for (var store in stores) {
      final storeItems = store['items'] ?? [];
      final storeItemNames =
          storeItems.map((i) => i['name'].toString().toLowerCase()).toList();

      final hasAllItems = itemNames.every(
        (name) => storeItemNames.contains(name),
      );

      if (hasAllItems) {
        double totalPrice = 0.0;
        Map<String, double> itemPrices = {};

        for (var itemName in itemNames) {
          final matchedItem = storeItems.firstWhere(
            (i) => i['name'].toString().toLowerCase() == itemName,
            orElse: () => null,
          );

          final price =
              double.tryParse(matchedItem?['price']?.toString() ?? '0') ?? 0.0;

          itemPrices[itemName] = price;
          totalPrice += price;
        }

        storeOptions.add({
          '_id': store['_id'],
          'name': store['name'],
          'image': store['image'],
          'totalPrice': totalPrice,
          'itemPrices': itemPrices, // ✅ Needed for accurate pricing
        });
      }
    }

    if (storeOptions.isEmpty) {
      await showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text('No Stores Found'),
              content: const Text(
                'No stores currently offer all items in your cart.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
      return null;
    }

    storeOptions.sort((a, b) => a['totalPrice'].compareTo(b['totalPrice']));

    String? selectedStoreId;
    Map<String, double>? selectedPrices;

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Select a store for your order',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ...storeOptions.map((store) {
              return ListTile(
                leading:
                    store['image'] != null
                        ? Image.network(store['image'], width: 40, height: 40)
                        : const Icon(Icons.store, color: green),
                title: Text(store['name']),
                subtitle: Text(
                  'Total: \$${store['totalPrice'].toStringAsFixed(2)}',
                ),
                onTap: () {
                  selectedStoreId = store['_id'];
                  selectedPrices = Map<String, double>.from(
                    store['itemPrices'],
                  ); // ✅ Cast correctly
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ],
        );
      },
    );

    if (selectedStoreId == null || selectedPrices == null) return null;

    return {
      'storeId': selectedStoreId,
      'storePrices': Map<String, double>.from(selectedPrices!), // ✅ cast here
    };
  }

  Future<void> _placeOrder(
    String method,
    String storeId,
    Map<String, double> storePrices,
  ) async {
    final List<Map<String, dynamic>> items =
        cartItems.map((item) {
          final name = item['name'];
          final rawPrice = storePrices[name.toLowerCase()] ?? 0.0;

          return {
            'name': name,
            'price': rawPrice,
            'quantity': item['quantity'] ?? 1,
          };
        }).toList();

    final double total = items.fold(
      0.0,
      (sum, item) => sum + item['price'] * (item['quantity'] ?? 1),
    );

    final response = await http.post(
      Uri.parse('http://192.168.1.4:3000/api/orders/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': widget.userId,
        'storeId': storeId,
        'items': items,
        'total': total,
        'deliveryMethod': method, // ✅ not "method"
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final userResponse = await http.get(
        Uri.parse('http://192.168.1.4:3000/api/users/profile/${widget.userId}'),
      );

      String userName = 'Someone';
      if (userResponse.statusCode == 200) {
        final user = jsonDecode(userResponse.body);
        userName = user['name'] ?? 'Someone';
      }

      await sendNotification(
        recipientId: storeId,
        recipientModel: 'Store',
        senderId: widget.userId,
        senderModel: 'User',
        type: 'purchase',
        message:
            '$userName placed an order worth \$${total.toStringAsFixed(2)}!',
        relatedId: storeId,
      );

      print('✅ Order placed for \$${total.toStringAsFixed(2)}');
    } else {
      print('❌ Order failed: ${response.body}');
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Order placed successfully!')));
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
    await http.post(
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
  }

  Future<void> _loadIngredients() async {
    final url = Uri.parse(
      'http://192.168.1.4:3000/api/mealplans/user/${widget.userId}/grocery-list',
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
      'http://192.168.1.4:3000/api/users/${widget.userId}/available-ingredients',
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
      'http://192.168.1.4:3000/api/users/${widget.userId}/grocery-list',
    );
    final ingredients =
        groceryItems.map((item) => item['name'] as String).toList();

    final response = await http.put(
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
      'http://192.168.1.4:3000/api/users/${widget.userId}/available-ingredients',
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
      'http://192.168.1.4:3000/api/stores/$storeId/purchase',
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
      _saveIngredients();
    });
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
      'http://192.168.1.4:3000/api/stores?item=${Uri.encodeComponent(itemName)}',
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
                    await recordPurchase(store['_id'], itemName);

                    // ✅ Send notification to the store
                    await sendNotification(
                      recipientId: store['_id'],
                      recipientModel: 'Store',
                      senderId: widget.userId,
                      senderModel: 'User',
                      type: 'purchase',
                      message: 'purchased $itemName from your store!',
                      relatedId: itemName,
                    );

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
      width: 171,

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
          // 🔸 NEW AI BUTTON HERE
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => AiFromIngredientsScreen(userId: widget.userId),
                ),
              );
            },
            icon: const Icon(Icons.auto_awesome, color: Colors.white),
            label: const Text(
              'Generate with ingredients',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14, // ✅ Set your desired font size here
                fontWeight: FontWeight.w500,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          availableIngredients.map((ingredient) {
                            return Chip(
                              label: Text(
                                ingredient,
                                overflow: TextOverflow.ellipsis,
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
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    item['icon'],
                                    size: 36,
                                    color: isAvailable ? Colors.grey : green,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['name'],
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          softWrap: false,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
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
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.store,
                                          color: green,
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
                                          Icons.add_shopping_cart,
                                          color: green,
                                        ),
                                        onPressed: () {
                                          final existing = cartItems.any(
                                            (i) => i['name'] == item['name'],
                                          );
                                          if (!existing) {
                                            setState(() {
                                              cartItems.add({
                                                'name': item['name'],
                                                'price': item['price'],
                                                'storeId': null,
                                              });
                                              _saveCartToPrefs();
                                            });
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text('Added to cart'),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ],
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

      floatingActionButton: FloatingActionButton(
        backgroundColor: green,
        onPressed: _showCartModal,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.shopping_cart, color: Colors.white),
            if (cartItems.isNotEmpty)
              Positioned(
                right: 0,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '${cartItems.length}',
                    style: const TextStyle(
                      color: green,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
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
