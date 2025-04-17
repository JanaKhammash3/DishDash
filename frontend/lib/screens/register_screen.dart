import 'package:flutter/material.dart';
import '../colors.dart'; // Make sure the colors.dart file is correct

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: maroon,
      body: Column(
        children: [
          // Maroon top bar with back arrow
          Container(
            height: MediaQuery.of(context).size.height * 0.12,
            padding: const EdgeInsets.only(top: 40, left: 16),
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // White form section
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

                    // Already registered - styled text
                    Row(
                      children: [
                        const Text(
                          'Already Registered? ',
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/');
                          },
                          child: Text(
                            'Log in here.',
                            style: TextStyle(
                              fontSize: 14,
                              color: maroon,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // Name
                    _buildLabel('NAME'),
                    _buildTextField('Jiara Martins'),
                    const SizedBox(height: 20),

                    // Email
                    _buildLabel('EMAIL'),
                    _buildTextField('hello@reallygreatsite.com'),
                    const SizedBox(height: 20),

                    // Password
                    _buildLabel('PASSWORD'),
                    _buildTextField('******', isPassword: true),
                    const SizedBox(height: 20),

                    // Date of Birth
                    _buildLabel('DATE OF BIRTH'),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: lightGrey,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      hint: const Text("Select"),
                      items:
                          ['2000-01-01', '2001-02-02', '2002-03-03']
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                      onChanged: (val) {},
                    ),

                    const SizedBox(height: 32),

                    // Sign Up Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          // Handle registration logic
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: maroon,
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

  // Reusable label builder
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

  // Reusable text field builder
  Widget _buildTextField(String hint, {bool isPassword = false}) {
    return TextField(
      obscureText: isPassword,
      decoration: InputDecoration(
        filled: true,
        fillColor: lightGrey,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
