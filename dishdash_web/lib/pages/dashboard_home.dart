import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardHome extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Padding(
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
                            (s) => '${s['name']} — ${s['telephone'] ?? 'N/A'}',
                          )
                          .toList(),
                ),
              ),
            ],
          ),
        ],
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
  final List<PieChartSectionData> pieData;
  const ChartCard({required this.title, required this.pieData});

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
