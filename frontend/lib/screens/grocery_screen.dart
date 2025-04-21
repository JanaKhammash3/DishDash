import 'package:flutter/material.dart';
import 'package:frontend/colors.dart';

class GroceryScreen extends StatefulWidget {
  const GroceryScreen({super.key});

  @override
  State<GroceryScreen> createState() => _GroceryScreenState();
}

class _GroceryScreenState extends State<GroceryScreen> {
  final List<Map<String, dynamic>> groceryItems = [
    {'name': 'Peppers', 'price': 1.20, 'image': 'assets/peppers.png'},
    {'name': 'Eggplant', 'price': 1.10, 'image': 'assets/eggplant.png'},
    {'name': 'Onion', 'price': 0.80, 'image': 'assets/onion.png'},
    {'name': 'Tomato', 'price': 1.50, 'image': 'assets/tomato.png'},
    {'name': 'Potato', 'price': 0.90, 'image': 'assets/potato.png'},
    {'name': 'Carrot', 'price': 0.70, 'image': 'assets/carrot.png'},
  ];

  final Set<String> availableIngredients = {};

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
          onPressed: () {
            Navigator.pop(context);
          },
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
      body: ListView.builder(
        itemCount: groceryItems.length,
        itemBuilder: (context, index) {
          final item = groceryItems[index];
          final isAvailable = availableIngredients.contains(item['name']);

          return Opacity(
            opacity: isAvailable ? 0.4 : 1.0,
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                subtitle: const Text(
                  'Description',
                  style: TextStyle(color: Colors.grey),
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
                          onChanged: (_) => toggleAvailability(item['name']),
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
                                  (context) =>
                                      StorePriceScreen(itemName: item['name']),
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
    // Dummy data for demo
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
