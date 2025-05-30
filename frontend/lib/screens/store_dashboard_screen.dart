// Full StoreDashboardScreen with Ratings (User Avatars + Names) & Exportable Items + Profile Image Upload + Loading

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend/screens/store_notifications_screen.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/colors.dart';
import 'package:fl_chart/fl_chart.dart';

class StoreDashboardScreen extends StatefulWidget {
  final String storeId;
  const StoreDashboardScreen({super.key, required this.storeId});
  @override
  State<StoreDashboardScreen> createState() => _StoreDashboardScreenState();
}

class _StoreDashboardScreenState extends State<StoreDashboardScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic> userMap = {};
  List<Map<String, dynamic>> items = [];
  Map<String, dynamic> storeData = {};
  final ImagePicker picker = ImagePicker();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  bool isUploading = false;
  late TabController _tabController;
  List<Map<String, dynamic>> _purchaseNotifs = [];
  List<Map<String, dynamic>> _ratingNotifs = [];
  bool isLoading = false;
  int unreadCount = 0;

  final categoryIcons = {
    'Vegetables': Icons.eco,
    'Fruits': Icons.local_grocery_store,
    'Meat': Icons.restaurant_menu,
    'Dairy': Icons.icecream,
    'Bakery': Icons.bakery_dining,
    'Seafood': Icons.set_meal,
    'Beverages': Icons.local_drink,
    'Frozen': Icons.ac_unit,
    'Other': Icons.category,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchStoreInfo();
    fetchUsers();
    fetchUnreadCount();
    fetchNotifications();
  }

  Future<void> fetchUsers() async {
    final url = Uri.parse('http://192.168.1.4:3000/api/users');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        setState(() {
          userMap = {for (var user in data) user['_id']: user};
        });
      }
    } catch (e) {
      debugPrint('Error fetching users: $e');
    }
  }

  Future<void> fetchUnreadCount() async {
    try {
      final res = await http.get(
        Uri.parse(
          'http://192.168.1.4:3000/api/notifications/${widget.storeId}/unread-count',
        ),
      );

      debugPrint('📡 Response status: ${res.statusCode}');
      debugPrint('📡 Response body: ${res.body}');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final parsedCount = int.tryParse(data['count'].toString()) ?? 0;
        debugPrint('✅ Parsed unreadCount: $parsedCount');

        setState(() {
          unreadCount = parsedCount;
        });
      } else {
        debugPrint('⚠️ Failed to fetch unread count');
      }
    } catch (e) {
      debugPrint('❌ Error in fetchUnreadCount: $e');
    }
  }

  Map<String, List<Map<String, dynamic>>> categorizedItems = {};

  Future<void> fetchStoreInfo() async {
    final url = Uri.parse(
      'http://192.168.1.4:3000/api/stores/${widget.storeId}',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Group items by category
        final fetchedItems = List<Map<String, dynamic>>.from(
          data['items'] ?? [],
        );

        // Group items by category
        final Map<String, List<Map<String, dynamic>>> grouped = {};
        for (var item in fetchedItems) {
          final category = item['category'] ?? 'Uncategorized';
          if (!grouped.containsKey(category)) {
            grouped[category] = [];
          }
          grouped[category]!.add(item);
        }

        setState(() {
          storeData = data;
          items = fetchedItems; // ✅ Make sure to store raw items too
          categorizedItems = grouped;
        });
      }
    } catch (e) {
      debugPrint('Error fetching store info: $e');
    }
  }

  List<Map<String, dynamic>> _notifications = [];

  Future<void> fetchNotifications() async {
    setState(() => isLoading = true);
    final url = Uri.parse(
      'http://192.168.1.4:3000/api/stores/${widget.storeId}/notifications',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = List<Map<String, dynamic>>.from(jsonDecode(response.body));
        setState(() {
          _notifications = data;
          _purchaseNotifs = data.where((n) => n['type'] == 'purchase').toList();
          _ratingNotifs = data.where((n) => n['type'] == 'rating').toList();
        });
      }
    } catch (e) {
      debugPrint('❌ Error fetching notifications: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showNotificationsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (_) => DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const TabBar(
                  labelColor: green,
                  unselectedLabelColor: Colors.grey,
                  tabs: [
                    Tab(icon: Icon(Icons.shopping_cart), text: 'Purchases'),
                    Tab(icon: Icon(Icons.star), text: 'Ratings'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildNotificationList(_purchaseNotifs),
                      _buildNotificationList(_ratingNotifs),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildNotificationList(List<Map<String, dynamic>> notifs) {
    return notifs.isEmpty
        ? const Center(child: Text('No notifications yet.'))
        : ListView.builder(
          itemCount: notifs.length,
          itemBuilder: (_, index) {
            final n = notifs[index];
            final sender = n['senderId'] ?? {};
            final name = sender['name'] ?? 'Unknown';
            final avatar = sender['avatar'] ?? '';
            final imageProvider =
                avatar.isNotEmpty && avatar.contains(',')
                    ? MemoryImage(base64Decode(avatar.split(',').last))
                    : const AssetImage('assets/profile.png');

            return ListTile(
              leading: CircleAvatar(
                backgroundImage: imageProvider as ImageProvider,
              ),
              title: Text(n['message'] ?? ''),
              subtitle: Text(name),
              trailing: Icon(
                n['type'] == 'purchase' ? Icons.shopping_cart : Icons.star,
                color: green,
              ),
            );
          },
        );
  }

  _getCategoryIcon(String category) {
    switch (category) {
      case 'Vegetables':
        return Icons.grass;
      case 'Fruits':
        return Icons.apple;
      case 'Dairy':
        return Icons.icecream;
      case 'Meat':
        return Icons.set_meal;
      case 'Grains & Pasta':
        return Icons.rice_bowl;
      case 'Condiments':
        return Icons.soup_kitchen;
      case 'Canned Goods':
        return Icons.lunch_dining;
      case 'Frozen Food':
        return Icons.ac_unit;
      default:
        return Icons.category;
    }
  }

  Widget _buildItemsByCategorySection() {
    if (categorizedItems.isEmpty) {
      return const Text('No items found.');
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      children:
          categorizedItems.entries.map((entry) {
            final category = entry.key;
            final items = entry.value;
            final icon = _getCategoryIcon(category);
            final count = items.length;

            // ✅ Count status types
            final available =
                items.where((item) => item['status'] == 'Available').length;
            final outOfStock =
                items.where((item) => item['status'] == 'Out of Stock').length;
            final comingSoon =
                items
                    .where((item) => item['status'] == 'Will be Available Soon')
                    .length;

            return GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder:
                      (_) => AlertDialog(
                        title: Text(category),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children:
                              items
                                  .map(
                                    (item) => ListTile(
                                      leading: const Icon(Icons.fastfood),
                                      title: Text(item['name']),
                                      subtitle: Text(
                                        'Price: \$${item['price']} • ${item['status']}',
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ),
                );
              },
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 36, color: green),
                      const SizedBox(height: 10),
                      Text(
                        category,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '$count item(s)',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      // ✅ Status summary
                      Text(
                        '✔️ $available | ❌ $outOfStock | ⏳ $comingSoon',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  Future<void> pickAndUploadImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() => isUploading = true);

    final bytes = await pickedFile.readAsBytes();
    final fileName = pickedFile.name;
    final uri = Uri.parse(
      'http://192.168.1.4:3000/api/stores/${widget.storeId}/image',
    );
    final request = http.MultipartRequest('PATCH', uri);

    request.files.add(
      http.MultipartFile.fromBytes('image', bytes, filename: fileName),
    );

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final data = json.decode(respStr);
        setState(() => storeData['image'] = data['image']);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('✅ Image uploaded')));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('❌ Upload failed')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('❌ Upload error')));
    } finally {
      setState(() => isUploading = false);
    }
  }

  void showRatingsModal() {
    final ratings = storeData['ratings'] as List<dynamic>? ?? [];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (_) => Padding(
            padding: const EdgeInsets.all(16),
            child:
                ratings.isEmpty
                    ? const Text('No ratings yet.')
                    : ListView.builder(
                      itemCount: ratings.length,
                      itemBuilder: (_, index) {
                        final r = ratings[index];
                        final userObj = r['userId'];
                        final user =
                            userObj is Map
                                ? userObj
                                : userMap[userObj?.toString()] ?? {};

                        final avatarBase64 = user['avatar']?.toString();
                        ImageProvider imageProvider;

                        if (avatarBase64 != null &&
                            avatarBase64.isNotEmpty &&
                            avatarBase64.contains(',')) {
                          try {
                            imageProvider = MemoryImage(
                              base64Decode(avatarBase64.split(',').last),
                            );
                          } catch (_) {
                            imageProvider = const AssetImage(
                              'assets/profile.png',
                            );
                          }
                        } else {
                          imageProvider = const AssetImage(
                            'assets/profile.png',
                          );
                        }

                        return ListTile(
                          leading: CircleAvatar(backgroundImage: imageProvider),
                          title: Text(user['name']?.toString() ?? 'User'),
                          trailing: Text('⭐ ${r['value']?.toString() ?? '-'}'),
                        );
                      },
                    ),
          ),
    );
  }

  void showItemsModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder:
          (_) => Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Items by Category",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildItemsByCategorySection(),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void showPurchasesModal() {
    final purchases = storeData['purchases'] as List<dynamic>? ?? [];

    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final p in purchases) {
      final userObj = p['userId'];
      final userId = userObj is Map ? userObj['_id'] : userObj;
      grouped.putIfAbsent(userId, () => []).add({
        ...p,
        'user': userObj is Map ? userObj : userMap[userId],
      });
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (_) => Padding(
            padding: const EdgeInsets.all(16),
            child:
                grouped.isEmpty
                    ? const Text('No purchases yet.')
                    : ListView(
                      children:
                          grouped.entries.map((entry) {
                            final userPurchases = entry.value;
                            final userId = entry.key;
                            final user = userMap[userId] ?? {};
                            final avatarBase64 = user['avatar']?.toString();

                            ImageProvider imageProvider;
                            if (avatarBase64 != null &&
                                avatarBase64.isNotEmpty) {
                              try {
                                imageProvider = MemoryImage(
                                  base64Decode(avatarBase64.split(',').last),
                                );
                              } catch (_) {
                                imageProvider = const AssetImage(
                                  'assets/profile.png',
                                );
                              }
                            } else {
                              imageProvider = const AssetImage(
                                'assets/profile.png',
                              );
                            }

                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        CircleAvatar(
                                          backgroundImage: imageProvider,
                                          radius: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            user['name']?.toString() ??
                                                'Anonymous',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 12),
                                    ...userPurchases.map((p) {
                                      final itemId = p['item']?.toString();
                                      final quantity =
                                          p['quantity']?.toString() ?? '1';
                                      final date =
                                          p['date']?.toString() ??
                                          'Date unknown';

                                      final item = items.firstWhere(
                                        (i) => i['id']?.toString() == itemId,
                                        orElse: () => {},
                                      );

                                      final itemName =
                                          item['name']?.toString() ?? 'Unnamed';
                                      final price =
                                          item['price']?.toString() ?? '0.00';

                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          top: 6,
                                          left: 8,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text('Item: $itemName'),
                                            Text('Price: \$$price'),
                                            Text('Quantity: $quantity'),
                                            Text('Date: $date'),
                                            const Divider(height: 20),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                    ),
          ),
    );
  }

  Widget _infoButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceTab() {
    final purchases = storeData['purchases'] as List<dynamic>? ?? [];
    final Map<String, int> daySales = {};
    for (final p in purchases) {
      final date = DateTime.tryParse(p['date'] ?? '') ?? DateTime.now();
      final day = '${date.year}-${date.month}-${date.day}';
      daySales[day] = (daySales[day] ?? 0) + 1;
    }
    final sortedDays = daySales.keys.toList()..sort();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly Sales Overview',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                barGroups: List.generate(sortedDays.length, (index) {
                  final count = daySales[sortedDays[index]] ?? 0;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: count.toDouble(),
                        width: 16,
                        color: green,
                      ),
                    ],
                  );
                }),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < sortedDays.length) {
                          return Text(sortedDays[index].split('-').last);
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTab() {
    final ratings = storeData['ratings'] as List<dynamic>? ?? [];
    final purchases = storeData['purchases'] as List<dynamic>? ?? [];
    final ratingAverage =
        ratings.isNotEmpty
            ? ratings.map((r) => (r['value'] as num)).reduce((a, b) => a + b) /
                ratings.length
            : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey[300],
                backgroundImage:
                    storeData['image'] != null
                        ? NetworkImage(storeData['image'])
                        : null,
                child:
                    storeData['image'] == null
                        ? const Icon(Icons.storefront, size: 50)
                        : null,
              ),
              if (isUploading)
                const Positioned.fill(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              Positioned(
                bottom: 4,
                right: 4,
                child: GestureDetector(
                  onTap: pickAndUploadImage,
                  child: const CircleAvatar(
                    radius: 18,
                    backgroundColor: green,
                    child: Icon(Icons.edit, size: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            storeData['name']?.toString() ?? 'Store Name',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            storeData['telephone']?.toString() ?? 'Phone: N/A',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _infoButton(
                icon: Icons.star,
                color: Colors.amber,
                label: '${ratingAverage.toStringAsFixed(1)} / 5.0',
                onTap: showRatingsModal,
              ),
              _infoButton(
                icon: Icons.shopping_cart,
                color: green,
                label: '${purchases.length} Purchases',
                onTap: showPurchasesModal,
              ),
              _infoButton(
                icon: Icons.fastfood,
                color: Colors.deepOrange,
                label: 'Items',
                onTap: showItemsModal,
              ),
            ],
          ),
          const SizedBox(height: 30),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: Colors.white,
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Store Summary',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Items:'),
                      Text('${items.length}'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Purchases:'),
                      Text('${purchases.length}'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Avg. Rating:'),
                      Text('${ratingAverage.toStringAsFixed(1)} / 5.0'),
                    ],
                  ),
                ],
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
      backgroundColor: const Color(0xFFF9F6FD),
      appBar: AppBar(
        backgroundColor: green,
        title: const Text(
          'Store Dashboard',
          style: TextStyle(color: Colors.white),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.info), text: 'Overview'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Performance'),
          ],
        ),
        actions: [
          // ✅ Notification Icon with Badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) =>
                              StoreNotificationsScreen(storeId: widget.storeId),
                    ),
                  ).then((_) {
                    fetchUnreadCount(); // ✅ Ensures it's called AFTER screen pops
                  });
                },
              ),

              if (unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),

          // Existing Popup Menu
          PopupMenuButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            itemBuilder:
                (_) => [
                  PopupMenuItem(
                    child: const Text('Logout'),
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                  ),
                ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildInfoTab(), _buildPerformanceTab()],
      ),
    );
  }
}
