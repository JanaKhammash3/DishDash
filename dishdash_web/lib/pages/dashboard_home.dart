import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

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
        title: Text('DishDash Admin', style: TextStyle(color: textColor)),
        elevation: 1,
        actions: [
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
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(20),
                    image: const DecorationImage(
                      image: AssetImage('assets/cover.png'),
                      fit: BoxFit.cover,
                      alignment: Alignment.centerRight,
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    padding: const EdgeInsets.all(12),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'Welcome to DishDash Admin!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF304D30),
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Manage users, stores, and delicious content.',
                          style: TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                      ],
                    ),
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
        gradient: LinearGradient(
          colors: [bgColor.withOpacity(0.05), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Icon(icon, size: 80, color: iconColor.withOpacity(0.1)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 28, color: iconColor),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: textColor.withOpacity(0.7),
                ),
              ),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
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
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [Colors.white, accentColor.withOpacity(0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Icon(icon, size: 80, color: accentColor.withOpacity(0.06)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: accentColor),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(height: 150, child: chart),
            ],
          ),
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
            barRods: [BarChartRodData(toY: 6, color: Colors.deepOrange)],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [BarChartRodData(toY: 3, color: Colors.deepOrange)],
          ),
          BarChartGroupData(
            x: 2,
            barRods: [BarChartRodData(toY: 13, color: Colors.deepOrange)],
          ),
        ],
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
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
        ),
      ),
    );
  }

  Widget buildUserDistributionPie() {
    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(value: 6, title: 'Users', color: Colors.green),
          PieChartSectionData(value: 3, title: 'Stores', color: Colors.orange),
          PieChartSectionData(value: 13, title: 'Recipes', color: Colors.blue),
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
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: textColor.withOpacity(0.7), size: 20),
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
                color: Colors.grey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.blueAccent.withOpacity(0.2),
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
                        Text(
                          name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
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
