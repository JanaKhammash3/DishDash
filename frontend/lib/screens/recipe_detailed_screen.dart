import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/colors.dart';

class RecipeDetailedScreen extends StatefulWidget {
  final String title;
  final String imagePath;
  final String description;
  final List<String> ingredients;
  final String prepTime;
  final String difficulty;
  final double rating;
  final String instructions;

  const RecipeDetailedScreen({
    super.key,
    required this.title,
    required this.imagePath,
    required this.description,
    required this.ingredients,
    required this.prepTime,
    required this.difficulty,
    required this.rating,
    required this.instructions,
  });

  @override
  State<RecipeDetailedScreen> createState() => _RecipeDetailedScreenState();
}

class _RecipeDetailedScreenState extends State<RecipeDetailedScreen> {
  bool translating = false;
  bool showArabic = false;

  String? descriptionAr;
  String? instructionsAr;
  String? ingredientsAr;

  Future<String> translateToArabic(String text) async {
    if (text.trim().isEmpty) return '';

    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.4:3000/translate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text, 'target': 'ar'}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['translated'] ?? '';
      } else {
        print('❌ Status ${response.statusCode}: ${response.body}');
        return '[Translation failed]';
      }
    } catch (e) {
      print('❌ Translation error: $e');
      return '[Translation error]';
    }
  }

  Future<void> _toggleTranslation() async {
    if (!showArabic && descriptionAr == null) {
      setState(() => translating = true);

      descriptionAr = await translateToArabic(widget.description);
      instructionsAr = await translateToArabic(widget.instructions);
      ingredientsAr = await translateToArabic(widget.ingredients.join(', '));

      setState(() {
        translating = false;
        showArabic = true;
      });
    } else {
      setState(() => showArabic = !showArabic);
    }
  }

  Future<void> _showNutritionModal() async {
    final url = Uri.parse('http://192.168.1.4:3000/api/analyze-nutrition');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': widget.title,
        'ingredients': widget.ingredients,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "🥦 Nutrition Breakdown",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                _buildNutrientRow("🍗 Protein", "${data['protein']}g"),
                _buildNutrientRow("🧈 Fat", "${data['fat']}g"),
                _buildNutrientRow("🍞 Carbs", "${data['carbs']}g"),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text("Close"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[700],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to analyze nutrition")),
      );
    }
  }

  Widget _buildNutrientRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider imageProvider;
    try {
      final isLikelyBase64 =
          widget.imagePath.length > 100 && !widget.imagePath.contains('http');
      if (isLikelyBase64) {
        imageProvider = MemoryImage(base64Decode(widget.imagePath));
      } else if (widget.imagePath.startsWith('http')) {
        imageProvider = NetworkImage(widget.imagePath);
      } else {
        imageProvider = const AssetImage('assets/placeholder.png');
      }
    } catch (_) {
      imageProvider = const AssetImage('assets/placeholder.png');
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: green,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Method & Details",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image(image: imageProvider, height: 200, fit: BoxFit.cover),
          ),
          const SizedBox(height: 16),
          Text(
            widget.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          const Text(
            "Description",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            widget.description.isNotEmpty
                ? widget.description
                : 'No description provided.',
          ),
          if (showArabic && descriptionAr != null) ...[
            const SizedBox(height: 6),
            Text(descriptionAr!, textDirection: TextDirection.rtl),
          ],

          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.schedule),
                  SizedBox(width: 5),
                  Text(widget.prepTime),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.local_fire_department),
                  SizedBox(width: 5),
                  Text(widget.difficulty),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber),
                  SizedBox(width: 5),
                  Text(widget.rating.toStringAsFixed(1)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 30),
          const Text(
            "Ingredients",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            widget.ingredients.isNotEmpty
                ? widget.ingredients.map((e) => "• $e").join("\n")
                : "N/A",
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
          if (showArabic && ingredientsAr != null) ...[
            const SizedBox(height: 6),
            Text(ingredientsAr!, textDirection: TextDirection.rtl),
          ],

          const SizedBox(height: 30),
          const Text(
            "Method",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            widget.instructions.isNotEmpty
                ? widget.instructions
                : "No instructions provided.",
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
          if (showArabic && instructionsAr != null) ...[
            const SizedBox(height: 6),
            Text(instructionsAr!, textDirection: TextDirection.rtl),
          ],

          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: _showNutritionModal,
            icon: const Icon(Icons.restaurant),
            label: const Text("Analyze Nutrition"),
            style: ElevatedButton.styleFrom(
              backgroundColor: green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: translating ? null : _toggleTranslation,
            icon: const Icon(Icons.translate),
            label: Text(
              translating
                  ? "Translating..."
                  : showArabic
                  ? "Show Original"
                  : "Translate to Arabic",
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
