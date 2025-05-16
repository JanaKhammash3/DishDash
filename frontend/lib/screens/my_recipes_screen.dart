import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/colors.dart';
import 'package:frontend/screens/recipe_screen.dart';

class MyRecipesScreen extends StatefulWidget {
  final String userId;
  const MyRecipesScreen({super.key, required this.userId});

  @override
  State<MyRecipesScreen> createState() => _MyRecipesScreenState();
}

class _MyRecipesScreenState extends State<MyRecipesScreen> {
  List<dynamic> userRecipes = [];
  Uint8List? imageBytes;

  ImageProvider _getImageProvider(String? image) {
    if (image != null && image.startsWith('http')) {
      return NetworkImage(image);
    } else if (image != null && image.startsWith('/9j')) {
      return MemoryImage(base64Decode(image));
    } else if (image != null && image.isNotEmpty) {
      return NetworkImage('http://192.168.68.60:3000/images/$image');
    } else {
      return const AssetImage('assets/placeholder.png');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUserRecipes();
  }

  Future<void> fetchUserRecipes() async {
    final url = Uri.parse(
      'http://192.168.68.60:3000/api/users/${widget.userId}/myRecipes',
    );
    final res = await http.get(url);
    if (res.statusCode == 200) {
      setState(() => userRecipes = jsonDecode(res.body));
    }
  }

  Future<String> translateToArabic(String text) async {
    if (text.trim().isEmpty) return '';

    try {
      final response = await http.post(
        Uri.parse(
          'http://192.168.68.60:3000/translate',
        ), // ✅ Your backend endpoint
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': text,
          'target': 'ar', // Optional, defaults to 'ar' in your backend
        }),
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

  void _openCreateModal() {
    bool showArabicFields = false;

    String title = '',
        ingredients = '',
        calories = '',
        description = '',
        diet = 'None';
    String mealTime = 'Breakfast',
        tagInput = '',
        prepTime = '',
        instructions = '',
        difficulty = 'Easy';
    String titleAr = '';
    String descriptionAr = '';
    String instructionsAr = '';
    String ingredientsAr = '';

    List<String> tags = [];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: Colors.grey[100],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Customize Your Recipe',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final picked = await picker.pickImage(
                          source: ImageSource.gallery,
                        );
                        if (picked != null) {
                          final bytes = await picked.readAsBytes();
                          setModalState(() => imageBytes = bytes);
                        }
                      },
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child:
                            imageBytes != null
                                ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.memory(
                                    imageBytes!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                                : const Center(
                                  child: Text('Tap to upload image'),
                                ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Title (English)',
                      ),
                      onChanged: (val) => title = val,
                    ),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Title (Arabic)',
                      ),
                      textDirection: TextDirection.rtl,
                      onChanged: (val) => titleAr = val,
                    ),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Ingredients',
                      ),
                      onChanged: (val) => ingredients = val,
                    ),
                    TextField(
                      decoration: const InputDecoration(labelText: 'Calories'),
                      keyboardType: TextInputType.number,
                      onChanged: (val) => calories = val,
                    ),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                      maxLines: 3,
                      onChanged: (val) => description = val,
                    ),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Instructions',
                      ),
                      maxLines: 3,
                      onChanged: (val) => instructions = val,
                    ),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Preparation Time (minutes)',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (val) => prepTime = val,
                    ),
                    DropdownButtonFormField<String>(
                      value: diet,
                      decoration: const InputDecoration(labelText: 'Diet'),
                      items:
                          [
                                'None',
                                'Vegan',
                                'Keto',
                                'Low-Carb',
                                'Paleo',
                                'Vegetarian',
                              ]
                              .map(
                                (d) =>
                                    DropdownMenuItem(value: d, child: Text(d)),
                              )
                              .toList(),
                      onChanged: (val) => setModalState(() => diet = val!),
                    ),
                    DropdownButtonFormField<String>(
                      value: mealTime,
                      decoration: const InputDecoration(labelText: 'Meal Time'),
                      items:
                          ['Breakfast', 'Lunch', 'Dinner', 'Snack', 'Dessert']
                              .map(
                                (m) =>
                                    DropdownMenuItem(value: m, child: Text(m)),
                              )
                              .toList(),
                      onChanged: (val) => setModalState(() => mealTime = val!),
                    ),
                    DropdownButtonFormField<String>(
                      value: difficulty,
                      decoration: const InputDecoration(
                        labelText: 'Difficulty',
                      ),
                      items:
                          ['Easy', 'Medium', 'Hard']
                              .map(
                                (d) =>
                                    DropdownMenuItem(value: d, child: Text(d)),
                              )
                              .toList(),
                      onChanged:
                          (val) => setModalState(() => difficulty = val!),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Add Tag',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            if (tagInput.isNotEmpty &&
                                !tags.contains(tagInput)) {
                              setModalState(() {
                                tags.add(tagInput.trim());
                                tagInput = '';
                              });
                            }
                          },
                        ),
                      ),
                      onChanged: (val) => tagInput = val,
                      onSubmitted: (_) {
                        if (tagInput.isNotEmpty && !tags.contains(tagInput)) {
                          setModalState(() {
                            tags.add(tagInput.trim());
                            tagInput = '';
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton.icon(
                  onPressed: () async {
                    setModalState(() {
                      descriptionAr = 'Translating...';
                      instructionsAr = 'Translating...';
                      ingredientsAr = 'Translating...';
                      showArabicFields = true;
                    });

                    final translatedDescription = await translateToArabic(
                      description,
                    );
                    final translatedInstructions = await translateToArabic(
                      instructions,
                    );
                    final translatedIngredients = await translateToArabic(
                      ingredients,
                    );

                    setModalState(() {
                      descriptionAr = translatedDescription;
                      instructionsAr = translatedInstructions;
                      ingredientsAr = translatedIngredients;
                    });
                  },
                  icon: const Icon(Icons.translate, color: Colors.green),
                  label: const Text('Translate to Arabic'),
                ),
                if (showArabicFields) ...[
                  const SizedBox(height: 10),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Description (Arabic)',
                    ),
                    controller: TextEditingController(text: descriptionAr),
                    textDirection: TextDirection.rtl,
                    maxLines: 3,
                    onChanged: (val) => descriptionAr = val,
                  ),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Instructions (Arabic)',
                    ),
                    controller: TextEditingController(text: instructionsAr),
                    textDirection: TextDirection.rtl,
                    maxLines: 3,
                    onChanged: (val) => instructionsAr = val,
                  ),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Ingredients (Arabic)',
                    ),
                    controller: TextEditingController(text: ingredientsAr),
                    textDirection: TextDirection.rtl,
                    onChanged: (val) => ingredientsAr = val,
                  ),
                ],

                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: green),
                  child: const Text(
                    'Add',
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () async {
                    if (title.isEmpty || calories.isEmpty) return;
                    final body = {
                      'title': title,
                      'titleAr': titleAr,
                      'description': description,
                      'descriptionAr': descriptionAr,
                      'instructions': instructions,
                      'instructionsAr': instructionsAr,
                      'ingredients':
                          ingredients.split(',').map((e) => e.trim()).toList(),
                      'ingredientsAr':
                          ingredientsAr
                              .split(',')
                              .map((e) => e.trim())
                              .toList(),

                      'calories': int.tryParse(calories) ?? 0,

                      'image':
                          imageBytes != null ? base64Encode(imageBytes!) : '',
                      'diet': diet,
                      'mealTime': mealTime,
                      'tags': tags,
                      'prepTime': int.tryParse(prepTime) ?? 0,
                      'difficulty': difficulty,
                      'isPublic': true,
                    };
                    final result = await showDialog<bool>(
                      context: context,
                      builder:
                          (_) => AlertDialog(
                            title: const Text('Make this recipe public?'),
                            content: const Text(
                              'Do you want your recipe to be visible to others?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Private'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Public'),
                              ),
                            ],
                          ),
                    );

                    if (result == null) return;

                    body['isPublic'] = result;

                    final res = await http.post(
                      Uri.parse(
                        'http://192.168.68.60:3000/api/users/${widget.userId}/customRecipe',
                      ),
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode(body),
                    );

                    if (res.statusCode == 201) {
                      Navigator.pop(context);
                      setState(() => fetchUserRecipes());
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Recipe added successfully!'),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to add recipe.')),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: green,
        title: const Text('My Recipes', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child:
                userRecipes.isEmpty
                    ? const Center(child: Text('No recipes yet.'))
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: userRecipes.length,
                      itemBuilder: (context, index) {
                        final r = userRecipes[index];
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            leading: CircleAvatar(
                              radius: 22,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: _getImageProvider(r['image']),
                            ),
                            title: Text(
                              r['title'] ?? 'Untitled',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${r['calories']} cal • ${r['difficulty'] ?? 'N/A'}',
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => RecipeScreen(
                                        title: r['title'] ?? 'Untitled',
                                        imagePath: r['image'] ?? '',
                                        rating: 0.0,
                                        ingredients: List<String>.from(
                                          (r['ingredients'] ?? []).map(
                                            (e) => e.toString(),
                                          ),
                                        ),
                                        description: r['description'] ?? '',
                                        prepTime: r['prepTime'] ?? 0,
                                        difficulty: r['difficulty'] ?? 'Easy',
                                        instructions: r['instructions'] ?? '',
                                      ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: ElevatedButton.icon(
              onPressed: _openCreateModal,
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 14,
                ),
              ),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Customize Your Recipe',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
