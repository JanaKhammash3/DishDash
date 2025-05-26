import 'package:flutter/material.dart';
import 'package:frontend/screens/AiRecipeFormScreen.dart';
import 'package:frontend/screens/image_torecipe.dart';
import 'package:frontend/colors.dart';

class AiScreen extends StatelessWidget {
  final String userId;
  const AiScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: green,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'AI Assistant',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 🌟 Green Glow AI Icon
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [green, Color(0xFFA3E4B4)], // Light green
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: green.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Explore AI-Powered Tools',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E7D32), // Deep green for text
              ),
            ),
            const SizedBox(height: 20),

            // 🧠 AI Tools
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: _buildModuleCard(
                      context,
                      title: 'AI Recipe Creator',
                      description:
                          'Generate recipes using your ingredients and dietary needs.',
                      icon: Icons.auto_awesome,
                      gradientColors: [
                        Colors.deepOrange,
                        Colors.orangeAccent,
                      ], // 🔁 swapped to orange
                      borderColor: Colors.deepOrange,
                      onTap:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => AiRecipeFormScreen(userId: userId),
                            ),
                          ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _buildModuleCard(
                      context,
                      title: 'Image to Recipe',
                      description:
                          'Upload a food image and AI will generate the recipe.',
                      icon: Icons.image_search,
                      gradientColors: [
                        green,
                        const Color(0xFF66BB6A),
                      ], // 🔁 swapped to green
                      borderColor: green,
                      onTap:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => AiImageToRecipeScreen(userId: userId),
                            ),
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required List<Color> gradientColors,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor.withOpacity(0.25), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: borderColor.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: borderColor.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
