// ✅ Updated AdminDashboardScreen (same logic, better UI/UX)
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:frontend/colors.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int totalUsers = 0;
  int totalStores = 0;
  int totalRecipes = 0;
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> stores = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    setState(() => isLoading = true);
    try {
      final userRes = await http.get(
        Uri.parse('http://192.168.68.61:3000/api/users'),
      );
      final storeRes = await http.get(
        Uri.parse('http://192.168.68.61:3000/api/stores'),
      );
      final recipeRes = await http.get(
        Uri.parse('http://192.168.68.61:3000/api/recipes'),
      );

      if (userRes.statusCode == 200 &&
          storeRes.statusCode == 200 &&
          recipeRes.statusCode == 200) {
        final userData = jsonDecode(userRes.body) as List;
        final storeData = jsonDecode(storeRes.body) as List;
        final recipeData = jsonDecode(recipeRes.body) as List;

        setState(() {
          users = userData.cast<Map<String, dynamic>>();
          stores = storeData.cast<Map<String, dynamic>>();
          totalUsers = users.length;
          totalStores = stores.length;
          totalRecipes = recipeData.length;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to fetch data');
      }
    } catch (e) {
      print('Dashboard error: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _showAnnouncementModal(BuildContext context) {
    final TextEditingController _textController = TextEditingController();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('📢 Send Announcement'),
            content: TextField(
              controller: _textController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Write your message here...',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                ),
                onPressed: () async {
                  final message = _textController.text.trim();
                  if (message.isEmpty) return;

                  final res = await http.get(
                    Uri.parse('http://192.168.68.61:3000/api/users'),
                  );
                  if (res.statusCode == 200) {
                    final users = jsonDecode(res.body);
                    for (var user in users) {
                      await http.post(
                        Uri.parse(
                          'http://192.168.68.61:3000/api/notifications',
                        ),
                        headers: {'Content-Type': 'application/json'},
                        body: jsonEncode({
                          'recipientId': user['_id'],
                          'recipientModel': 'User',
                          'senderModel': 'Admin',
                          'type': 'Alerts',
                          'message': message,
                        }),
                      );
                    }
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Announcement sent to all users'),
                      ),
                    );
                  } else {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('❌ Failed to fetch users')),
                    );
                  }
                },
                child: const Text(
                  'Announce',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: green,
        title: const Text(
          'DishDash Admin',
          style: TextStyle(color: Colors.white),
        ),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.campaign, color: Colors.white),
            onPressed: () => _showAnnouncementModal(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: logout,
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildWelcomeBanner(),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        buildStatCard(
                          "Total Users",
                          totalUsers,
                          Icons.people,
                          Colors.deepOrange,
                        ),
                        buildStatCard(
                          "Total Stores",
                          totalStores,
                          Icons.store,
                          Colors.orange,
                        ),
                        buildStatCard(
                          "Total Recipes",
                          totalRecipes,
                          Icons.receipt,
                          Colors.green,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Column(
                      children: [
                        buildChartCard(
                          "User Distribution",
                          buildUserDistributionPie(),
                          Icons.pie_chart,
                          Colors.blue,
                          width:
                              MediaQuery.of(context).size.width -
                              40, // Full width with padding
                        ),
                        const SizedBox(height: 16),
                        buildChartCard(
                          "Users by Role",
                          buildBarChart(),
                          Icons.bar_chart,
                          Colors.deepOrange,
                          width: MediaQuery.of(context).size.width - 40,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: buildListCard(
                            "Recent Users",
                            users,
                            Icons.person_outline,
                            'name',
                            'email',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: buildListCard(
                            "Recent Stores",
                            stores,
                            Icons.store,
                            'name',
                            'phone',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildWelcomeBanner() {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: const DecorationImage(
          image: AssetImage('assets/cover.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: const Align(
          alignment: Alignment.centerLeft,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome to DishDash Admin!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Manage users, stores, and delicious content.',
                style: TextStyle(fontSize: 13, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildStatCard(
    String title,
    int count,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: iconColor.withOpacity(0.1),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget buildChartCard(
    String title,
    Widget chart,
    IconData icon,
    Color color, {
    double width = 300,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 220, // Ensure enough space for charts to render safely
              height: 150,
              child: chart,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildUserDistributionPie() {
    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(
            value: totalUsers.toDouble(),
            title: 'Users',
            color: Colors.green,
            titleStyle: const TextStyle(fontSize: 12, color: Colors.white),
          ),
          PieChartSectionData(
            value: totalStores.toDouble(),
            title: 'Stores',
            color: Colors.orange,
            titleStyle: const TextStyle(fontSize: 12, color: Colors.white),
          ),
          PieChartSectionData(
            value: totalRecipes.toDouble(),
            title: 'Recipes',
            color: Colors.blue,
            titleStyle: const TextStyle(fontSize: 12, color: Colors.white),
          ),
        ],
        sectionsSpace: 2,
        centerSpaceRadius: 30,
      ),
    );
  }

  Widget buildBarChart() {
    return BarChart(
      BarChartData(
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: totalUsers.toDouble(),
                color: Colors.deepOrange,
              ),
            ],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(
                toY: totalStores.toDouble(),
                color: Colors.deepOrange,
              ),
            ],
          ),
          BarChartGroupData(
            x: 2,
            barRods: [
              BarChartRodData(
                toY: totalRecipes.toDouble(),
                color: Colors.deepOrange,
              ),
            ],
          ),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                switch (value.toInt()) {
                  case 0:
                    return const Text('Users', style: TextStyle(fontSize: 10));
                  case 1:
                    return const Text('Stores', style: TextStyle(fontSize: 10));
                  case 2:
                    return const Text(
                      'Recipes',
                      style: TextStyle(fontSize: 10),
                    );
                  default:
                    return const SizedBox();
                }
              },
            ),
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: false),
      ),
    );
  }

  Widget buildListCard(
    String title,
    List<Map<String, dynamic>> items,
    IconData icon,
    String titleKey,
    String subtitleKey,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.black54),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          ...items.take(5).map((item) {
            final name = item[titleKey] ?? 'No name';
            final subtitle = item[subtitleKey] ?? '';
            final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.blueAccent.withOpacity(0.15),
                    child: Text(initial),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          subtitle,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
