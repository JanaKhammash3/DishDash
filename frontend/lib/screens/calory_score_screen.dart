// Calory Score Screen - Polished with Professional UI Theme
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:frontend/colors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

class CaloryScoreScreen extends StatefulWidget {
  final String userId;
  const CaloryScoreScreen({super.key, required this.userId});

  @override
  State<CaloryScoreScreen> createState() => _CaloryScoreScreenState();
}

class _CaloryScoreScreenState extends State<CaloryScoreScreen> {
  int totalCaloriesThisWeek = 0;
  List<int> dailyCalories = List.filled(7, 0);
  bool isLoading = true;

  TextEditingController _targetController = TextEditingController();
  int weeklyTarget = 10000;

  final Color darkBlue = const Color(0xFF1E293B);
  final Color softWhite = const Color(0xFFF9FAFB);
  final Color accentGreen = const Color(0xFF10B981);
  final Color accentRed = const Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    loadWeeklyTarget();
    fetchAndSetCalorieData();
  }

  Future<void> loadWeeklyTarget() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt('weeklyTarget_${widget.userId}');
    if (saved != null) {
      setState(() {
        weeklyTarget = saved;
      });
    }
  }

  Future<void> saveWeeklyTarget(int newTarget) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('weeklyTarget_${widget.userId}', newTarget);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Target updated to $newTarget kcal!")),
    );
  }

  Future<Map<String, dynamic>> fetchCalorieData() async {
    final response = await http.get(
      Uri.parse(
        'http://192.168.1.4:3000/api/mealplans/weekly-calories/${widget.userId}',
      ),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return {
        'totalCalories': data['totalCalories'],
        'dailyCalories': List<int>.from(data['dailyCalories']),
      };
    } else {
      throw Exception('Failed to load calorie data');
    }
  }

  Future<void> fetchAndSetCalorieData() async {
    try {
      final data = await fetchCalorieData();
      setState(() {
        totalCaloriesThisWeek = data['totalCalories'];
        dailyCalories = data['dailyCalories'];
        isLoading = false;
      });
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  void _showTargetDialog() {
    _targetController.text = weeklyTarget.toString();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (_) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Set Weekly Calorie Target',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _targetController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Enter kcal (e.g. 10000)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.flag),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkBlue,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () {
                    final newTarget = int.tryParse(_targetController.text);
                    if (newTarget != null && newTarget > 0) {
                      saveWeeklyTarget(newTarget);
                      setState(() => weeklyTarget = newTarget);
                      Navigator.pop(context);
                      fetchAndSetCalorieData();
                    }
                  },
                  label: const Text(
                    "Save Target",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildLoadingState() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            height: 250,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final percent = totalCaloriesThisWeek / weeklyTarget;
    final kcalLeft = (weeklyTarget - totalCaloriesThisWeek).clamp(
      0,
      weeklyTarget,
    );

    return Scaffold(
      backgroundColor: softWhite,
      appBar: AppBar(
        backgroundColor: darkBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, 'refresh'),
        ),
        title: const Text(
          'Calorie Score',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: _showTargetDialog,
          ),
        ],
      ),
      body:
          isLoading
              ? _buildLoadingState()
              : RefreshIndicator(
                onRefresh: fetchAndSetCalorieData,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween(
                              begin: 0,
                              end: percent.clamp(0.0, 1.0),
                            ),
                            duration: const Duration(milliseconds: 800),
                            builder:
                                (context, value, _) => Column(
                                  children: [
                                    CircularPercentIndicator(
                                      radius: 80,
                                      lineWidth: 12,
                                      percent: value,
                                      center: Text(
                                        '${(value * 100).toStringAsFixed(1)}%',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      progressColor:
                                          value >= 1.0 ? accentGreen : darkBlue,
                                      backgroundColor: Colors.grey.shade300,
                                      circularStrokeCap:
                                          CircularStrokeCap.round,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      '$totalCaloriesThisWeek / $weeklyTarget kcal',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey.shade800,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$kcalLeft kcal remaining',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    if (value >= 1.0)
                                      AnimatedScale(
                                        scale: 1.1,
                                        duration: const Duration(
                                          milliseconds: 500,
                                        ),
                                        child: Container(
                                          margin: const EdgeInsets.only(
                                            top: 10,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: accentGreen.withOpacity(
                                              0.15,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                          ),
                                          child: const Text(
                                            '🎉 Goal Achieved!',
                                            style: TextStyle(
                                              color: Color(0xFF10B981),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Weekly Intake Trend',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AspectRatio(
                      aspectRatio: 1.8,
                      child: LineChart(
                        LineChartData(
                          minY: 0,
                          maxY: 2500,
                          lineBarsData: [
                            LineChartBarData(
                              isCurved: true,
                              color: darkBlue,
                              barWidth: 5,
                              dotData: FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                color: darkBlue.withOpacity(0.1),
                              ),
                              spots: List.generate(
                                dailyCalories.length,
                                (i) => FlSpot(
                                  i.toDouble(),
                                  dailyCalories[i].toDouble(),
                                ),
                              ),
                            ),
                          ],
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, _) {
                                  const days = [
                                    'S',
                                    'M',
                                    'T',
                                    'W',
                                    'T',
                                    'F',
                                    'S',
                                  ];
                                  return value % 1 == 0 &&
                                          value >= 0 &&
                                          value <= 6
                                      ? Padding(
                                        padding: const EdgeInsets.only(
                                          top: 5.0,
                                        ),
                                        child: Text(
                                          days[value.toInt()],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      )
                                      : const SizedBox();
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawHorizontalLine: true,
                          ),
                          borderData: FlBorderData(show: false),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Daily Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(7, (index) {
                          return Card(
                            color: Colors.white,
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 14,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    ['S', 'M', 'T', 'W', 'T', 'F', 'S'][index],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: darkBlue,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text('${dailyCalories[index]} kcal'),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
