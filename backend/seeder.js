// seeder.js
const mongoose = require('mongoose');
const Recipe = require('./models/Recipe'); // <-- Update the path if needed

async function seed() {
  try {
    await mongoose.connect('mongodb+srv://zainabubaker:zainZainzain2002@cluster0.qjep15r.mongodb.net/', {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });

    console.log('MongoDB connected 🌟');

    // Clear previous recipes (optional, if you want to wipe first)
    await Recipe.deleteMany();

    const recipes = [
      {
        title: 'Vegan Tofu Scramble',
        description: 'A protein-rich breakfast made with crumbled tofu and veggies.',
        ingredients: ['Tofu', 'Spinach', 'Tomatoes', 'Turmeric', 'Salt', 'Pepper'],
        instructions: 'Sauté crumbled tofu with spices and vegetables until cooked.',
        image: 'http://192.168.0.101:3000/images/vegan-tofu-scramble.jpg',
        calories: 220,
        diet: 'Vegan',
        mealTime: 'Breakfast',
        prepTime: 15,
        tags: ['gluten-free', 'spicy'],
        ratings: [5, 4, 5, 5],
      },
      {
        title: 'Avocado Toast with Chickpeas',
        description: 'Crispy toast topped with smashed avocado and seasoned chickpeas.',
        ingredients: ['Bread', 'Avocado', 'Chickpeas', 'Lemon Juice', 'Chili Flakes'],
        instructions: 'Toast bread, top with mashed avocado and seasoned chickpeas.',
        image: 'http://192.168.0.101:3000/images/avocado-toast-with-chickpeas.jpg',
        calories: 300,
        diet: 'Vegan',
        mealTime: 'Breakfast',
        prepTime: 10,
        tags: ['spicy'],
        ratings: [3, 4],
      },
      {
        title: 'Keto Chicken Caesar Salad',
        description: 'Grilled chicken over romaine with keto-friendly Caesar dressing.',
        ingredients: ['Chicken Breast', 'Romaine', 'Parmesan', 'Keto Caesar Dressing'],
        instructions: 'Grill chicken, toss with salad and dressing.',
        image: 'http://192.168.0.101:3000/images/keto-chicken-saladjpg.jpg',
        calories: 420,
        diet: 'Keto',
        mealTime: 'Lunch',
        prepTime: 20,
        tags: ['gluten-free'],
        ratings: [4, 5, 4],
      },
      {
        title: 'Keto Avocado Egg Bowl',
        description: 'Low-carb lunch bowl with boiled eggs and creamy avocado.',
        ingredients: ['Eggs', 'Avocado', 'Spinach', 'Lemon Juice'],
        instructions: 'Boil eggs, serve with avocado and greens.',
        image: 'http://192.168.0.101:3000/images/keto-avocado-egg-bowl.jpg',
        calories: 350,
        diet: 'Keto',
        mealTime: 'Lunch',
        prepTime: 15,
        tags: [],
        ratings: [2, 3],
      },
      {
        title: 'Low-Carb Zucchini Noodles',
        description: 'Zoodles with garlic, tomatoes, and Parmesan.',
        ingredients: ['Zucchini', 'Tomatoes', 'Garlic', 'Parmesan'],
        instructions: 'Sauté zoodles with garlic and top with Parmesan.',
        image: 'http://192.168.0.101:3000/images/low-carb-zucchini-noodles.jpg',
        calories: 200,
        diet: 'Low-Carb',
        mealTime: 'Dinner',
        prepTime: 25,
        tags: ['gluten-free'],
        ratings: [4, 3],
      },
      {
        title: 'Low-Carb Cauliflower Fried Rice',
        description: 'Cauliflower rice with veggies and soy sauce.',
        ingredients: ['Cauliflower', 'Carrots', 'Peas', 'Soy Sauce', 'Egg'],
        instructions: 'Stir-fry all ingredients together.',
        image: 'http://192.168.0.101:3000/images/low-carb-cauliflower-fried-ricepng.png',
        calories: 250,
        diet: 'Low-Carb',
        mealTime: 'Dinner',
        prepTime: 20,
        tags: [],
        ratings: [5, 5, 4, 4],
      },
      {
        title: 'Vegetarian Banana Oat Cookies',
        description: 'Healthy dessert made with bananas and oats.',
        ingredients: ['Bananas', 'Oats', 'Cinnamon'],
        instructions: 'Mash bananas, mix with oats and bake.',
        image: 'http://192.168.0.101:3000/images/banana-cookies.jpg',
        calories: 180,
        diet: 'Vegetarian',
        mealTime: 'Dessert',
        prepTime: 30,
        tags: ['lactose-free'],
        ratings: [3, 2],
      },
      {
        title: 'Vegetarian Chocolate Avocado Mousse',
        description: 'Creamy and rich chocolate mousse with avocado.',
        ingredients: ['Avocado', 'Cocoa Powder', 'Maple Syrup'],
        instructions: 'Blend all ingredients until smooth and chill.',
        image: 'http://192.168.0.101:3000/images/chocolate-avocado-mousse.jpg',
        calories: 280,
        diet: 'Vegetarian',
        mealTime: 'Dessert',
        prepTime: 10,
        tags: ['gluten-free', 'lactose-free'],
        ratings: [5, 4, 5],
      },
    ];
    

    await Recipe.insertMany(recipes);

    console.log('Seeding completed 🎯');
    process.exit();
  } catch (error) {
    console.error('Error seeding database:', error.message);
    process.exit(1);
  }
}

seed();
