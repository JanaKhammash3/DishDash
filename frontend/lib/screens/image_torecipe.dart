import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/colors.dart';
import 'package:frontend/screens/my_recipes_screen.dart';

class AiImageToRecipeScreen extends StatefulWidget {
  final String userId;
  const AiImageToRecipeScreen({super.key, required this.userId});

  @override
  State<AiImageToRecipeScreen> createState() => _AiImageToRecipeScreenState();
}

class _AiImageToRecipeScreenState extends State<AiImageToRecipeScreen> {
  Uint8List? imageBytes;
  Map<String, dynamic>? recipe;
  bool isLoading = false;

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        imageBytes = bytes;
        recipe = null;
      });
    }
  }

  Future<void> processImage() async {
    if (imageBytes == null) return;
    setState(() => isLoading = true);

    final res = await http.post(
      Uri.parse('http://192.168.68.61:3000/api/ai/image-to-recipe'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'image': base64Encode(imageBytes!)}),
    );

    setState(() => isLoading = false);

    if (res.statusCode == 200) {
      setState(() => recipe = jsonDecode(res.body));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to process image.')));
    }
  }

  Future<void> saveRecipe() async {
    if (recipe == null) return;

    final response = await http.post(
      Uri.parse(
        'http://192.168.68.61:3000/api/users/${widget.userId}/customRecipe',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        ...recipe!,
        'image': recipe!['image'] ?? base64Encode(imageBytes!),
        'instructions': (recipe!['instructions'] as List).join('\n'),
        'isPublic': true,
      }),
    );

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recipe saved to My Recipes!')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MyRecipesScreen(userId: widget.userId),
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to save recipe.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI Image Recipe',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: green,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔼 Upload Image Section
            GestureDetector(
              onTap: pickImage,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey[400]!,
                    style: BorderStyle.solid,
                    width: 1.4,
                  ),
                ),
                child:
                    imageBytes != null
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(imageBytes!, fit: BoxFit.cover),
                        )
                        : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.cloud_upload,
                              size: 38,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Tap to upload a food image",
                              style: TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
              ),
            ),

            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: isLoading ? null : processImage,
              icon: const Icon(Icons.auto_awesome, color: Colors.white),
              label: const Text(
                "Generate Recipe",
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (isLoading)
              const Center(child: CircularProgressIndicator(color: green))
            else if (recipe != null)
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          recipe!['title'] ?? '',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          recipe!['description'] ?? '',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "🧂 Ingredients",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ...List<String>.from(
                          recipe!['ingredients'] ?? [],
                        ).map((i) => Text('• $i')),
                        const SizedBox(height: 16),
                        const Text(
                          "👨‍🍳 Instructions",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ...List<String>.from(
                          recipe!['instructions'] ?? [],
                        ).map((i) => Text('• $i')),
                        const SizedBox(height: 16),
                        Text(
                          '🔥 Calories: ${recipe!['calories'] ?? 0}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: saveRecipe,
                          icon: const Icon(Icons.save, color: Colors.white),
                          label: const Text(
                            "Save to My Recipes",
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
