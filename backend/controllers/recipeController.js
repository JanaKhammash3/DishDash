const Recipe = require('../models/Recipe');

exports.createRecipe = async (req, res) => {
  try {
    const {
      title,
      description,
      ingredients,
      instructions,
      image,
      calories,
      diet,        // ✅ NEW
      mealType,    // ✅ NEW
      prepTime,    // ✅ NEW
      tags,        // ✅ NEW (array)
      author
    } = req.body;

    const newRecipe = await Recipe.create({
      title,
      description,
      ingredients,
      instructions,
      image,
      calories,
      diet,
      mealType,
      prepTime,
      tags,
      author
    });

    res.status(201).json(newRecipe);
  } catch (err) {
    res.status(500).json({ message: 'Error creating recipe', error: err.message });
  }
};

// GET /api/recipes
exports.getAllRecipes = async (req, res) => {
  const { diet, mealTime, tag, minCalories, maxCalories, maxPrepTime } = req.query;

  
  let filter = {};

  if (diet) filter.diet = diet;
  if (mealTime) filter.mealTime = mealTime;
  if (tag) filter.tags = { $in: [tag] };
  if (minCalories || maxCalories) {
    filter.calories = {};
    if (minCalories) filter.calories.$gte = Number(minCalories);
    if (maxCalories) filter.calories.$lte = Number(maxCalories);
  }
  if (maxPrepTime) filter.prepTime = { $lte: Number(maxPrepTime) };

  

  try {
    const recipes = await Recipe.find(filter).populate('author', 'name avatar');
    res.json(recipes);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};




exports.deleteRecipe = async (req, res) => {
  try {
    const { id } = req.params;
    await Recipe.findByIdAndDelete(id);
    res.status(200).json({ message: 'Recipe deleted' });
  } catch (err) {
    res.status(500).json({ error: 'Failed to delete recipe' });
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
    const { rating } = req.body;

    // Validate the rating
    if (typeof rating !== 'number' || rating < 1 || rating > 5) {
      return res.status(400).json({ message: "Invalid rating value" });
    }

    const recipe = await Recipe.findById(id);
    if (!recipe) {
      return res.status(404).json({ message: "Recipe not found" });
    }

    recipe.ratings.push(rating); // ✅ push only if valid
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


exports.filterRecipes = async (req, res) => {
  try {
    const { diet, mealTime, minCalories, maxCalories, maxPrepTime, tags } = req.query;

    const filter = {};

    if (diet) filter.diet = diet;
    if (mealTime) filter.mealTime = mealTime;
    if (minCalories || maxCalories) {
      filter.calories = {};
      if (minCalories) filter.calories.$gte = Number(minCalories);
      if (maxCalories) filter.calories.$lte = Number(maxCalories);
    }
    if (maxPrepTime) filter.prepTime = { $lte: Number(maxPrepTime) };
    if (tags) {
      // If tags are comma-separated like ?tags=gluten-free,spicy
      const tagArray = tags.split(',').map(t => t.trim());
      filter.tags = { $all: tagArray };
    }

    const recipes = await Recipe.find(filter).populate('author', 'name avatar');
    res.status(200).json(recipes);
  } catch (err) {
    res.status(500).json({ message: 'Failed to filter recipes', error: err.message });
  }
};

exports.getAllRecipes = async (req, res) => {
  const recipes = await Recipe.find().populate('author', 'name avatar');
  res.json(recipes);
};