import 'package:flutter/material.dart';
import 'package:frontend/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GroceryScreen extends StatefulWidget {
  const GroceryScreen({super.key});

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
    final prefs = await SharedPreferences.getInstance();
    final List<String> ingredients =
        prefs.getStringList('groceryIngredients') ?? [];

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
  }

  Future<void> _saveIngredients() async {
    final prefs = await SharedPreferences.getInstance();
    final updated = groceryItems.map((item) => item['name'] as String).toList();
    await prefs.setStringList('groceryIngredients', updated);
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
      body:
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
                              icon: const Icon(Icons.store, color: maroon),
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
                              icon: const Icon(Icons.delete, color: maroon),
                              onPressed: () => _removeIngredient(item['name']),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}

class StorePriceScreen extends StatelessWidget {
  final String itemName;
  const StorePriceScreen({super.key, required this.itemName});

  @override
  Widget build(BuildContext context) {
    final storePrices = [
      {'store': 'Store A', 'price': 1.50},
      {'store': 'Store B', 'price': 1.40},
      {'store': 'Store C', 'price': 1.60},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('$itemName Prices'),
        backgroundColor: Colors.white,
        foregroundColor: maroon,
      ),
      body: ListView.builder(
        itemCount: storePrices.length,
        itemBuilder: (context, index) {
          final store = storePrices[index];
          return ListTile(
            leading: const Icon(Icons.store, color: maroon),
            title: Text(store['store']?.toString() ?? 'Unknown Store'),
            trailing: Text(
              '\$${store['price']}',
              style: const TextStyle(color: Colors.black),
            ),
          );
        },
      ),
    );
  }
}
