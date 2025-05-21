import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> _login(BuildContext context) async {
    final url = Uri.parse('http://192.168.0.101:3000/api/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': emailController.text.trim(),
        'password': passwordController.text.trim(),
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('🛂 Login response: $data');

      final user = data['user'];
      final userId = user['_id'];
      final type = data['type'];
      final role = data['role'] ?? user['role'] ?? type;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', userId);

      if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else if (role == 'store') {
        await prefs.setString('storeId', userId);
        Navigator.pushReplacementNamed(context, '/store');
      } else {
        _showError(context, 'Access denied. Invalid role.');
      }
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        color: const Color(0xFFF5F5F5), // Light grey background
        child: Row(
          children: [
            // ✅ LEFT GREEN PANEL
            Expanded(
              flex: 1,
              child: ClipPath(
                clipper: RightWaveClipper(),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF304D30), Color(0xFF2C3E2B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 20,
                  ),
                  child: Transform.translate(
                    offset: const Offset(-50, 0), // Slight shift left
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(), // Top spacer
                        // ✅ Centered content
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ClipOval(
                              child: Image.asset(
                                'assets/Food.gif',
                                width: 180,
                                height: 180,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 32),
                            const Text(
                              'Welcome Back!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Manage your dashboard efficiently\nwith secure login access.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),

                        // ✅ Bottom logo
                        Column(
                          children: [
                            Image.asset('assets/Login.png', width: 100),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ✅ RIGHT PANEL
            Expanded(
              flex: 1,
              child: Transform.translate(
                offset: const Offset(-70, 0), // Move left to hide gap
                child: Container(
                  color: const Color(0xFFF5F5F5),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(40),
                          bottomLeft: Radius.circular(40),
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 48,
                            vertical: 40,
                          ),
                          color: const Color(0xFFF5F5F5),
                          child: Center(
                            child: Container(
                              width: 430,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 12,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    "Login",
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF304D30),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    "Please enter your credentials",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  const SizedBox(height: 24),
                                  TextField(
                                    controller: emailController,
                                    decoration: InputDecoration(
                                      labelText: 'Email',
                                      prefixIcon: const Icon(Icons.email),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[100],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  TextField(
                                    controller: passwordController,
                                    obscureText: true,
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      prefixIcon: const Icon(Icons.lock),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[100],
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () => _login(context),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF304D30,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        "Login",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
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
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ✅ Custom wave clipper
class RightWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(size.width * 0.75, 0);
    path.quadraticBezierTo(
      size.width,
      size.height / 2,
      size.width * 0.75,
      size.height,
    );
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
