import 'package:flutter/material.dart';
import 'package:frontend/colors.dart'; // ensure 'maroon' is defined
import 'home_screen.dart';

class AllergyScreen extends StatefulWidget {
  const AllergyScreen({super.key});

  @override
  State<AllergyScreen> createState() => _AllergyScreenState();
}

class _AllergyScreenState extends State<AllergyScreen> {
  final TextEditingController _allergyController = TextEditingController();

  void _goToHomeScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  void _saveAllergy() {
    String allergy = _allergyController.text.trim();
    if (allergy.isNotEmpty) {
      // ignore: avoid_print
      print("Saved Allergy: $allergy");
    }
    _goToHomeScreen();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: maroon,
      body: Column(
        children: [
          // Top section with image
          Container(
            height: MediaQuery.of(context).size.height * 0.35,
            alignment: Alignment.center,
            child: Image.asset(
              'assets/allergy.png',
              height: 160,
              fit: BoxFit.contain,
            ),
          ),

          // Bottom section with form
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
                    // Skip Button (top right in form area)
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
                      "Let us know in one word.",
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    TextField(
                      controller: _allergyController,
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
                    const SizedBox(height: 30),
                    SizedBox(
                      width: 200,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveAllergy,
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
