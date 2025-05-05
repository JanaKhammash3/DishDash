import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:frontend/colors.dart'; // if you use maroon color from your palette
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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
  @override
  void initState() {
    super.initState();
    loadWeeklyTarget();
    fetchCalorieData();
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
  }

  Future<void> fetchCalorieData() async {
    try {
      final response = await http.get(
        Uri.parse(
          'http://192.168.68.60:3000/api/mealplans/weekly-calories/${widget.userId}',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          totalCaloriesThisWeek = data['totalCalories'];
          dailyCalories = List<int>.from(data['dailyCalories']);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load calorie data');
      }
    } catch (e) {
      print('Error fetching calorie data: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double percent = totalCaloriesThisWeek / weeklyTarget;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: maroon,
        elevation: 0,
        leadingWidth: 96, // Adjust to fit both buttons
        leading: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            Builder(
              builder:
                  (context) => IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
            ),
          ],
        ),
        title: const Text(
          'Calorie Score',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      drawer: Drawer(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text(
                'Set Weekly Target',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _targetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Enter target (e.g. 10000)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  weeklyTarget = int.tryParse(value) ?? 0; // ✅ this line
                },
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: maroon),
                onPressed: () {
                  if (weeklyTarget > 0) {
                    saveWeeklyTarget(weeklyTarget);
                    setState(() => weeklyTarget = weeklyTarget);
                    Navigator.pop(context); // close drawer
                  }
                },
                child: const Text(
                  'Submit',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                // 👈 wrap in scroll view to prevent overflow just in case
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Weekly Calorie Progress',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // 🔥 Calorie Progress Ring
                    CircularPercentIndicator(
                      radius: 100.0,
                      lineWidth: 15.0,
                      animation: true,
                      percent: percent.clamp(0.0, 1.0),
                      center: Text(
                        '${(percent * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 22.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      footer: Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Text(
                          '$totalCaloriesThisWeek / $weeklyTarget kcal',
                          style: const TextStyle(fontSize: 16.0),
                        ),
                      ),
                      circularStrokeCap: CircularStrokeCap.round,
                      progressColor: percent >= 1.0 ? Colors.green : maroon,
                      backgroundColor: Colors.grey.shade300,
                    ),

                    const SizedBox(height: 40),

                    Text(
                      'Target Range',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Stack(
                      children: [
                        Container(
                          height: 20,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: LinearGradient(
                              colors: [
                                Colors.grey.shade400,
                                maroon,
                                Colors.red.shade400,
                              ],
                              stops: const [0.0, 0.85, 1.0],
                            ),
                          ),
                        ),
                        Positioned(
                          left:
                              (percent.clamp(0.0, 1.0)) *
                              MediaQuery.of(context).size.width *
                              0.85,
                          top: 0,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black, width: 1),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),
                    const Text(
                      'Weekly Intake Trend',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      height: 150,
                      child: LineChart(
                        LineChartData(
                          lineBarsData: [
                            LineChartBarData(
                              spots: List.generate(
                                dailyCalories.length,
                                (index) => FlSpot(
                                  index.toDouble(),
                                  dailyCalories[index].toDouble(),
                                ),
                              ),
                              isCurved: true,
                              barWidth: 3,
                              color: maroon,
                              dotData: FlDotData(show: false),
                            ),
                          ],
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 22,
                                getTitlesWidget: (value, _) {
                                  const days = [
                                    'M',
                                    'T',
                                    'W',
                                    'T',
                                    'F',
                                    'S',
                                    'S',
                                  ];
                                  if (value % 1 == 0 &&
                                      value >= 0 &&
                                      value <= 6) {
                                    return Text(
                                      days[value.toInt()],
                                      style: const TextStyle(fontSize: 12),
                                    );
                                  } else {
                                    return const SizedBox.shrink();
                                  }
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
                          gridData: FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          minY: 0,
                          maxY: 2500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
