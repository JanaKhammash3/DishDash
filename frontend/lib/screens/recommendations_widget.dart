// lib/widgets/recommendations_widget.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../colors.dart';
import '../screens/recipe_screen.dart';
import '../screens/home_screen.dart'; // for placeCard
import 'package:frontend/screens/place_card.dart';

class RecommendationsWidget extends StatefulWidget {
  final String userId;
  const RecommendationsWidget({super.key, required this.userId});

  @override
  State<RecommendationsWidget> createState() => _RecommendationsWidgetState();
}

class _RecommendationsWidgetState extends State<RecommendationsWidget> {
  List<dynamic> recommendations = [];

  @override
  void initState() {
    super.initState();
    fetchRecommendations();
  }

  Future<void> fetchRecommendations() async {
    final url = Uri.parse(
      'http://192.168.68.60:3000/api/users/${widget.userId}/recommendations',
    );
    final res = await http.get(url);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        recommendations = data;
      });
    } else {
      print('Error fetching recommendations: ${res.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: recommendations.length,
        itemBuilder: (context, index) {
          final recipe = recommendations[index];
          final image = recipe['image'];
          final imagePath =
              (image != null && image.isNotEmpty)
                  ? 'http://192.168.68.60:3000/images/$image'
                  : 'assets/placeholder.png';

          return placeCard(
            recipe['title'] ?? 'Recipe',
            recipe['author']?['name'] ?? '',
            imagePath,
            rating: _averageRating(recipe['ratings']),
            authorName: recipe['author']?['name'],
            authorAvatar: recipe['author']?['avatar'],
          );
        },
      ),
    );
  }

  double _averageRating(List? ratings) {
    final r = (ratings ?? []).cast<num>();
    return r.isEmpty ? 0.0 : r.reduce((a, b) => a + b) / r.length;
  }
}
