import 'package:flutter/material.dart';
import 'package:frontend/screens/grocery_screen.dart';
import 'package:frontend/screens/home_screen.dart';
import 'package:frontend/screens/recipe_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DishDash Grocery',
      theme: ThemeData(
        fontFamily: 'Arial',
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: Colors.red.shade900, // Maroon
          secondary: Colors.grey,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
