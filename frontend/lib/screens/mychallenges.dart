import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const green = Color(0xFF304D30);

class MyChallengesScreen extends StatefulWidget {
  final String userId;
  const MyChallengesScreen({super.key, required this.userId});

  @override
  State<MyChallengesScreen> createState() => _MyChallengesScreenState();
}

class _MyChallengesScreenState extends State<MyChallengesScreen> {
  List<dynamic> challenges = [];
  List<dynamic> myRecipes = [];
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    fetchChallenges();
    fetchMyRecipes();
  }

  Future<void> fetchChallenges() async {
    final res = await http.get(
      Uri.parse('http://localhost:3000/api/challenges'),
    );
    if (res.statusCode == 200) {
      final all = List<Map<String, dynamic>>.from(jsonDecode(res.body));
      setState(() {
        challenges =
            all
                .where(
                  (c) => List<String>.from(
                    c['participants'],
                  ).contains(widget.userId),
                )
                .toList();
      });
    }
  }

  Future<void> fetchMyRecipes() async {
    final res = await http.get(
      Uri.parse(
        'http://192.168.68.61:3000/api/users/${widget.userId}/myRecipes',
      ),
    );
    if (res.statusCode == 200) {
      setState(() => myRecipes = jsonDecode(res.body));
    }
  }

  void openSubmissionModal(dynamic challenge) {
    String? selectedRecipeId;
    String notes = '';
    Uint8List? imageBytes;

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text('Submit for "${challenge['title']}"'),
            content: StatefulBuilder(
              builder: (context, setModalState) {
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      if (challenge['type'] == 'Recipe Creation')
                        DropdownButtonFormField(
                          decoration: const InputDecoration(
                            labelText: 'Select a recipe',
                          ),
                          items:
                              myRecipes.map<DropdownMenuItem<String>>((recipe) {
                                return DropdownMenuItem(
                                  value: recipe['_id'],
                                  child: Text(recipe['title'] ?? 'Untitled'),
                                );
                              }).toList(),
                          onChanged: (value) => selectedRecipeId = value,
                        ),
                      if (challenge['type'] != 'Recipe Creation')
                        TextField(
                          decoration: const InputDecoration(labelText: 'Notes'),
                          onChanged: (val) => notes = val,
                        ),
                      const SizedBox(height: 10),
                      if (challenge['type'] != 'Recipe Creation')
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            final img = await picker.pickImage(
                              source: ImageSource.gallery,
                            );
                            if (img != null) {
                              final bytes = await img.readAsBytes();
                              setModalState(() => imageBytes = bytes);
                            }
                          },
                          icon: const Icon(Icons.image),
                          label: const Text('Upload Image'),
                        ),
                      if (imageBytes != null)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.memory(imageBytes!, height: 100),
                        ),
                    ],
                  ),
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  final body = {
                    'userId': widget.userId,
                    if (selectedRecipeId != null) 'recipeId': selectedRecipeId,
                    if (notes.isNotEmpty) 'notes': notes,
                    if (imageBytes != null) 'image': base64Encode(imageBytes!),
                  };

                  final res = await http.post(
                    Uri.parse(
                      'http://192.168.68.61:3000/api/challenges/${challenge['_id']}/submit',
                    ),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode(body),
                  );

                  if (res.statusCode == 200) {
                    await fetchChallenges();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Submission successful!')),
                    );
                  }
                },
                child: const Text('Submit'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Challenges'),
        backgroundColor: green,
        foregroundColor: Colors.white,
      ),
      body:
          challenges.isEmpty
              ? const Center(child: Text('No joined challenges'))
              : ListView.builder(
                itemCount: challenges.length,
                itemBuilder: (ctx, i) {
                  final c = challenges[i];
                  final submissions = List<Map<String, dynamic>>.from(
                    c['submissions'] ?? [],
                  );
                  final hasSubmitted = submissions.any(
                    (s) => s['user'] == widget.userId,
                  );
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                    margin: const EdgeInsets.all(10),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      tileColor: Colors.white,
                      title: Text(
                        c['title'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${c['type']} | Ends: ${c['endDate'].substring(0, 10)}',
                      ),
                      trailing:
                          hasSubmitted
                              ? const Text(
                                'Submitted ✅',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                              : ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () => openSubmissionModal(c),
                                child: const Text('Submit'),
                              ),
                    ),
                  );
                },
              ),
    );
  }
}
