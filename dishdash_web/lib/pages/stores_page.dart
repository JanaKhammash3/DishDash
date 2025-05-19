import 'package:flutter/material.dart';

class StoresPage extends StatefulWidget {
  const StoresPage({super.key});

  @override
  State<StoresPage> createState() => _StoresPageState();
}

class _StoresPageState extends State<StoresPage> with TickerProviderStateMixin {
  late TabController _tabController;

  final Map<String, List<Map<String, dynamic>>> itemsByCategory = {
    'Vegetables': [],
    'Fruits': [],
    'Dairy': [],
  };

  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  String selectedStatus = 'Available';

  String searchQuery = '';
  String sortOption = 'Name (A-Z)';

  double averageRating = 4.2;
  int totalPurchases = 128;

  @override
  void initState() {
    _tabController = TabController(length: itemsByCategory.length, vsync: this);
    super.initState();
  }

  void _showItemDialog(
    String category, {
    Map<String, dynamic>? editItem,
    int? index,
  }) {
    nameController.text = editItem?['name'] ?? '';
    priceController.text = editItem?['price'].toString() ?? '';
    selectedStatus = editItem?['status'] ?? 'Available';

    final List<Map<String, dynamic>> statuses = [
      {'label': 'Available', 'icon': Icons.check_circle, 'color': Colors.green},
      {'label': 'Out of Stock', 'icon': Icons.cancel, 'color': Colors.red},
      {
        'label': 'Will be Available Soon',
        'icon': Icons.access_time,
        'color': Colors.orange,
      },
    ];

    showDialog(
      context: context,
      builder:
          (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: SizedBox(
              width: 300,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        editItem == null ? 'Add New Item' : 'Edit Item',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Item Name',
                          prefixIcon: const Icon(Icons.label_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Price',
                          prefixIcon: const Icon(Icons.attach_money),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Status',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        children:
                            statuses.map((status) {
                              final isSelected =
                                  selectedStatus == status['label'];
                              return ChoiceChip(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      status['icon'],
                                      size: 18,
                                      color:
                                          isSelected
                                              ? Colors.white
                                              : status['color'],
                                    ),
                                    const SizedBox(width: 5),
                                    Text(status['label']),
                                  ],
                                ),
                                selected: isSelected,
                                selectedColor: status['color'],
                                backgroundColor: Colors.grey[200],
                                labelStyle: TextStyle(
                                  color:
                                      isSelected ? Colors.white : Colors.black,
                                ),
                                onSelected: (_) {
                                  setState(
                                    () => selectedStatus = status['label'],
                                  );
                                },
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          minimumSize: const Size.fromHeight(45),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.check),
                        label: Text(
                          editItem == null ? 'Add Item' : 'Update Item',
                        ),
                        onPressed: () {
                          final name = nameController.text.trim();
                          final price =
                              double.tryParse(priceController.text.trim()) ??
                              0.0;

                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Item name is required"),
                              ),
                            );
                            return;
                          }

                          setState(() {
                            final newItem = {
                              'name': name,
                              'price': price,
                              'status': selectedStatus,
                            };

                            if (editItem != null && index != null) {
                              itemsByCategory[category]![index] = newItem;
                            } else {
                              itemsByCategory[category]?.add(newItem);
                            }
                          });

                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }

  Color? _getStatusColor(String status) {
    switch (status) {
      case 'Available':
        return Colors.green[200];
      case 'Out of Stock':
        return Colors.red[200];
      case 'Will be Available Soon':
        return Colors.orange[200];
      default:
        return Colors.grey[200];
    }
  }

  Widget _buildCategoryTab(String category) {
    List<Map<String, dynamic>> items = List.from(itemsByCategory[category]!);

    // Apply search
    if (searchQuery.isNotEmpty) {
      items =
          items
              .where(
                (item) => item['name'].toString().toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ),
              )
              .toList();
    }

    // Apply sort
    items.sort((a, b) {
      switch (sortOption) {
        case 'Price (Low-High)':
          return a['price'].compareTo(b['price']);
        case 'Price (High-Low)':
          return b['price'].compareTo(a['price']);
        case 'Name (Z-A)':
          return b['name'].compareTo(a['name']);
        default: // Name (A-Z)
          return a['name'].compareTo(b['name']);
      }
    });

    final total = items.length;
    final available = items.where((e) => e['status'] == 'Available').length;
    final totalValue = items.fold(0.0, (sum, item) => sum + item['price']);

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search items...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 12,
                    ),
                  ),
                  onChanged: (val) {
                    setState(() => searchQuery = val);
                  },
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: sortOption,
                onChanged: (val) => setState(() => sortOption = val!),
                items:
                    [
                          'Name (A-Z)',
                          'Name (Z-A)',
                          'Price (Low-High)',
                          'Price (High-Low)',
                        ]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Card(
            color: Colors.grey[200],
            child: ListTile(
              title: Text('$total items | \$${totalValue.toStringAsFixed(2)}'),
              subtitle: Text(
                '$available available (${(available / (total == 0 ? 1 : total) * 100).toStringAsFixed(0)}%)',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.green),
                onPressed: () => _showItemDialog(category),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (_, i) {
                final item = items[i];
                final originalIndex = itemsByCategory[category]!.indexOf(item);
                return Stack(
                  children: [
                    if (item['status'] == 'Out of Stock')
                      Positioned.fill(
                        child: Container(
                          color: Colors.white.withOpacity(0.6),
                          child: const Center(
                            child: Icon(
                              Icons.block,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                    ListTile(
                      title: Text(item['name']),
                      subtitle: Text('\$${item['price']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Chip(
                            label: Text(item['status']),
                            backgroundColor: _getStatusColor(item['status']),
                          ),
                          const SizedBox(width: 8),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'Edit') {
                                _showItemDialog(
                                  category,
                                  editItem: item,
                                  index: originalIndex,
                                );
                              } else if (value == 'Delete') {
                                setState(() {
                                  itemsByCategory[category]!.removeAt(
                                    originalIndex,
                                  );
                                });
                              }
                            },
                            itemBuilder:
                                (context) => [
                                  const PopupMenuItem(
                                    value: 'Edit',
                                    child: Text('Edit'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'Delete',
                                    child: Text('Delete'),
                                  ),
                                ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardStats() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder:
                      (_) => AlertDialog(
                        title: const Text("Ratings"),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            ListTile(title: Text("⭐ 5 - User A")),
                            ListTile(title: Text("⭐ 4 - User B")),
                            ListTile(title: Text("⭐ 3 - User C")),
                          ],
                        ),
                      ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Average Rating',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$averageRating ⭐',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder:
                      (_) => AlertDialog(
                        title: const Text("Purchases"),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            ListTile(title: Text("🛒 User A bought 3 items")),
                            ListTile(title: Text("🛒 User B bought 5 items")),
                            ListTile(title: Text("🛒 User C bought 1 item")),
                          ],
                        ),
                      ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Total Purchases',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalPurchases 🛒',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
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
        title: const Text('Store Items Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: itemsByCategory.keys.map((e) => Tab(text: e)).toList(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children:
                  itemsByCategory.keys
                      .map((category) => _buildCategoryTab(category))
                      .toList(),
            ),
          ),
          _buildDashboardStats(),
        ],
      ),
    );
  }
}
