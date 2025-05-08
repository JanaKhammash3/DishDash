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
                  'image': _getImagePath(name.toLowerCase()),
                },
              )
              .toList();
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

  String _getImagePath(String name) {
    switch (name) {
      case 'tomato':
        return 'assets/tomato.png';
      case 'onion':
        return 'assets/onion.png';
      case 'potato':
        return 'assets/potato.png';
      case 'carrot':
        return 'assets/carrot.png';
      case 'peppers':
      case 'pepper':
        return 'assets/peppers.png';
      case 'eggplant':
        return 'assets/eggplant.png';
      default:
        return 'assets/placeholder.png';
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
            icon: const Icon(Icons.search, color: maroon),
            onPressed: () {},
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
                        leading: ColorFiltered(
                          colorFilter:
                              isAvailable
                                  ? const ColorFilter.mode(
                                    Colors.grey,
                                    BlendMode.saturation,
                                  )
                                  : const ColorFilter.mode(
                                    Colors.transparent,
                                    BlendMode.multiply,
                                  ),
                          child: Image.asset(item['image'], height: 50),
                        ),
                        title: Text(
                          item['name'],
                          style: const TextStyle(color: Colors.black),
                        ),
                        subtitle: Text(
                          '\$${item['price'].toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Theme(
                              data: Theme.of(
                                context,
                              ).copyWith(unselectedWidgetColor: Colors.grey),
                              child: Transform.scale(
                                scale: 1.2,
                                child: Checkbox(
                                  shape: const CircleBorder(),
                                  value: isAvailable,
                                  activeColor: Colors.green,
                                  onChanged:
                                      (_) => toggleAvailability(item['name']),
                                ),
                              ),
                            ),
                            if (!isAvailable)
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
    final List<Map<String, dynamic>> storePrices = [
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
            title: Text(store['store']),
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
