import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/colors.dart';

class MyRecipesScreen extends StatefulWidget {
  final String userId;
  const MyRecipesScreen({super.key, required this.userId});

  @override
  State<MyRecipesScreen> createState() => _MyRecipesScreenState();
}

class _MyRecipesScreenState extends State<MyRecipesScreen> {
  List<dynamic> userRecipes = [];
  Uint8List? imageBytes;

  @override
  void initState() {
    super.initState();
    fetchUserRecipes();
  }

  void _showRecipeModal(dynamic recipe) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                recipe['title'] ?? '',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text("🔥 Calories: ${recipe['calories']} kcal"),
              const SizedBox(height: 12),
              const Text(
                "📝 Description:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(recipe['description'] ?? 'No description'),
              const SizedBox(height: 12),
              const Text(
                "🥬 Ingredients:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                (recipe['ingredients'] as List<dynamic>?)?.join(', ') ?? 'N/A',
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Future<void> fetchUserRecipes() async {
    final url = Uri.parse(
      'http://192.168.68.60:3000/api/users/${widget.userId}/myRecipes',
    );
    final res = await http.get(url);
    if (res.statusCode == 200) {
      setState(() {
        userRecipes = jsonDecode(res.body);
      });
    }
  }

  void _openCreateModal() {
    String title = '';
    String ingredients = '';
    String calories = '';
    String description = '';

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
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final picked = await picker.pickImage(
                          source: ImageSource.gallery,
                        );
                        if (picked != null) {
                          final bytes = await picked.readAsBytes();
                          setModalState(() {
                            imageBytes = bytes;
                          });
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
                      decoration: const InputDecoration(labelText: 'Title'),
                      onChanged: (val) => title = val,
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
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: maroon),
                  child: const Text(
                    'Add',
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () async {
                    if (title.isEmpty || calories.isEmpty) return;

                    final body = {
                      'title': title,
                      'ingredients': ingredients,
                      'calories': calories,
                      'description': description,
                      'image':
                          imageBytes != null ? base64Encode(imageBytes!) : '',
                    };

                    final res = await http.post(
                      Uri.parse(
                        'http://192.168.68.60:3000/api/users/${widget.userId}/customRecipe',
                      ),
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode(body),
                    );

                    if (res.statusCode == 200) {
                      Navigator.pop(context);
                      fetchUserRecipes();
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
        backgroundColor: maroon,
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
                            leading: const Icon(
                              Icons.kitchen,
                              color: maroon,
                              size: 28,
                            ),
                            title: Text(
                              r['title'] ?? 'Untitled',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text('${r['calories']} calories'),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                            ),
                            onTap: () => _showRecipeModal(r),
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
                backgroundColor: maroon,
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
