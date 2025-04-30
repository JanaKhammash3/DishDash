const Recipe = require('../models/Recipe');

exports.createRecipe = async (req, res) => {
  try {
    const newRecipe = await Recipe.create(req.body);
    res.status(201).json(newRecipe);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

exports.getAllRecipes = async (req, res) => {
  try {
    const recipes = await Recipe.find();
    res.status(200).json(recipes);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

exports.getRecipeById = async (req, res) => {
  try {
    const recipe = await Recipe.findById(req.params.id);
    res.status(200).json(recipe);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

exports.searchByIngredients = async (req, res) => {
  try {
    const ingredients = req.params.ingredients.split(',');
    const recipes = await Recipe.find({ ingredients: { $in: ingredients } });
    res.status(200).json(recipes);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};
exports.rateRecipe = async (req, res) => {
  try {
    const { id } = req.params;
    const { value } = req.body; // 🔥 Only value

    const recipe = await Recipe.findById(id);
    if (!recipe) return res.status(404).json({ message: "Recipe not found" });

    recipe.ratings.push(value); // 🔥 Just push the number
    await recipe.save();

    res.status(200).json({ message: "Rating added", recipe });
  } catch (error) {
    res.status(500).json({ message: "Server error", error });
  }
};

// ✅ NEW: Get Popular Recipes
exports.getPopularRecipes = async (req, res) => {
  try {
    const recipes = await Recipe.find().sort({ averageRating: -1 }).limit(4);
    res.status(200).json(recipes);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

// ✅ NEW: Get Recommended Recipes (e.g., random or based on logic)
exports.getRecommendedRecipes = async (req, res) => {
  try {
    const count = await Recipe.countDocuments();
    const skip = Math.max(0, Math.floor(Math.random() * (count - 3)));
    const recipes = await Recipe.find().skip(skip).limit(3);
    res.status(200).json(recipes);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

// ✅ NEW: Search Recipes by Query (title, description, etc.)
exports.searchRecipes = async (req, res) => {
  try {
    const { query } = req.query;
    const regex = new RegExp(query, 'i');
    const recipes = await Recipe.find({
      $or: [
        { title: regex },
        { description: regex },
        { ingredients: regex },
      ],
    });
    res.status(200).json(recipes);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

// ✅ NEW: Filter Recipes by type, calories, mealTime
exports.filterRecipes = async (req, res) => {
  try {
    const { type, mealTime, calories } = req.body;
    const filter = {};

    if (type) filter.type = { $in: type };
    if (mealTime) filter.mealTime = { $in: mealTime };
    if (calories && calories.length) {
      filter.calories = {
        $gte: calories[0],
        $lte: calories[1],
      };
    }

    const recipes = await Recipe.find(filter);
    res.status(200).json(recipes);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};