// lib/widgets/category_filters.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../colors.dart';

typedef CategoryFilterCallback = void Function(String category);

class CategoryFilters extends StatelessWidget {
  final String selectedCategory;
  final CategoryFilterCallback onCategorySelected;

  const CategoryFilters({
    Key? key,
    required this.selectedCategory,
    required this.onCategorySelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final categories = [
      {'label': 'Vegan', 'icon': LucideIcons.leaf},
      {'label': 'Vegetarian', 'icon': LucideIcons.salad},
      {'label': 'Keto', 'icon': LucideIcons.beef},
      {'label': 'Low-Carb', 'icon': LucideIcons.egg},
      {'label': 'Lunch', 'icon': LucideIcons.soup},
      {'label': 'Breakfast', 'icon': LucideIcons.sun},
      {'label': 'Dinner', 'icon': LucideIcons.moon},
      {'label': 'Snack', 'icon': LucideIcons.cookie},
      {'label': 'Dessert', 'icon': LucideIcons.cupSoda},
    ];

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (_, index) {
          final category = categories[index];
          final isSelected = selectedCategory == category['label'];
          return GestureDetector(
            onTap: () => onCategorySelected(category['label']! as String),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isSelected ? Colors.black : maroon,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      category['icon'] as IconData,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category['label'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
