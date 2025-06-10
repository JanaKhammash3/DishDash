import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../colors.dart';
import 'OtpResetScreen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  void _showDialog(String title, String message, {VoidCallback? onOk}) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  if (onOk != null) onOk();
                },
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  // ✅ Then define _sendOtp
  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showDialog('Error', 'Please enter a valid email.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://192.168.68.61:3000/api/users/request-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      setState(() => _isLoading = false); // ✅ always stop loading here

      String message = 'An OTP has been sent to your email.';
      if (response.statusCode == 200) {
        // ✅ Safe decode
        if (response.body.isNotEmpty) {
          try {
            final data = jsonDecode(response.body);
            message = data['message'] ?? message;
          } catch (_) {} // ignore parsing errors
        }

        _showDialog(
          'Success',
          message,
          onOk: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => OtpResetScreen(email: email)),
            );
          },
        );
      } else {
        String errorMsg = 'Something went wrong.';
        if (response.body.isNotEmpty) {
          try {
            final data = jsonDecode(response.body);
            errorMsg = data['message'] ?? errorMsg;
          } catch (_) {}
        }
        _showDialog('Error', errorMsg);
      }
    } catch (e) {
      setState(() => _isLoading = false); // ✅ stop loading on network error
      _showDialog('Error', 'Failed to send request. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.3,
            padding: const EdgeInsets.only(top: 70, left: 24),
            decoration: const BoxDecoration(
              color: green,
              borderRadius: BorderRadius.only(bottomRight: Radius.circular(60)),
            ),
            alignment: Alignment.topLeft,
            child: const Text(
              'FORGOT\nPASSWORD',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 32.0,
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 70,
                      color: Colors.black,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Trouble Logging in?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Enter your email and we'll send you\na link to reset your password.",
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'EMAIL',
                        style: TextStyle(
                          fontSize: 12,
                          letterSpacing: 1,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        hintText: 'hello@reallygreatsite.com',
                        filled: true,
                        fillColor: lightGrey,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _sendOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child:
                            _isLoading
                                ? const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                )
                                : const Text(
                                  'Reset Password',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Return to Login Page',
                        style: TextStyle(
                          color: Colors.black87,
                          decoration: TextDecoration.underline,
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
