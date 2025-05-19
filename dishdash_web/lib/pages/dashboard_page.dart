import 'dart:convert';
import 'package:flutter/material.dart';
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

  bool isSidebarExpanded = false;

  final Color fadedGreen = const Color(0xFF3E5E3E); // hover background

  @override
  void initState() {
    super.initState();
    fetchStats();
  }

  Future<void> fetchStats() async {
    try {
      final userRes = await http.get(
        Uri.parse('http://192.168.1.4:3000/api/users'),
      );
      final storeRes = await http.get(
        Uri.parse('http://192.168.1.4:3000/api/stores'),
      );
      final recipeRes = await http.get(
        Uri.parse('http://192.168.1.4:3000/api/recipes'),
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
          MouseRegion(
            onEnter: (_) => setState(() => isSidebarExpanded = true),
            onExit: (_) => setState(() => isSidebarExpanded = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isSidebarExpanded ? 200 : 70,
              color: const Color(0xFF1E3920),
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  if (isSidebarExpanded)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        children: [
                          // Bigger logo
                          Image.asset(
                            'assets/Login.png',
                            width: 80,
                            height: 80,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.admin_panel_settings,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Admin Panel',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  else
                    const Icon(Icons.admin_panel_settings, color: Colors.white),

                  const SizedBox(height: 30),

                  SidebarItem(
                    icon: Icons.dashboard,
                    label: 'Dashboard',
                    isExpanded: isSidebarExpanded,
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
                    icon: Icons.people,
                    label: 'Users',
                    isExpanded: isSidebarExpanded,
                    onTap: () => setState(() => currentPage = UsersPage()),
                  ),
                  SidebarItem(
                    icon: Icons.store,
                    label: 'Stores',
                    isExpanded: isSidebarExpanded,
                    onTap: () {},
                  ),
                  SidebarItem(
                    icon: Icons.receipt_long,
                    label: 'Recipes',
                    isExpanded: isSidebarExpanded,
                    onTap: () {},
                  ),
                  SidebarItem(
                    icon: Icons.flag,
                    label: 'Challenges',
                    isExpanded: isSidebarExpanded,
                    onTap: () {},
                  ),
                  const Spacer(),
                  SidebarItem(
                    icon: Icons.logout,
                    label: 'Logout',
                    isExpanded: isSidebarExpanded,
                    onTap: logout,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          // Main content
          Expanded(child: currentPage),
        ],
      ),
    );
  }
}

class SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isExpanded;
  final Color? color;

  const SidebarItem({
    required this.icon,
    required this.label,
    this.onTap,
    required this.isExpanded,
    this.color,
  });

  @override
  State<SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<SidebarItem> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = isHovered ? const Color(0xFF3E5E3E) : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          color: bgColor,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            mainAxisAlignment:
                widget.isExpanded
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: widget.color ?? Colors.white),
              if (widget.isExpanded) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.label,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: TextStyle(color: widget.color ?? Colors.white),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
