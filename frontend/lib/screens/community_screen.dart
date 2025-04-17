import 'package:flutter/material.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample data
    final List<Map<String, dynamic>> posts = [
      {
        'username': 'Alice',
        'userImage': 'https://i.pravatar.cc/150?img=1',
        'recipeImage':
            'https://images.unsplash.com/photo-1504674900247-0877df9cc836',
        'caption': 'Spicy chicken curry with a twist!',
        'likes': 120,
        'comments': 24,
      },
      {
        'username': 'Bob',
        'userImage': 'https://i.pravatar.cc/150?img=2',
        'recipeImage':
            'https://images.unsplash.com/photo-1546069901-ba9599a7e63c',
        'caption': 'My favorite vegan lasagna 😋',
        'likes': 90,
        'comments': 10,
      },
      {
        'username': 'Sophie',
        'userImage': 'https://i.pravatar.cc/150?img=3',
        'recipeImage':
            'https://images.unsplash.com/photo-1525351484163-7529414344d8',
        'caption': 'Tried a gluten-free banana bread today 🍌🍞',
        'likes': 75,
        'comments': 8,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Our Community'),
        backgroundColor: Colors.red.shade900,
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          final String username = post['username'] as String;
          final String userImage = post['userImage'] as String;
          final String recipeImage = post['recipeImage'] as String;
          final String caption = post['caption'] as String;
          final int likes = post['likes'] as int;
          final int comments = post['comments'] as int;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(userImage),
                  ),
                  title: Text(
                    username,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    recipeImage,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8,
                  ),
                  child: Text(caption),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.favorite, color: Colors.red.shade900),
                      const SizedBox(width: 4),
                      Text('$likes'),
                      const SizedBox(width: 16),
                      const Icon(Icons.comment, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('$comments'),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          );
        },
      ),
    );
  }
}
