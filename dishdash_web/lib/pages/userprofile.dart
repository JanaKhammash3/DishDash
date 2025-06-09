import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:image/image.dart' as img;
import 'locationPickerModal.dart';

class WebProfileScreen extends StatefulWidget {
  final String userId;
  const WebProfileScreen({super.key, required this.userId});

  @override
  State<WebProfileScreen> createState() => _WebProfileScreenState();
}

class _WebProfileScreenState extends State<WebProfileScreen> {
  String name = '';
  String email = '';
  String? avatarBase64;
  int followerCount = 0;
  int followingCount = 0;
  int recipeCount = 0;
  LatLng? selectedLocation;
  String? selectedAction;
  final ImagePicker _picker = ImagePicker();
  List<dynamic> joinedChallenges = [];
  List<dynamic> myRecipes = [];
  List<TextEditingController> _allergyControllers = [];
  String? _selectedDiet;
  List<String> _preferredTags = [];
  List<String> _preferredCuisines = [];
  TextEditingController _weightController = TextEditingController();
  TextEditingController _heightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
    fetchRecipeCount();
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
                          onPressed: () async {
                            final picked = await ImagePicker().pickImage(
                              source: ImageSource.gallery,
                            );
                            if (picked != null) {
                              final bytes = await picked.readAsBytes();
                              setModalState(() => imageBytes = bytes);
                            }
                          },
                          icon: const Icon(Icons.image),
                          label: const Text('Upload Image'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF304D30),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
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
                onPressed: () async {
                  final body = {
                    'userId': widget.userId,
                    if (selectedRecipeId != null) 'recipeId': selectedRecipeId,
                    if (notes.isNotEmpty) 'notes': notes,
                    if (imageBytes != null) 'image': base64Encode(imageBytes!),
                  };

                  final res = await http.post(
                    Uri.parse(
                      'http://192.168.1.4:3000/api/challenges/${challenge['_id']}/submit',
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF304D30),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Submit'),
              ),
            ],
          ),
    );
  }

  Widget _buildEditProfileForm() {
    final nameController = TextEditingController(text: name);
    final emailController = TextEditingController(text: email);
    final passwordController = TextEditingController();

    return Container(
      margin: const EdgeInsets.only(top: 12),
      constraints: const BoxConstraints(maxHeight: 500), // or adjust as needed
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Edit Profile",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: TextEditingController(text: name),
              decoration: InputDecoration(
                labelText: "Full Name",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: TextEditingController(text: email),
              decoration: InputDecoration(
                labelText: "Email Address",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  "Location",
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                IconButton(
                  icon: const Icon(Icons.location_on, color: Color(0xFF304D30)),
                  onPressed: () async {
                    final picked = await showDialog<LatLng>(
                      context: context,
                      builder:
                          (_) => LocationPickerModal(
                            initialLocation:
                                selectedLocation ?? LatLng(32.2211, 35.2544),
                          ),
                    );
                    if (picked != null) {
                      setState(() {
                        selectedLocation = picked;
                      });
                    }
                  },
                ),
                if (selectedLocation != null)
                  Expanded(
                    child: Text(
                      "Lat: ${selectedLocation!.latitude.toStringAsFixed(4)}, Lng: ${selectedLocation!.longitude.toStringAsFixed(4)}",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: TextEditingController(),
              decoration: InputDecoration(
                labelText: "Change Password (optional)",
                hintText: "Leave blank to keep current password",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () {
                  // save logic
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF304D30),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Save",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSurveyEditor() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Allergies",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ..._allergyControllers.map(
            (c) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: TextField(
                controller: c,
                decoration: InputDecoration(
                  hintText: "e.g. Nuts",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
          TextButton.icon(
            icon: const Icon(Icons.add, color: Color(0xFF304D30)),
            label: const Text(
              "Add Another",
              style: TextStyle(color: Color(0xFF304D30)),
            ),
            onPressed: _addAllergyField,
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: _selectedDiet,
            decoration: const InputDecoration(
              labelText: "Diet",
              border: OutlineInputBorder(),
            ),
            items:
                ['None', 'Vegan', 'Keto', 'Low-Carb', 'Paleo', 'Vegetarian']
                    .map(
                      (diet) =>
                          DropdownMenuItem(value: diet, child: Text(diet)),
                    )
                    .toList(),
            onChanged: (val) => setState(() => _selectedDiet = val),
          ),
          const SizedBox(height: 20),
          const Text(
            "Preferred Tags",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Wrap(
            spacing: 8,
            children:
                ['gluten-free', 'spicy', 'lactose-free', 'high-protein'].map((
                  tag,
                ) {
                  final selected = _preferredTags.contains(tag);
                  return ChoiceChip(
                    label: Text(tag),
                    selected: selected,
                    onSelected: (_) {
                      setState(() {
                        selected
                            ? _preferredTags.remove(tag)
                            : _preferredTags.add(tag);
                      });
                    },
                  );
                }).toList(),
          ),
          const SizedBox(height: 20),
          const Text(
            "Preferred Cuisines",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Wrap(
            spacing: 8,
            children:
                ['Italian', 'Asian', 'Middle Eastern', 'Mexican', 'Indian'].map(
                  (cuisine) {
                    final selected = _preferredCuisines.contains(cuisine);
                    return ChoiceChip(
                      label: Text(cuisine),
                      selected: selected,
                      onSelected: (_) {
                        setState(() {
                          selected
                              ? _preferredCuisines.remove(cuisine)
                              : _preferredCuisines.add(cuisine);
                        });
                      },
                    );
                  },
                ).toList(),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _weightController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Weight (kg)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _heightController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Height (cm)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 30),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _saveSurvey,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF304D30),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text("Save", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengesList() {
    if (joinedChallenges.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Text('No joined challenges'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(), // Don't conflict with outer scroll
      itemCount: joinedChallenges.length,
      itemBuilder: (ctx, i) {
        final c = joinedChallenges[i];
        final submissions = List<Map<String, dynamic>>.from(
          c['submissions'] ?? [],
        );
        final hasSubmitted = submissions.any((s) => s['user'] == widget.userId);

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 8),
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
                        color: Color(0xFF304D30),
                        fontWeight: FontWeight.bold,
                      ),
                    )
                    : ElevatedButton(
                      onPressed: () => openSubmissionModal(c),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF304D30),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Submit'),
                    ),
          ),
        );
      },
    );
  }

  void _onEdit() {
    setState(() => selectedAction = 'edit');
  }

  void _onUpdateSurvey() async {
    await _fetchSurveyData();
    setState(() => selectedAction = 'survey');
  }

  Future<void> _fetchSurveyData() async {
    final url = Uri.parse(
      'http://192.168.1.4:3000/api/profile/${widget.userId}',
    );
    final res = await http.get(url);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final survey = data['survey'] ?? {};
      final allergies = List<String>.from(data['allergies'] ?? []);

      setState(() {
        _allergyControllers =
            allergies.map((a) => TextEditingController(text: a)).toList();
        if (_allergyControllers.isEmpty)
          _allergyControllers.add(TextEditingController());

        _selectedDiet = survey['diet'];
        _preferredTags = List<String>.from(survey['preferredTags'] ?? []);
        _preferredCuisines = List<String>.from(
          survey['preferredCuisines'] ?? [],
        );
        _weightController.text = survey['weight']?.toString() ?? '';
        _heightController.text = survey['height']?.toString() ?? '';
      });
    }
  }

  void _addAllergyField() {
    setState(() => _allergyControllers.add(TextEditingController()));
  }

  Future<void> _saveSurvey() async {
    final allergies =
        _allergyControllers
            .map((c) => c.text.trim())
            .where((e) => e.isNotEmpty)
            .toList();

    final surveyData = {
      "diet": _selectedDiet ?? "None",
      "preferredTags": _preferredTags,
      "preferredCuisines": _preferredCuisines,
      "weight": int.tryParse(_weightController.text),
      "height": int.tryParse(_heightController.text),
    };

    final allergyRes = await http.patch(
      Uri.parse(
        'http://192.168.1.4:3000/api/users/updateAllergies/${widget.userId}',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'allergies': allergies}),
    );

    final surveyRes = await http.put(
      Uri.parse('http://192.168.1.4:3000/api/users/${widget.userId}/survey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(surveyData),
    );

    if (allergyRes.statusCode == 200 && surveyRes.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Survey updated successfully")),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to update survey")));
    }
  }

  void _onMyChallenges() async {
    await fetchChallenges();
    await fetchMyRecipes();
    setState(() => selectedAction = 'challenges');
  }

  Future<void> fetchChallenges() async {
    final res = await http.get(
      Uri.parse('http://192.168.1.4:3000/api/challenges'),
    );
    if (res.statusCode == 200) {
      final all = List<Map<String, dynamic>>.from(jsonDecode(res.body));
      setState(() {
        joinedChallenges =
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
      Uri.parse('http://192.168.1.4:3000/api/users/${widget.userId}/myRecipes'),
    );
    if (res.statusCode == 200) {
      setState(() => myRecipes = jsonDecode(res.body));
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      final rawBytes = await picked.readAsBytes();

      // Decode the image
      final originalImage = img.decodeImage(rawBytes);
      if (originalImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not process image')),
        );
        return;
      }

      // Resize and compress
      final resized = img.copyResize(
        originalImage,
        width: 300,
      ); // Resize to 300px width
      final compressedBytes = img.encodeJpg(
        resized,
        quality: 70,
      ); // JPEG quality 70%

      final base64String = base64Encode(compressedBytes);

      final url = Uri.parse(
        'http://192.168.1.4:3000/api/profile/${widget.userId}/avatar',
      );

      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'avatar': base64String}),
      );

      if (response.statusCode == 200) {
        await fetchUserProfile(); // Force refresh
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar updated successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload avatar')),
        );
      }
    }
  }

  Future<void> fetchRecipeCount() async {
    final url = Uri.parse(
      'http://192.168.1.4:3000/api/recipes/count/${widget.userId}',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          recipeCount = data['count'];
        });
      }
    } catch (e) {
      debugPrint('Error fetching recipe count: $e');
    }
  }

  Future<void> fetchUserProfile() async {
    final url = Uri.parse(
      'http://192.168.1.4:3000/api/profile/${widget.userId}',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          name = data['name'];
          email = data['email'];
          if (data['location'] != null) {
            selectedLocation = LatLng(
              data['location']['latitude'],
              data['location']['longitude'],
            );
          }
          avatarBase64 = data['avatar'];
          followerCount =
              data['followers'] is List
                  ? data['followers'].length
                  : data['followers'] ?? 0;

          followingCount =
              data['following'] is List
                  ? data['following'].length
                  : data['following'] ?? 0;
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to load profile')));
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasAvatar = avatarBase64 != null && avatarBase64!.isNotEmpty;
    final avatarImage =
        hasAvatar
            ? MemoryImage(base64Decode(avatarBase64!)) as ImageProvider
            : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Panel: Avatar and Stats
            Container(
              width: 300,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey.shade300,
                        backgroundImage: avatarImage,
                        child:
                            !hasAvatar
                                ? const Icon(
                                  Icons.person,
                                  size: 48,
                                  color: Colors.white70,
                                )
                                : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Color(0xFF304D30)),
                        onPressed: _pickAndUploadImage,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(email, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  _buildStatTile('Followers', followerCount, Icons.group),
                  _buildStatTile('Following', followingCount, Icons.group_add),
                  _buildStatTile('Recipes', recipeCount, Icons.restaurant_menu),
                ],
              ),
            ),

            const SizedBox(width: 32),

            // Right Panel: Actions
            // Right Panel: Actions + Dynamic Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(
                  bottom: 32,
                ), // Prevent bottom clipping
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Settings & Actions',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildActionBox(
                      icon: Icons.edit,
                      title: 'Edit Profile',
                      description: 'Update your profile details',
                      onTap: _onEdit,
                    ),
                    const SizedBox(height: 16),
                    _buildActionBox(
                      icon: Icons.flag,
                      title: 'My Challenges',
                      description: 'View and submit your challenge progress',
                      onTap: _onMyChallenges,
                    ),
                    const SizedBox(height: 16),
                    _buildActionBox(
                      icon: Icons.assignment,
                      title: 'Update Survey',
                      description:
                          'Edit your dietary and lifestyle preferences',
                      onTap: _onUpdateSurvey,
                    ),
                    const SizedBox(height: 32),

                    // Dynamic Section
                    if (selectedAction == 'edit') _buildEditProfileForm(),
                    if (selectedAction == 'survey') _buildSurveyEditor(),
                    if (selectedAction == 'challenges') _buildChallengesList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(String label, int value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: const Color.fromARGB(255, 89, 147, 89),
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionBox({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 32, color: Color.fromARGB(255, 89, 147, 89)),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
