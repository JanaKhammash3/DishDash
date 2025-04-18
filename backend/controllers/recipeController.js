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
    const { userId, value } = req.body;
    const recipe = await Recipe.findById(req.params.id);
    recipe.ratings.push({ userId, value });
    await recipe.save();
    res.status(200).json(recipe);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};
