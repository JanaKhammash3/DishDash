const User = require('../models/User');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const Recipe = require('../models/Recipe');
const multer = require('multer');
const path = require('path');
const MealPlan = require('../models/MealPlan'); 
const mongoose = require('mongoose');


// Setup storage for Multer
const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, 'uploads/'), // Folder 'uploads'
  filename: (req, file, cb) => cb(null, `${req.params.id}_${Date.now()}${path.extname(file.originalname)}`),
});

const upload = multer({ storage });
// Register user
exports.register = async (req, res) => {
  const { name, email, password, location } = req.body;

  try {
    const exists = await User.findOne({ email });
    if (exists) return res.status(400).json({ message: 'Email already in use' });

    const hashed = await bcrypt.hash(password, 10);

    const newUser = await User.create({
      name,
      email,
      password: hashed,
      avatar: '',
      location: location || { latitude: null, longitude: null },
      allergies: [],
      calorieScore: 0,
      following: [],
      recipes: [],
      savedPlans: [],
      currentGroceryList: [],
      role: 'user'
    });

    res.status(201).json({ message: 'User created', userId: newUser._id });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

// Login user
exports.login = async (req, res) => {
  const { email, password } = req.body;

  try {
    const user = await User.findOne({ email });
    if (!user) return res.status(400).json({ message: 'Invalid credentials' });

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) return res.status(400).json({ message: 'Invalid credentials' });

    const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET, { expiresIn: '1d' });

    res.status(200).json({
      message: 'Login successful',
      token,
      user: {
        _id: user._id,
        name: user.name,
        email: user.email,
        avatar: user.avatar,
        location: user.location,
        allergies: user.allergies,
        calorieScore: user.calorieScore
      }
    });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

// Get full user profile (excluding password)
exports.getUserProfile = async (req, res) => {
  try {
    const user = await User.findById(req.params.id).select('-password');
    if (!user) return res.status(404).json({ message: 'User not found' });
    res.status(200).json(user);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

// Update full profile
exports.updateProfile = async (req, res) => {
  try {
    const updated = await User.findByIdAndUpdate(req.params.id, req.body, { new: true });
    res.status(200).json(updated);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

// Update allergies
exports.updateAllergies = async (req, res) => {
  try {
    const { id } = req.params;
    const { allergies } = req.body;
    await User.findByIdAndUpdate(id, { allergies });
    res.status(200).json({ message: 'Allergies updated' });
  } catch (err) {
    res.status(500).json({ message: 'Failed to update allergies', error: err.message });
  }
};


// Controller for Upload Avatar (base64)
exports.uploadAvatar = async (req, res) => {
  try {
    const { avatar } = req.body;

    if (!avatar || typeof avatar !== 'string' || avatar.length < 50) {
      return res.status(400).json({ message: 'Invalid avatar data' });
    }

    const updatedUser = await User.findByIdAndUpdate(
      req.params.id,
      { avatar }, // saving base64 string
      { new: true }
    );

    if (!updatedUser) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.status(200).json(updatedUser);
  } catch (err) {
    console.error('Avatar Upload Error:', err.message);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};
exports.saveRecipeToUser = async (req, res) => {
  try {
    const { userId } = req.params;
    const { recipeId } = req.body;

    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ message: 'User not found' });

    if (user.recipes.includes(recipeId)) {
      return res.status(400).json({ message: 'Recipe already saved' });
    }

    user.recipes.push(recipeId);
    await user.save();

    res.status(200).json({ message: 'Recipe saved successfully' });
  } catch (err) {
    console.error('Error saving recipe:', err.message);
    res.status(500).json({ message: 'Internal server error' });
  }
};
exports.unsaveRecipe = async (req, res) => {
  try {
    const { userId } = req.params;
    const { recipeId } = req.body;

    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ error: 'User not found' });

    user.recipes = user.recipes.filter(
      id => id.toString() !== recipeId.toString()
    );

    await user.save();
    res.status(200).json({ message: 'Recipe removed from saved list' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};
exports.getSavedRecipes = async (req, res) => {
  const user = await User.findById(req.params.id).populate('recipes');
  res.json(user.recipes);
};
// POST /api/users/:userId/customRecipe
exports.createCustomRecipe = async (req, res) => {
  try {
    const userId = req.params.userId;

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
      tags
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
      description,
      ingredients: safeIngredients,
      instructions,
      image,
      calories,
      diet,
      mealTime,
      prepTime,
      tags: safeTags,
      author: userId  // ✅ this is now guaranteed
    });

    await User.findByIdAndUpdate(userId, {
      $push: {
        recipes: newRecipe._id,        // ✅ For My Recipes
        savedRecipes: newRecipe._id    // ✅ For Saved Recipes screen
      }
    });

    const populatedRecipe = await Recipe.findById(newRecipe._id).populate('author', 'name avatar');

    res.status(201).json(populatedRecipe);
  } catch (err) {
    console.error('❌ Custom recipe error:', err);
    res.status(500).json({ message: 'Error creating custom recipe', error: err.message });
  }
};



exports.getMyRecipes = async (req, res) => {
  try {
    const userId = req.params.userId;
    const recipes = await Recipe.find({ author: userId });
    res.status(200).json(recipes);
  } catch (err) {
    res.status(500).json({ message: 'Failed to fetch user recipes', error: err.message });
  }
};
// Toggle follow/unfollow
exports.toggleFollow = async (req, res) => {
  const { userId, targetUserId } = req.body;

  if (userId === targetUserId) {
    return res.status(400).json({ message: "Cannot follow yourself" });
  }

  const user = await User.findById(userId);
  const target = await User.findById(targetUserId);

  if (!user || !target) return res.status(404).json({ message: "User not found" });

  const isFollowing = user.following.includes(targetUserId);

  if (isFollowing) {
    user.following.pull(targetUserId);
  } else {
    user.following.push(targetUserId);
  }

  await user.save();

  const followers = await User.countDocuments({ following: targetUserId });

  res.json({
    following: user.following,
    isFollowing: !isFollowing,
    followers
  });
};
exports.getFollowerCount = async (req, res) => {
  try {
    const { id } = req.params; // id of profile being viewed
    const count = await User.countDocuments({ following: id }); // 🔥 correct query
    res.json({ count });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch follower count' });
  }
};


exports.getGroceryList = async (req, res) => {
  try {
    const user = await User.findById(req.params.userId);
    if (!user) return res.status(404).send('User not found');
    res.status(200).json(user.currentGroceryList || []);
  } catch (err) {
    console.error('❌ Error in getGroceryList:', err.message);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};


// POST grocery list
exports.saveGroceryList = async (req, res) => {
  try {
    const user = await User.findById(req.params.userId);
    if (!user) return res.status(404).send('User not found');
    user.currentGroceryList = req.body.ingredients;
    await user.save();
    res.status(200).json({ message: 'Grocery list updated' });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};
exports.updateSurvey = async (req, res) => {
  try {
    const userId = req.params.id;
    const { diet, preferredTags, preferredCuisines, weight, height } = req.body;

    // Calculate BMI and classify
    const heightInMeters = height / 100;
    const bmi = weight / (heightInMeters * heightInMeters);
    let bmiStatus = 'normal';
    if (bmi < 18.5) bmiStatus = 'underweight';
    else if (bmi >= 25) bmiStatus = 'overweight';

    const user = await User.findByIdAndUpdate(
      userId,
      {
        survey: {
          diet,
          preferredTags,
          preferredCuisines,
          weight,
          height,
          bmiStatus
        }
      },
      { new: true }
    );

    if (!user) return res.status(404).json({ message: 'User not found' });

    res.status(200).json({ message: 'Survey updated', survey: user.survey });
  } catch (err) {
    console.error('Error updating survey:', err);
    res.status(500).json({ message: 'Failed to update survey' });
  }
};


exports.getRecommendations = async (req, res) => {
  try {
    const userId = req.params.id;
    const user = await User.findById(userId).populate('recipes');
    if (!user) return res.status(404).json({ message: 'User not found' });

    // Determine current meal time
    const hour = new Date().getHours();
    let currentMeal = 'Breakfast';
    if (hour >= 11 && hour < 15) currentMeal = 'Lunch';
    else if (hour >= 15 && hour < 20) currentMeal = 'Dinner';
    else if (hour >= 20 || hour < 6) currentMeal = 'Snack';

    // Extract liked tags/ingredients from activity
    const likedTags = {};
    const likedIngredients = {};
    const extractFromRecipe = recipe => {
      if (!recipe) return;
      (recipe.tags || []).forEach(tag => {
        likedTags[tag] = (likedTags[tag] || 0) + 1;
      });
      (recipe.ingredients || []).forEach(ing => {
        likedIngredients[ing.toLowerCase()] = (likedIngredients[ing.toLowerCase()] || 0) + 1;
      });
    };

    // From saved recipes
    user.recipes.forEach(extractFromRecipe);

    // From liked recipes
    const likedRecipes = await Recipe.find({ likes: userId });
    likedRecipes.forEach(extractFromRecipe);

    // From meal plans
    const mealPlans = await MealPlan.find({ userId }).populate('days.meals.recipe');
    mealPlans.forEach(plan =>
      plan.days.forEach(day =>
        day.meals.forEach(meal => extractFromRecipe(meal.recipe))
      )
    );

    // Build search priorities
    const topTags = [...new Set([
      ...Object.keys(likedTags),
      ...(user.preferredTags || []),
      ...(user.preferredCuisines || [])
    ])];
    const topIngredients = Object.keys(likedIngredients);

    const excludedIds = [
      ...user.recipes.map(r => r._id.toString()),
      ...likedRecipes.map(r => r._id.toString())
    ];

    const baseConditions = {
      _id: { $nin: excludedIds },
      ingredients: { $nin: user.allergies || [] }
    };

    // Calorie logic based on BMI
    let calorieCondition = {};
    if (user.height && user.weight) {
      const heightM = user.height / 100;
      const bmi = user.weight / (heightM * heightM);
      if (bmi > 25) calorieCondition = { calories: { $lte: 400 } };
      else if (bmi < 18.5) calorieCondition = { calories: { $gte: 400 } };
    }

    // 🥗 Meal-time Recommendations (based on current time and diet)
    const mealTimeBased = await Recipe.find({
      ...baseConditions,
      mealTime: currentMeal,
      ...calorieCondition
    })
    .populate('author') 
    .limit(10);

    const mealTimeIds = mealTimeBased.map(r => r._id.toString());

    // 🌱 Survey-Based Recommendations
    const orConditions = [];
    if (topTags.length) orConditions.push({ tags: { $in: topTags } });
    if (topIngredients.length) orConditions.push({ ingredients: { $in: topIngredients } });
    if (user.diet && user.diet !== 'None') orConditions.push({ diet: user.diet });

    let surveyBased = [];

    if (orConditions.length > 0) {
      surveyBased = await Recipe.find({
        ...baseConditions,
        _id: { $nin: [...excludedIds, ...mealTimeIds] },
        $or: orConditions,
        ...calorieCondition
      })
      .populate('author') 
      .limit(10);
    } else {
      // fallback if survey data is missing
      surveyBased = await Recipe.find({
        ...baseConditions,
        _id: { $nin: [...excludedIds, ...mealTimeIds] },
        ...calorieCondition
      })
      .populate('author') 
      .limit(10);
    }

    res.json({
      mealTimeBased,
      surveyBased,
    });
  } catch (err) {
    console.error('Recommendation error:', err);
    res.status(500).json({ message: 'Recommendation failed' });
  }
};


// ✅ GET /api/users/:userId/available-ingredients
exports.getAvailableIngredients = async (req, res) => {
  try {
    const user = await User.findById(req.params.userId);
    if (!user) return res.status(404).json({ message: 'User not found' });
    res.status(200).json(user.availableIngredients || []);
  } catch (err) {
    console.error('Error fetching available ingredients:', err.message);
    res.status(500).json({ message: 'Failed to get available ingredients' });
  }
};

// ✅ PUT /api/users/:userId/available-ingredients
exports.updateAvailableIngredients = async (req, res) => {
  try {
    const { ingredients } = req.body;
    const user = await User.findByIdAndUpdate(
      req.params.userId,
      { availableIngredients: ingredients },
      { new: true }
    );
    if (!user) return res.status(404).json({ message: 'User not found' });
    res.status(200).json(user.availableIngredients);
  } catch (err) {
    console.error('Error updating available ingredients:', err.message);
    res.status(500).json({ message: 'Failed to update available ingredients' });
  }
};
exports.getProfile = async (req, res) => {
  try {
    const user = await User.findById(req.params.id) // ✅ FIXED
      .populate('following', 'name avatar')
      .lean();

    if (!user) return res.status(404).json({ message: 'User not found' });

    res.json(user);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
};