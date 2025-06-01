import 'dart:convert';

import 'package:dishdash_web/pages/users_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;

final Color beigeBackground = const Color(0xFFF5F4F0); // Light beige
final Color beigeCard = const Color(0xFFFAF9F6); // Slightly lighter beige
final Color beigeBorder = const Color(0xFFDAD4C2); // Soft border
final Color beigeAccent = const Color(0xFFB9A67D); // Muted gold
final Color iconMuted = const Color(0xFF7C7155); // Muted brown-gray

class DashboardHome extends StatefulWidget {
  final int totalUsers;
  final int totalStores;
  final int totalRecipes;
  final List<Map<String, dynamic>> users;
  final List<Map<String, dynamic>> stores;

  const DashboardHome({
    super.key,
    required this.totalUsers,
    required this.totalStores,
    required this.totalRecipes,
    required this.users,
    required this.stores,
  });

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
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
                const adminId = '6823bb9b57548e1f37f72cc3';
                final message = _textController.text.trim();
                if (message.isEmpty) return;

                final res = await http.get(
                  Uri.parse('http://192.168.1.4:3000/api/users'),
                );

                if (res.statusCode == 200) {
                  final users = jsonDecode(res.body);
                  for (var user in users) {
                    await http.post(
                      Uri.parse('http://192.168.1.4:3000/api/notifications'),
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode({
                        'recipientId': user['_id'],
                        'recipientModel': 'User',
                        'senderId': adminId,
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

class _DashboardHomeState extends State<DashboardHome> {
  bool isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    final bgColor =
        isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF9FAFB);
    final cardColor = isDarkMode ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final subTextColor = isDarkMode ? Colors.grey[300] : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: cardColor,
        title: Row(
          children: [
            Icon(Icons.dashboard, color: textColor),
            const SizedBox(width: 10),
            Text('DishDash Admin', style: TextStyle(color: textColor)),
          ],
        ),
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(Icons.campaign_rounded, color: darkGreen),
            tooltip: 'Send Announcement',
            onPressed: () => _showAnnouncementModal(context),
          ),
          Row(
            children: [
              Icon(
                isDarkMode ? Icons.dark_mode : Icons.light_mode,
                color: textColor,
              ),
              Switch(
                value: isDarkMode,
                onChanged: (value) => setState(() => isDarkMode = value),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        '👋 Welcome to DishDash Admin!',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF304D30),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Manage users, stores, and delicious content with ease.',
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
                Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  children: [
                    buildStatCard(
                      "Total Users",
                      widget.totalUsers,
                      Icons.people,
                      Colors.deepOrange,
                      cardColor,
                      textColor,
                    ),
                    buildStatCard(
                      "Total Stores",
                      widget.totalStores,
                      Icons.store,
                      Colors.orange,
                      cardColor,
                      textColor,
                    ),
                    buildStatCard(
                      "Total Recipes",
                      widget.totalRecipes,
                      Icons.receipt,
                      Colors.green,
                      cardColor,
                      textColor,
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: buildChartCardCreative(
                        "User Distribution",
                        buildUserDistributionPie(),
                        Icons.pie_chart,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: buildChartCardCreative(
                        "Users by Role",
                        buildBarChart(),
                        Icons.bar_chart,
                        Colors.deepOrange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: buildListCard(
                        "Recent Users",
                        widget.users,
                        Icons.person_outline,
                        'name',
                        'email',
                        cardColor,
                        textColor,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: buildListCard(
                        "Recent Stores",
                        widget.stores,
                        Icons.store,
                        'name',
                        'phone',
                        cardColor,
                        textColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
    Color bgColor,
    Color textColor,
  ) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: beigeBorder),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: iconColor.withOpacity(0.1),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.7)),
          ),
          const SizedBox(height: 6),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildChartCardCreative(
    String title,
    Widget chart,
    IconData icon,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: beigeCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: beigeBorder),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: accentColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(height: 150, child: chart),
        ],
      ),
    );
  }

  Widget buildBarChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [BarChartRodData(toY: 6, color: iconMuted)],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [BarChartRodData(toY: 3, color: iconMuted)],
          ),
          BarChartGroupData(
            x: 2,
            barRods: [BarChartRodData(toY: 13, color: iconMuted)],
          ),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                switch (value.toInt()) {
                  case 0:
                    return const Text('Users');
                  case 1:
                    return const Text('Stores');
                  case 2:
                    return const Text('Recipes');
                  default:
                    return const SizedBox();
                }
              },
            ),
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget buildUserDistributionPie() {
    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(value: 6, title: 'Users', color: iconMuted),
          PieChartSectionData(value: 3, title: 'Stores', color: beigeAccent),
          PieChartSectionData(
            value: 13,
            title: 'Recipes',
            color: Colors.grey[400],
          ),
        ],
        sectionsSpace: 2,
        centerSpaceRadius: 30,
      ),
    );
  }

  Widget buildListCard(
    String title,
    List<Map<String, dynamic>> items,
    IconData icon,
    String titleKey,
    String subtitleKey,
    Color bgColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: beigeCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: beigeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconMuted, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.take(5).map((item) {
            final name = item[titleKey] ?? 'No name';
            final subtitle = item[subtitleKey] ?? '';
            final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: iconMuted.withOpacity(0.1),
                    child: Text(
                      initial,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: TextStyle(color: textColor)),
                        Text(
                          subtitle,
                          style: TextStyle(color: textColor.withOpacity(0.6)),
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
