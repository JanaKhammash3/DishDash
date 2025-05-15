import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_home.dart';
import 'users_page.dart';

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
  Widget currentPage = const Center(child: CircularProgressIndicator());

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

          currentPage = DashboardHome(
            totalUsers: totalUsers,
            totalStores: totalStores,
            totalRecipes: totalRecipes,
            users: users,
            stores: stores,
          );
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
                SidebarItem(
                  title: 'Dashboard',
                  onTap: () {
                    setState(() {
                      currentPage = DashboardHome(
                        totalUsers: totalUsers,
                        totalStores: totalStores,
                        totalRecipes: totalRecipes,
                        users: users,
                        stores: stores,
                      );
                    });
                  },
                ),
                SidebarItem(
                  title: 'Users',
                  onTap: () {
                    setState(() {
                      currentPage = UsersPage();
                    });
                  },
                ),
                SidebarItem(title: 'Stores', onTap: () {}),
                SidebarItem(title: 'Recipes', onTap: () {}),
                SidebarItem(title: 'Challenges', onTap: () {}),
                const Spacer(),
                TextButton(
                  onPressed: logout,
                  child: const Text(
                    'Logout',
                    style: TextStyle(
                      color: const Color.fromARGB(255, 153, 28, 19),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Main content
          Expanded(child: currentPage),
        ],
      ),
    );
  }
}

class SidebarItem extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  const SidebarItem({required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(title, style: const TextStyle(color: Colors.white)),
        onTap: onTap,
      ),
    );
  }
}
