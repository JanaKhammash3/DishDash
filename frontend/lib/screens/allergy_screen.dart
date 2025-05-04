import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frontend/colors.dart';
import 'package:http/http.dart' as http;
import 'home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AllergyScreen extends StatefulWidget {
  final String userId;

  const AllergyScreen({super.key, required this.userId});

  @override
  State<AllergyScreen> createState() => _AllergyScreenState();
}

class _AllergyScreenState extends State<AllergyScreen> {
  List<TextEditingController> _allergyControllers = [TextEditingController()];

  void _addAllergyField() {
    setState(() {
      _allergyControllers.add(TextEditingController());
    });
  }

  void _goToHomeScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreen(userId: widget.userId),
      ),
    );
  }

  void _saveAllergies() async {
    List<String> allergies =
        _allergyControllers
            .map((controller) => controller.text.trim())
            .where((text) => text.isNotEmpty)
            .toList();

    if (allergies.isEmpty) {
      _goToHomeScreen();
      return;
    }

    final response = await http.patch(
      Uri.parse(
        'http://192.168.68.60:3000/api/users/updateAllergies/${widget.userId}',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'allergies': allergies}),
    );

    if (response.statusCode == 200) {
      // ✅ Save userId to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', widget.userId);

      _goToHomeScreen();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to save allergies")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: maroon,
      body: Column(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.35,
            alignment: Alignment.center,
            child: Image.asset(
              'assets/allergy.png',
              height: 160,
              fit: BoxFit.contain,
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(50),
                  topRight: Radius.circular(50),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.bottomRight,
                      child: TextButton(
                        onPressed: _goToHomeScreen,
                        child: const Text(
                          "Skip",
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Any Allergies?",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Let us know in one word each.",
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),

                    // Allergy Text Fields
                    ..._allergyControllers.map((controller) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: TextField(
                          controller: controller,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            hintText: "E.g. Nuts",
                            hintStyle: const TextStyle(color: Colors.grey),
                            filled: true,
                            fillColor: Colors.grey.shade200,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      );
                    }).toList(),

                    const SizedBox(height: 10),

                    // Add another allergy field
                    TextButton.icon(
                      onPressed: _addAllergyField,
                      icon: Icon(Icons.add, color: maroon),
                      label: Text(
                        "Add another",
                        style: TextStyle(color: maroon),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Save Button
                    SizedBox(
                      width: 200,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveAllergies,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: maroon,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          "Save",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
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
    );
  }
}
