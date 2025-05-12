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
          final Color bgColor = isSelected ? Colors.white : green;
          final Color textColor = isSelected ? green : Colors.white;

          return GestureDetector(
            onTap: () => onCategorySelected(category['label']! as String),
            child: Container(
              width: 90,
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: green),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    category['icon'] as IconData,
                    color: textColor,
                    size: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category['label'] as String,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
