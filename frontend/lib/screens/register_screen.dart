import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  String? email, password, confirmPassword;
  bool isLoading = false;

  Future<void> registerUser() async {
    final url = Uri.parse('http://localhost:3000/api/auth/register');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        // Success — navigate to home
        // ignore: use_build_context_synchronously
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // Show error
        showDialog(
          // ignore: use_build_context_synchronously
          context: context,
          builder:
              (_) => AlertDialog(
                title: Text('Registration Failed'),
                content: Text(data['message'] ?? 'Unknown error'),
              ),
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void handleSubmit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (password != confirmPassword) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Passwords do not match')));
        return;
      }

      setState(() => isLoading = true);
      registerUser();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                'Create Account',
                style: TextStyle(fontSize: 26),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              TextFormField(
                decoration: InputDecoration(labelText: 'Email'),
                onSaved: (val) => email = val,
                validator: (val) => val!.isEmpty ? 'Enter your email' : null,
              ),
              SizedBox(height: 10),
              TextFormField(
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                onSaved: (val) => password = val,
                validator: (val) => val!.length < 6 ? 'Min 6 characters' : null,
              ),
              SizedBox(height: 10),
              TextFormField(
                decoration: InputDecoration(labelText: 'Confirm Password'),
                obscureText: true,
                onSaved: (val) => confirmPassword = val,
                validator:
                    (val) => val!.isEmpty ? 'Confirm your password' : null,
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: isLoading ? null : handleSubmit,
                child:
                    isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text('Register'),
              ),
              TextButton(
                child: Text('Already have an account? Login'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
