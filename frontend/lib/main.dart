import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/', // The initial route (home screen)
      routes: {
        '/': (context) => LoginScreen(), // Define the login screen route
        '/forgot-password':
            (context) => ForgotPasswordScreen(), // Define forgot password route
        '/register': (context) => RegisterScreen(), // Define register route
      },
    );
  }
}
