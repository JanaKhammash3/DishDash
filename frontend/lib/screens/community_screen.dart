import 'package:flutter/material.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  _CommunityScreenState createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  List<Map<String, dynamic>> posts = [
    {
      'username': 'Alice',
      'userImage': 'https://i.pravatar.cc/150?img=1',
      'recipeImage':
          'https://images.unsplash.com/photo-1504674900247-0877df9cc836',
      'caption': 'Spicy chicken curry with a twist!',
      'likes': 120,
      'comments': 2,
      'liked': false,
    },
    {
      'username': 'Bob',
      'userImage': 'https://i.pravatar.cc/150?img=2',
      'recipeImage':
          'https://images.unsplash.com/photo-1546069901-ba9599a7e63c',
      'caption': 'My favorite vegan lasagna 😋',
      'likes': 90,
      'comments': 1,
      'liked': false,
    },
    {
      'username': 'Sophie',
      'userImage': 'https://i.pravatar.cc/150?img=3',
      'recipeImage':
          'https://images.unsplash.com/photo-1525351484163-7529414344d8',
      'caption': 'Tried a gluten-free banana bread today 🍌🍞',
      'likes': 75,
      'comments': 0,
      'liked': false,
    },
  ];

  List<Map<String, dynamic>> savedRecipes = [];

  void saveRecipe(Map<String, dynamic> recipe) {
    setState(() {
      savedRecipes.add(recipe);
    });
  }

  void toggleLike(int index) {
    setState(() {
      posts[index]['liked'] = !posts[index]['liked'];
      posts[index]['likes'] += posts[index]['liked'] ? 1 : -1;
    });
  }

  void addComment(int index) async {
    final TextEditingController _controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Add Comment"),
            content: TextField(
              controller: _controller,
              decoration: const InputDecoration(hintText: 'Type your comment'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, _controller.text),
                child: const Text("Post"),
              ),
            ],
          ),
    );

    if (result != null && result.trim().isNotEmpty) {
      setState(() {
        posts[index]['comments'] += 1;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Comment added!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Our Community',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red.shade900,
        centerTitle: true,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SavedRecipesScreen(savedRecipes),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];

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
                    backgroundImage: NetworkImage(post['userImage']),
                  ),
                  title: Text(
                    post['username'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    post['recipeImage'],
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
                  child: Text(post['caption']),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          post['liked']
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: post['liked'] ? Colors.red : Colors.grey,
                        ),
                        onPressed: () => toggleLike(index),
                      ),
                      Text('${post['likes']}'),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.comment, color: Colors.grey),
                        onPressed: () => addComment(index),
                      ),
                      Text('${post['comments']}'),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.save_alt, color: Colors.blue),
                        onPressed: () {
                          saveRecipe(post);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Recipe saved!')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class SavedRecipesScreen extends StatelessWidget {
  final List<Map<String, dynamic>> savedRecipes;

  const SavedRecipesScreen(this.savedRecipes, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Saved Recipes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red.shade900,
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      body:
          savedRecipes.isEmpty
              ? const Center(child: Text('No saved recipes yet.'))
              : ListView.builder(
                itemCount: savedRecipes.length,
                itemBuilder: (context, index) {
                  final recipe = savedRecipes[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          title: Text(
                            recipe['username'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            recipe['recipeImage'],
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
                          child: Text(recipe['caption']),
                        ),
                      ],
                    ),
                  );
                },
              ),
    );
  }
}
