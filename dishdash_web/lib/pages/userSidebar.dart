import 'package:flutter/material.dart';
import 'homescreen.dart';
import 'community.dart';
import 'my_recipes.dart';
import 'package:dishdash_web/pages/users_courses_page.dart';

final Color beigeBackground = const Color(0xFFF5F4F0);
final Color beigeCard = const Color(0xFFFAF9F6);
final Color beigeBorder = const Color(0xFFDAD4C2);
final Color beigeAccent = const Color(0xFFB9A67D);
final Color iconMuted = const Color(0xFF7C7155);

class UserDashboardWrapper extends StatefulWidget {
  final String userId;
  const UserDashboardWrapper({super.key, required this.userId});

  @override
  State<UserDashboardWrapper> createState() => _UserDashboardWrapperState();
}

class _UserDashboardWrapperState extends State<UserDashboardWrapper> {
  int selectedIndex = 0;

  final List<String> menuTitles = [
    'Home',
    'Profile',
    'Community',
    'My Recipes',
    'Courses',
  ];

  final List<IconData> icons = [
    Icons.home,
    Icons.person,
    Icons.people_alt,
    Icons.book,
    Icons.video_library,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: beigeBackground,
      body: Row(
        children: [
          buildSidebar(),
          Expanded(
            child: IndexedStack(
              index: selectedIndex,
              children: [
                UserHomeScreen(userId: widget.userId),
                Placeholder(child: Text("Profile Page")), // Replace soon
                CommunityScreen(userId: widget.userId),
                MyRecipesWebPage(userId: widget.userId),
                UserCoursesPage(userId: widget.userId),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSidebar() {
    return Container(
      width: 240,
      color: const Color(0xFF304D30),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/Login.png', width: 20, height: 20),
              const SizedBox(width: 8),
              const Text(
                'DishDash',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          ...List.generate(menuTitles.length, (index) {
            final isSelected = selectedIndex == index;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? Colors.white.withOpacity(0.1)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Icon(icons[index], color: Colors.white),
                title: Text(
                  menuTitles[index],
                  style: const TextStyle(color: Colors.white),
                ),
                selected: isSelected,
                selectedTileColor: Colors.white.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () => setState(() => selectedIndex = index),
              ),
            );
          }),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Logout', style: TextStyle(color: Colors.white)),
            onTap: () async {
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
