import 'dart:convert';
import 'package:flutter/material.dart';
import '../colors.dart';

Widget placeCard(
  String title,
  String subtitle,
  String imagePath, {
  double rating = 0.0,
  VoidCallback? onSave,
  bool isSaved = false,
  String? authorName,
  String? authorAvatar,
}) {
  final isBase64 = imagePath.startsWith('/9j');
  final isNetwork = imagePath.startsWith('http');

  ImageProvider imageProvider;
  if (isBase64) {
    imageProvider = MemoryImage(base64Decode(imagePath));
  } else if (isNetwork) {
    imageProvider = NetworkImage(imagePath);
  } else {
    imageProvider = const AssetImage('assets/placeholder.png');
  }

  return Stack(
    children: [
      Container(
        width: 250,
        height: 300,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey[300],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Image(
                image: imageProvider,
                width: 250,
                height: 300,
                fit: BoxFit.cover,
              ),
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  icon: Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: Colors.white,
                  ),
                  onPressed: onSave ?? () {},
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Color.fromARGB(153, 0, 0, 0),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      if (authorName != null && authorAvatar != null)
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 10,
                              backgroundImage: MemoryImage(
                                base64Decode(authorAvatar),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              authorName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
