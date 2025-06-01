import 'package:dishdash_web/pages/stores_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferences;
import 'pages/login_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/userSidebar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DishDash Admin',
      initialRoute: '/',
      routes: {
        '/': (_) => LoginPage(),
        '/dashboard': (_) => DashboardPage(),
        '/store': (_) => StoresDashboard(), // ✅ Add this route
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/user') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => UserDashboardWrapper(userId: args['userId']),
          );
        }
        return null;
      },
    );
  }
}
