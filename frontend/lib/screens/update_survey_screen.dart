import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/colors.dart';

class UpdateSurveyScreen extends StatefulWidget {
  final String userId;
  const UpdateSurveyScreen({super.key, required this.userId});

  @override
  State<UpdateSurveyScreen> createState() => _UpdateSurveyScreenState();
}

class _UpdateSurveyScreenState extends State<UpdateSurveyScreen> {
  List<TextEditingController> _allergyControllers = [];
  String? _selectedDiet;
  List<String> _preferredTags = [];
  List<String> _preferredCuisines = [];
  TextEditingController _weightController = TextEditingController();
  TextEditingController _heightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchExistingData();
  }

  Future<void> _fetchExistingData() async {
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
    setState(() {
      _allergyControllers.add(TextEditingController());
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: green,
        title: const Text(
          'Update Survey',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
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
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: green), // your green color
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: green, width: 2),
                    ),
                  ),
                ),
              ),
            ),
            TextButton.icon(
              icon: Icon(Icons.add, color: green),
              label: Text("Add Another", style: TextStyle(color: green)),
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
                  [
                    'None',
                    'Vegan',
                    'Keto',
                    'Low-Carb',
                    'Paleo',
                    'Vegetarian',
                  ].map((diet) {
                    return DropdownMenuItem(value: diet, child: Text(diet));
                  }).toList(),
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
                  [
                    'Italian',
                    'Asian',
                    'Middle Eastern',
                    'Mexican',
                    'Indian',
                  ].map((cuisine) {
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
                  }).toList(),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Weight (kg)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _heightController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Height (cm)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveSurvey,
                style: ElevatedButton.styleFrom(backgroundColor: green),
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
}
