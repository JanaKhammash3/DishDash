import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class MyRecipesWebPage extends StatefulWidget {
  final String userId;
  const MyRecipesWebPage({super.key, required this.userId});

  @override
  State<MyRecipesWebPage> createState() => _MyRecipesWebPageState();
}

class _MyRecipesWebPageState extends State<MyRecipesWebPage> {
  List<dynamic> savedRecipes = [];
  List<dynamic> userRecipes = [];
  bool isLoading = true;
  Uint8List? imageBytes;
  @override
  void initState() {
    super.initState();
    fetchSavedRecipes();
    fetchUserRecipes();
  }

  Future<String> translateToArabic(String text) async {
    if (text.trim().isEmpty) return '';

    try {
      final response = await http.post(
        Uri.parse(
          'http://192.168.1.4:3000/translate',
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

  void _showRecipeDetailsModal(Map<String, dynamic> recipe) {
    final String title = recipe['title'] ?? '';
    final String imagePath = recipe['image'] ?? '';
    final String description =
        recipe['description'] ?? 'No description provided.';
    final List<String> ingredients = List<String>.from(
      recipe['ingredients'] ?? [],
    );
    final String instructions =
        recipe['instructions'] ?? 'No instructions provided.';
    final int prepTime = recipe['prepTime'] ?? 0;
    final String difficulty = recipe['difficulty'] ?? 'Easy';
    final int calories = recipe['calories'] ?? 0;
    final double rating = _averageRating(recipe['ratings']);

    ImageProvider imageProvider;
    try {
      final isLikelyBase64 =
          imagePath.length > 100 &&
          (imagePath.startsWith('/9j') ||
              imagePath.startsWith('iVBOR') ||
              imagePath.contains('base64'));

      if (isLikelyBase64) {
        final base64Str =
            imagePath.contains(',') ? imagePath.split(',').last : imagePath;
        imageProvider = MemoryImage(base64Decode(base64Str));
      } else if (imagePath.startsWith('http')) {
        imageProvider = NetworkImage(imagePath);
      } else {
        imageProvider = NetworkImage(
          'http://192.168.1.4:3000/images/$imagePath',
        );
      }
    } catch (_) {
      imageProvider = const AssetImage('assets/placeholder.png');
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 🔹 Image & Title
                  Center(
                    child: CircleAvatar(
                      radius: 70,
                      backgroundImage: imageProvider,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 🔹 Description
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),

                  const SizedBox(height: 16),

                  // 🔹 Meta Info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.schedule, size: 18),
                          const SizedBox(width: 4),
                          Text('$prepTime min'),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.local_fire_department, size: 18),
                          const SizedBox(width: 4),
                          Text('$calories kcal'),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.settings, size: 18),
                          const SizedBox(width: 4),
                          Text(difficulty),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text(rating.toStringAsFixed(1)),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 🔹 Ingredients
                  const Text(
                    "Ingredients",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children:
                        ingredients
                            .map(
                              (ing) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                      offset: Offset(2, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  ing,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),

                  const SizedBox(height: 30),

                  // 🔹 Instructions
                  const Text(
                    "Instructions",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    instructions,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
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
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Calories',
                            ),
                            keyboardType: TextInputType.number,
                            controller: TextEditingController(text: calories),
                            onChanged: (val) => calories = val,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF304D30),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          onPressed: () async {
                            final ingrList =
                                ingredients
                                    .split(',')
                                    .map((e) => e.trim())
                                    .where((e) => e.isNotEmpty)
                                    .toList();

                            if (ingrList.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please enter ingredients first',
                                  ),
                                ),
                              );
                              return;
                            }

                            setModalState(() => calories = 'Analyzing...');

                            try {
                              final res = await http.post(
                                Uri.parse(
                                  'http://192.168.1.4:3000/api/analyze-nutrition',
                                ),
                                headers: {'Content-Type': 'application/json'},
                                body: jsonEncode({
                                  'title': title,
                                  'ingredients': ingrList,
                                }),
                              );

                              if (res.statusCode == 200) {
                                final data = jsonDecode(res.body);
                                setModalState(
                                  () => calories = data['calories'].toString(),
                                );
                              } else {
                                setModalState(() => calories = '');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Failed to analyze calories'),
                                  ),
                                );
                              }
                            } catch (e) {
                              setModalState(() => calories = '');
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Error analyzing calories'),
                                ),
                              );
                            }
                          },
                          child: const Text(
                            'Analyze Calories',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
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
                  icon: const Icon(Icons.translate, color: Color(0xFF304D30)),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF304D30),
                  ),
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
                        'http://192.168.1.4:3000/api/users/${widget.userId}/customRecipe',
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

  Future<void> fetchUserRecipes() async {
    setState(() => isLoading = true);
    final url = Uri.parse(
      'http://192.168.1.4:3000/api/users/${widget.userId}/myRecipes',
    );
    final res = await http.get(url);
    if (res.statusCode == 200) {
      setState(() {
        userRecipes = jsonDecode(res.body);
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  ImageProvider _getImageProvider(String? image) {
    if (image == null || image.isEmpty) {
      return const AssetImage('assets/placeholder.png');
    }

    // Detect base64 string (common formats: /9j for JPEG, iVBOR for PNG)
    final isBase64 =
        RegExp(r'^[A-Za-z0-9+/]+={0,2}$').hasMatch(image) &&
        image.length > 100; // crude length check to avoid false positives

    if (isBase64) {
      try {
        return MemoryImage(base64Decode(image));
      } catch (_) {
        return const AssetImage('assets/placeholder.png');
      }
    }

    if (image.startsWith('http')) {
      return NetworkImage(image);
    }

    return NetworkImage('http://192.168.1.4:3000/images/$image');
  }

  Future<void> fetchSavedRecipes() async {
    final url = Uri.parse(
      'http://192.168.1.4:3000/api/users/${widget.userId}/savedRecipes',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      setState(() => savedRecipes = jsonDecode(response.body));
    }
  }

  Future<void> unsaveRecipe(String recipeId) async {
    final url = Uri.parse(
      'http://192.168.1.4:3000/api/users/${widget.userId}/unsaveRecipe',
    );
    await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'recipeId': recipeId}),
    );
    fetchSavedRecipes();
  }

  double _averageRating(dynamic ratings) {
    if (ratings == null || ratings.isEmpty) return 0.0;
    final List<int> list = List<int>.from(ratings);
    return list.reduce((a, b) => a + b) / list.length;
  }

  Widget _buildRecipeSquare(Map recipe) {
    final String? image = recipe['image'];
    ImageProvider imageProvider;

    if (image != null && image.startsWith('http')) {
      imageProvider = NetworkImage(image);
    } else if (image != null &&
        (image.startsWith('/9j') || image.startsWith('iVBOR'))) {
      imageProvider = MemoryImage(base64Decode(image));
    } else if (image != null && image.isNotEmpty) {
      imageProvider = NetworkImage('http://192.168.1.4:3000/images/$image');
    } else {
      imageProvider = const AssetImage('assets/placeholder.png');
    }

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(
          color: Color(0xFF304D30),
          width: 2,
        ), // ✅ dark Color(0xFF304D30) border
      ),
      elevation: 2,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image(
              image: imageProvider,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Column(
              children: [
                Text(
                  recipe['title'] ?? 'Untitled',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${recipe['calories'] ?? 0} cal • ${recipe['difficulty'] ?? 'Easy'} • ${recipe['prepTime'] ?? 0} min',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => unsaveRecipe(recipe['_id']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(
                      0xFF304D30,
                    ), // ✅ dark Color(0xFF304D30)
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "Unsave",
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ), // ✅ white text
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Page Title
            const Text(
              "My Recipes Dashboard",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF304D30),
              ),
            ),

            const SizedBox(height: 12),

            // ✅ Moved Create Button to left, below title
            ElevatedButton.icon(
              onPressed: () {
                _openCreateModal();
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Create a Recipe',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF304D30),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 25),
            const Text(
              "Saved Recipes",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // ✅ Smaller boxes: more per row, reduced aspect ratio
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: savedRecipes.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4, // Show 5 boxes per row
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 0.9, // Makes boxes shorter
              ),
              itemBuilder: (context, index) {
                final recipe = savedRecipes[index];
                return GestureDetector(
                  onTap:
                      () => _showRecipeDetailsModal(
                        recipe,
                      ), // ✅ your existing modal function
                  child: _buildRecipeSquare(recipe),
                );
              },
            ),

            const SizedBox(height: 32),
            const Text(
              "My Recipes",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            isLoading
                ? const Center(child: CircularProgressIndicator())
                : userRecipes.isEmpty
                ? const Text('You haven’t created any recipes yet.')
                : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: userRecipes.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 0.7,
                  ),
                  itemBuilder: (context, index) {
                    final recipe = userRecipes[index];
                    final isPublic = recipe['isPublic'] == true;

                    return GestureDetector(
                      onTap:
                          () => _showRecipeDetailsModal(
                            recipe,
                          ), // You can reuse the same modal function
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(
                            color: Color(0xFF304D30),
                            width: 2,
                          ),
                        ),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image(
                                  image: _getImageProvider(recipe['image']),
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                recipe['title'] ?? 'Untitled',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${recipe['calories'] ?? 0} cal • ${recipe['difficulty'] ?? 'N/A'} • ${recipe['prepTime'] ?? 0} min',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isPublic ? Icons.public : Icons.lock,
                                    size: 16,
                                    color:
                                        isPublic
                                            ? Color(0xFF304D30)
                                            : Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isPublic ? 'Public' : 'Private',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          isPublic
                                              ? Color(0xFF304D30)
                                              : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
          ],
        ),
      ),
    );
  }
}
