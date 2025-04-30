class Recipe {
  final String id;
  final String title;
  final String description;
  final String image;
  final int calories;
  final String type;
  final String mealTime;

  Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.image,
    required this.calories,
    required this.type,
    required this.mealTime,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['_id'],
      title: json['title'],
      description: json['description'] ?? '',
      image: json['image'] ?? '',
      calories: json['calories'] ?? 0,
      type: json['type'] ?? '',
      mealTime: json['mealTime'] ?? '',
    );
  }
}
