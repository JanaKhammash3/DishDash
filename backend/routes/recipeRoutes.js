const express = require('express');
const router = express.Router();
const { createRecipe, getAllRecipes, getRecipeById, searchByIngredients, rateRecipe } = require('../controllers/recipeController');

router.post('/', createRecipe);
router.get('/', getAllRecipes);
router.get('/:id', getRecipeById);
router.get('/search/:ingredients', searchByIngredients);
router.post('/:id/rate', rateRecipe);

module.exports = router;