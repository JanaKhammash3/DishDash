import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('DishDash Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome to DishDash!', style: TextStyle(fontSize: 22)),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('Start DishDash'),
              onPressed: () {
                Navigator.pushNamed(context, '/planner');
              },
            ),
          ],
        ),
      ),
    );
  }
}
