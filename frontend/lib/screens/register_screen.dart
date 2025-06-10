import 'package:flutter/material.dart';
import 'package:frontend/screens/store_dashboard_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../colors.dart';
import 'LocationPickerScreen.dart';
import 'allergy_screen.dart';
import 'package:latlong2/latlong.dart'; // ✅ flutter_map uses this

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController telephoneController = TextEditingController();
  LatLng? _selectedLocation;
  String selectedRole = 'user'; // default value

  double? latitude;
  double? longitude;

  Future<void> registerUser() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final telephone = telephoneController.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        latitude == null ||
        longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields and choose a location'),
        ),
      );
      return;
    }

    final url = Uri.parse('http://192.168.68.61:3000/api/users/register');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'location': {'latitude': latitude, 'longitude': longitude},
          'role': selectedRole, // 👈 include role
          if (selectedRole == 'store')
            'telephone': telephone, // 👈 only include if store
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        final userId = data['userId'];

        if (selectedRole == 'user') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => AllergyScreen(userId: userId)),
          );
        } else {
          // navigate to a different screen if store, or just show success
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Store registered successfully')),
          );

          // Optional: clear fields
          setState(() {
            nameController.clear();
            emailController.clear();
            passwordController.clear();
            telephoneController.clear();
            latitude = null;
            longitude = null;
            selectedRole = 'user'; // reset to default
          });

          // Or redirect as needed
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Registration failed')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _pickLocation() async {
    final picked = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => LocationPickerScreen(
              initialLocation: _selectedLocation ?? LatLng(32.2211, 35.2544),
            ),
      ),
    );

    if (picked != null && picked is LatLng) {
      setState(() => _selectedLocation = picked);
    }

    if (picked != null && picked is LatLng) {
      setState(() {
        latitude = picked.latitude;
        longitude = picked.longitude;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Location selected')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: green,
      body: Column(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.12,
            padding: const EdgeInsets.only(top: 40, left: 16),
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create new\nAccount',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text(
                          'Already Registered? ',
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/'),
                          child: Text(
                            'Log in here.',
                            style: TextStyle(
                              fontSize: 14,
                              color: green,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    _buildLabel('NAME'),
                    TextField(
                      controller: nameController,
                      decoration: _buildInputDecoration('Jiara Martins'),
                    ),
                    const SizedBox(height: 20),

                    _buildLabel('EMAIL'),
                    TextField(
                      controller: emailController,
                      decoration: _buildInputDecoration(
                        'hello@reallygreatsite.com',
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildLabel('PASSWORD'),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: _buildInputDecoration('******'),
                    ),
                    const SizedBox(height: 20),
                    if (selectedRole == 'store') ...[
                      _buildLabel('TELEPHONE'),
                      TextField(
                        controller: telephoneController,
                        keyboardType: TextInputType.phone,
                        decoration: _buildInputDecoration('+970 598 123 456'),
                      ),
                      const SizedBox(height: 20),
                    ],

                    _buildLabel('LOCATION'),
                    ElevatedButton.icon(
                      onPressed: _pickLocation,
                      icon: const Icon(Icons.location_on, color: Colors.white),
                      label: Text(
                        latitude != null && longitude != null
                            ? 'Location Selected'
                            : 'Pick Location',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),

                    _buildLabel('REGISTER AS'),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      items: const [
                        DropdownMenuItem(value: 'user', child: Text('User')),
                        DropdownMenuItem(value: 'store', child: Text('Store')),
                      ],

                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedRole = value;
                          });
                        }
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: lightGrey,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: registerUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          'Sign up',
                          style: TextStyle(fontSize: 16, color: Colors.white),
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

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        letterSpacing: 1,
        color: Colors.black54,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: lightGrey,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }
}
