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
        title: 'Berry Parfait',
        description: 'A light and healthy yogurt parfait with fresh berries and granola.',
        ingredients: ['yogurt', 'strawberries', 'blueberries', 'granola', 'honey'],
        instructions: 'Layer yogurt, berries, and granola in a glass and drizzle with honey.',
        image: 'https://example.com/images/berry-parfait.jpg',
        calories: 200,
        type: 'Desserts',
        mealTime: 'Breakfast',
        ratings: [5, 4, 3, 5, 2],
      },
      {
        title: 'Vegan Burger',
        description: 'Tasty plant-based burger perfect for lunch.',
        ingredients: ['vegan patty', 'lettuce', 'tomato', 'vegan mayo', 'burger bun'],
        instructions: 'Grill patty, assemble burger with toppings and enjoy!',
        image: 'https://example.com/images/vegan-burger.jpg',
        calories: 400,
        type: 'Vegan',
        mealTime: 'Lunch',
        ratings: [1,1,1,1,1],
      },
      {
        title: 'Garlic-Butter Rib Roast',
        description: 'Juicy and flavorful rib roast infused with garlic butter.',
        ingredients: ['rib roast', 'butter', 'garlic', 'rosemary'],
        instructions: 'Season roast, bake in oven at 375°F, baste with garlic butter.',
        image: 'https://example.com/images/rib-roast.jpg',
        calories: 800,
        type: 'Meat',
        mealTime: 'Dinner',
        ratings: [2,2,2,2,2],
      },
      {
        title: 'Ceaser Salad',
        description: 'Classic ceaser salad with creamy dressing.',
        ingredients: ['romaine', 'croutons', 'parmesan', 'caesar dressing'],
        instructions: 'Toss ingredients together and serve.',
        image: 'https://example.com/images/caeser-salad.jpg',
        calories: 250,
        type: 'Soups',
        mealTime: 'Lunch',
        ratings: [4,4,2,1,5],
      },
      {
        title: 'Lasagna',
        description: 'Rich lasagna layered with beef and cheese.',
        ingredients: ['pasta sheets', 'beef', 'cheese', 'tomato sauce'],
        instructions: 'Layer all ingredients and bake at 350°F for 45 minutes.',
        image: 'https://example.com/images/lasagna.jpg',
        calories: 600,
        type: 'Quick Meals',
        mealTime: 'Dinner',
        ratings: [3,4,1,5,5],
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
