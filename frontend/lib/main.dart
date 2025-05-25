import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/ChatsScreen.dart'; // 👈 Make sure this is imported
import 'screens/home_screen.dart'; // Optional: Add your home screen

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/', // The initial route (login screen)
      routes: {
        '/': (context) => const LoginScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/register': (context) => const RegisterScreen(),
      },
      // 👇 Handle dynamic routes like /chats with arguments
      onGenerateRoute: (settings) {
        if (settings.name == '/chats') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder:
                (context) => ChatsScreen(
                  userId: args['userId'],
                  initialChatUserId: args['initialChatUserId'],
                ),
          );
        }

        // Add fallback or error route
        return MaterialPageRoute(
          builder:
              (context) =>
                  const Scaffold(body: Center(child: Text('Route not found'))),
        );
      },
    );
  }
}
