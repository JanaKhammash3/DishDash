import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> _login(BuildContext context) async {
    final url = Uri.parse('http://192.168.68.60:3000/api/users/login');
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
      final user = data['user'];
      final role = user['role'];
      final userId = user['_id'];

      if (role == 'admin') {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', userId);

        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        _showError(context, 'Access denied. You are not an admin.');
      }
    } else {
      _showError(context, 'Invalid credentials');
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
      backgroundColor: const Color(0xFF304D30),
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black26)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/Logo.png', width: 100, height: 100),
              const SizedBox(height: 4),
              const Text(
                "Login",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF304D30),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Please enter your credentials",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF304D30),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 80,
                    vertical: 16,
                  ),
                ),
                onPressed: () => _login(context),
                child: const Text(
                  "Login",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
