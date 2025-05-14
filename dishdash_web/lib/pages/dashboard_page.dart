import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DashboardPage extends StatefulWidget {
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int totalUsers = 0;
  int totalStores = 0;
  int totalRecipes = 0;
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> stores = [];

  @override
  void initState() {
    super.initState();
    fetchStats();
  }

  Future<void> fetchStats() async {
    try {
      final userRes = await http.get(
        Uri.parse('http://192.168.68.60:3000/api/users'),
      );
      final storeRes = await http.get(
        Uri.parse('http://192.168.68.60:3000/api/stores'),
      );
      final recipeRes = await http.get(
        Uri.parse('http://192.168.68.60:3000/api/recipes'),
      );

      if (userRes.statusCode == 200 &&
          storeRes.statusCode == 200 &&
          recipeRes.statusCode == 200) {
        setState(() {
          users = List<Map<String, dynamic>>.from(jsonDecode(userRes.body));
          stores = List<Map<String, dynamic>>.from(jsonDecode(storeRes.body));
          totalUsers = users.length;
          totalStores = stores.length;
          totalRecipes = jsonDecode(recipeRes.body).length;
        });
      }
    } catch (e) {
      print('Error fetching stats: $e');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF304D30),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 200,
            color: const Color(0xFF1E3920),
            padding: const EdgeInsets.only(top: 40, left: 16, right: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                const SidebarItem(title: 'Dashboard', selected: true),
                const SidebarItem(title: 'Users'),
                const SidebarItem(title: 'Stores'),
                const SidebarItem(title: 'Recipes'),
                const SidebarItem(title: 'Challenges'),
                const Spacer(),
                TextButton(
                  onPressed: logout,
                  child: const Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Main content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      StatCard(title: 'Total Users', count: totalUsers),
                      StatCard(title: 'Total Stores', count: totalStores),
                      StatCard(title: 'Total Recipes', count: totalRecipes),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: ChartCard(
                          title: 'User Distribution',
                          isPie: true,
                          pieData: [
                            PieChartSectionData(
                              color: Colors.green,
                              value: totalUsers.toDouble(),
                              title: '$totalUsers',
                            ),
                            PieChartSectionData(
                              color: Colors.orange,
                              value: totalStores.toDouble(),
                              title: '$totalStores',
                            ),
                            PieChartSectionData(
                              color: Colors.blue,
                              value: totalRecipes.toDouble(),
                              title: '$totalRecipes',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: BarChartCard(
                          title: 'Users by Role',
                          data: [
                            {'label': 'Users', 'value': totalUsers},
                            {'label': 'Stores', 'value': totalStores},
                            {'label': 'Recipes', 'value': totalRecipes},
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: InfoCard(
                          title: 'Recent Users',
                          items:
                              users
                                  .take(5)
                                  .map((u) => '${u['name']} — ${u['email']}')
                                  .toList(),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: InfoCard(
                          title: 'Recent Stores',
                          items:
                              stores
                                  .take(5)
                                  .map(
                                    (s) =>
                                        '${s['name']} — ${s['telephone'] ?? 'N/A'}',
                                  )
                                  .toList(),
                        ),
                      ),
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
}

class SidebarItem extends StatelessWidget {
  final String title;
  final bool selected;
  const SidebarItem({required this.title, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration:
          selected
              ? BoxDecoration(
                color: const Color(0xFF3F5F3B),
                borderRadius: BorderRadius.circular(10),
              )
              : null,
      child: ListTile(
        title: Text(title, style: const TextStyle(color: Colors.white)),
        onTap: () {},
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final int count;
  const StatCard({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 100,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF557A59),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class ChartCard extends StatelessWidget {
  final String title;
  final bool isPie;
  final List<PieChartSectionData> pieData;
  const ChartCard({
    required this.title,
    this.isPie = false,
    required this.pieData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          Expanded(child: PieChart(PieChartData(sections: pieData))),
        ],
      ),
    );
  }
}

class BarChartCard extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> data;
  const BarChartCard({required this.title, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, _) {
                        return Text(data[val.toInt()]['label']);
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                barGroups:
                    data
                        .asMap()
                        .entries
                        .map(
                          (entry) => BarChartGroupData(
                            x: entry.key,
                            barRods: [
                              BarChartRodData(
                                toY: entry.value['value'].toDouble(),
                                color: Colors.red,
                              ),
                            ],
                          ),
                        )
                        .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final String title;
  final List<String> items;
  const InfoCard({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 140),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          ...items.map((e) => Text(e)).toList(),
        ],
      ),
    );
  }
}
