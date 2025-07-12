
const Recipe = require('../models/Recipe');
const Comment = require('../models/Comment');
exports.createCustomRecipe = async (req, res) => {
  try {
    const {
      title,
      description,
      ingredients,
      instructions,
      image,
      calories,
      diet,
      mealTime,
      prepTime,
      difficulty,
      tags,
      author,
    } = req.body;

    const safeIngredients = Array.isArray(ingredients)
      ? ingredients.flatMap(i => i.split(',').map(x => x.trim()))
      : typeof ingredients === 'string'
        ? ingredients.split(',').map(i => i.trim())
        : [];

    const safeTags = Array.isArray(tags)
      ? tags
      : typeof tags === 'string' && tags.trim() !== ''
        ? [tags.trim()]
        : [];

    const newRecipe = await Recipe.create({
      title,
      description,
      ingredients: safeIngredients,
      instructions,
      image,
      calories,
      diet,
      mealTime,
      prepTime,
      difficulty,
      tags: safeTags,
      author,
    });

    res.status(201).json(newRecipe);
  } catch (err) {
    console.error('❌ Custom recipe error:', err);
    res.status(500).json({ message: 'Error creating custom recipe', error: err.message });
  }
};

exports.getAllRecipes = async (req, res) => {
  const { diet, mealTime, tag, minCalories, maxCalories, minPrepTime, maxPrepTime, difficulty } = req.query;
  let filter = {};

  if (diet) filter.diet = diet;
  if (mealTime) filter.mealTime = mealTime;
  if (difficulty) filter.difficulty = difficulty;
  if (tag) filter.tags = { $in: [tag] };

  if (minCalories || maxCalories) {
    filter.calories = {};
    if (minCalories) filter.calories.$gte = Number(minCalories);
    if (maxCalories) filter.calories.$lte = Number(maxCalories);
  }

  if (minPrepTime || maxPrepTime) {
    filter.prepTime = {};
    if (minPrepTime) filter.prepTime.$gte = Number(minPrepTime);
    if (maxPrepTime) filter.prepTime.$lte = Number(maxPrepTime);
  }

  try {
    filter.isPublic=true;
    const recipes = await Recipe.find(filter).populate('author', 'name avatar');
    res.json(recipes);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

exports.filterRecipes = async (req, res) => {
  try {
    const {
      diet, mealTime, minCalories, maxCalories, minPrepTime,
      maxPrepTime, tags, difficulty, ingredients
    } = req.query;

    const filter = {};

    if (diet) filter.diet = diet;
    if (mealTime) filter.mealTime = mealTime;
    if (difficulty) filter.difficulty = difficulty;

    if (minCalories || maxCalories) {
      filter.calories = {};
      if (minCalories) filter.calories.$gte = Number(minCalories);
      if (maxCalories) filter.calories.$lte = Number(maxCalories);
    }

    if (minPrepTime || maxPrepTime) {
      filter.prepTime = {};
      if (minPrepTime) filter.prepTime.$gte = Number(minPrepTime);
      if (maxPrepTime) filter.prepTime.$lte = Number(maxPrepTime);
    }

    if (tags) {
      const tagArray = tags.split(',').map(t => t.trim());
      filter.tags = { $all: tagArray };
    }

    if (ingredients) {
      const ingredientArray = ingredients
        .split(',')
        .map(i => i.trim().toLowerCase())
        .filter(Boolean);
    
      filter.$and = ingredientArray.map(kw => ({
        ingredients: {
          $elemMatch: {
            $regex: new RegExp(kw, 'i'),
          },
        },
      }));
    }
    
    filter.isPublic=true;
    const recipes = await Recipe.find(filter).populate('author', 'name avatar');
    res.status(200).json(recipes);
  } catch (err) {
    res.status(500).json({ message: 'Failed to filter recipes', error: err.message });
  }
};

const unitPattern = /\b(\d+\/\d+|\d+\.\d+|\d+|cup|cups|tbsp|tsp|tablespoon|teaspoon|grams?|ml|oz|kg|lb|liters?|pinch|dash|of)\b/gi;

exports.searchByIngredients = async (req, res) => {
  try {
    const rawKeywords = req.params.ingredients
      .split(',')
      .map(w => w.trim().toLowerCase())
      .filter(Boolean);

    // Remove units/numbers/specials from each keyword
    const cleanedKeywords = rawKeywords.map(kw =>
      kw.replace(unitPattern, '').replace(/[^a-zA-Z\s]/g, '').trim()
    ).filter(Boolean);

    const regexQueries = cleanedKeywords.map(kw => ({
      ingredients: { $elemMatch: { $regex: kw, $options: 'i' } },
    }));

    const recipes = await Recipe.find({ $or: regexQueries });

    res.status(200).json(recipes);
  } catch (err) {
    console.error('🔴 Ingredient search error:', err);
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

exports.deleteRecipe = async (req, res) => {
  try {
    const { id } = req.params;
    await Recipe.findByIdAndDelete(id);
    res.status(200).json({ message: 'Recipe deleted' });
  } catch (err) {
    res.status(500).json({ error: 'Failed to delete recipe' });
  }
};

exports.rateRecipe = async (req, res) => {
  try {
    const { id } = req.params;
    const { rating } = req.body;

    if (typeof rating !== 'number' || rating < 1 || rating > 5) {
      return res.status(400).json({ message: 'Invalid rating value' });
    }

    const recipe = await Recipe.findById(id);
    if (!recipe) return res.status(404).json({ message: 'Recipe not found' });

    recipe.ratings.push(rating);
    await recipe.save();

    res.status(200).json({ message: 'Rating added', recipe });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error });
  }
};

exports.getPopularRecipes = async (req, res) => {
  try {
    const recipes = await Recipe.find({ isPublic: true }).sort({ averageRating: -1 }).limit(4);
    res.status(200).json(recipes);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

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

exports.searchRecipes = async (req, res) => {
  try {
    const { query } = req.query;
    const regex = new RegExp(query, 'i');
    const recipes = await Recipe.find({
      $or: [{ title: regex }, { description: regex }, { ingredients: regex }],
    });
    res.status(200).json(recipes);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

exports.toggleLike = async (req, res) => {
  const { userId } = req.body;
  const recipeId = req.params.id;

  try {
    const recipe = await Recipe.findById(recipeId);
    if (!recipe) return res.status(404).json({ message: 'Recipe not found' });

    const alreadyLiked = recipe.likes.includes(userId);

    if (alreadyLiked) {
      recipe.likes = recipe.likes.filter(id => id.toString() !== userId);
    } else {
      recipe.likes.push(userId);
    }

    await recipe.save();

    res.status(200).json({
      message: alreadyLiked ? 'Unliked' : 'Liked',
      liked: !alreadyLiked,
      likesCount: recipe.likes.length,
      likes: recipe.likes,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Something went wrong' });
  }
};
exports.getAllRecipesAdmin = async (req, res) => {
  try {
    const recipes = await Recipe.find().populate('author', 'name avatar');
    res.json(recipes);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};
// controllers/recipeController.js
exports.getFullRecipeDetails = async (req, res) => {
  try {
    const recipe = await Recipe.findById(req.params.id)
      .populate('author', 'name avatar')
      .populate('likes', 'name avatar')
      .lean();

    if (!recipe) {
      return res.status(404).json({ message: 'Recipe not found' });
    }

    // remove fields
    delete recipe.createdAt;
    delete recipe.updatedAt;
    delete recipe.image;

    // Format ratings
    recipe.ratedBy = (recipe.ratings || []).map(r =>
      typeof r === 'object' && r.user
        ? { user: r.user, value: r.value }
        : { user: null, value: r }
    );

    // 🆕 Fetch comments from Comment model
    const comments = await Comment.find({ recipeId: req.params.id })
      .populate('userId', 'name avatar')
      .lean();

    // Attach nicely to the recipe object
    recipe.comments = comments.map(c => ({
      user: c.userId,
      text: c.content,
      createdAt: c.createdAt
    }));

    res.json(recipe);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
// controllers/recipeController.js
exports.deleteReciperoot = async (req, res) => {
  try {
    await Recipe.findByIdAndDelete(req.params.id);
    res.json({ message: 'Recipe deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Get number of recipes created by a specific user
exports.getRecipeCountByUser = async (req, res) => {
  try {
    const count = await Recipe.countDocuments({ author: req.params.userId });
    res.json({ count });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
exports.adminCreateRecipe = async (req, res) => {
  try {
    const {
      title,
      titleAr,
      description,
      descriptionAr,
      ingredients,
      ingredientsAr,
      instructions,
      instructionsAr,
      image,
      calories,
      diet,
      mealTime,
      prepTime,
      difficulty,
      tags,
    } = req.body;

    const safeIngredients = Array.isArray(ingredients)
      ? ingredients
      : typeof ingredients === 'string'
        ? ingredients.split(',').map(i => i.trim())
        : [];

    const safeTags = Array.isArray(tags)
      ? tags
      : typeof tags === 'string' && tags.trim() !== ''
        ? [tags.trim()]
        : [];

    const newRecipe = await Recipe.create({
      title,
      titleAr,
      description,
      descriptionAr,
      ingredients: safeIngredients,
      ingredientsAr,
      instructions,
      instructionsAr,
      image,
      calories,
      diet,
      mealTime,
      prepTime,
      difficulty,
      tags: safeTags,
      isPublic: true,  // ✅ Always public
    });

    res.status(201).json(newRecipe);
  } catch (err) {
    console.error('❌ Admin recipe error:', err);
    res.status(500).json({ message: 'Error creating admin recipe', error: err.message });
  }
};


