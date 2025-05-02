const express = require('express');
const router = express.Router();
const {
  createRecipe,
  getAllRecipes,
  getRecipeById,
  searchByIngredients,
  rateRecipe,
  getPopularRecipes,
  getRecommendedRecipes,
  searchRecipes,
  filterRecipes
} = require('../controllers/recipeController');

router.post('/', createRecipe);
router.get('/', getAllRecipes);
router.get('/popular', getPopularRecipes);
router.get('/recommendations', getRecommendedRecipes);
router.get('/search', searchRecipes); // Search by query string
router.get('/search/:ingredients', searchByIngredients); // Search by ingredients
router.post('/filter', filterRecipes);
router.get('/:id', getRecipeById);
router.post('/:id/rate', rateRecipe);
router.patch('/rate/:id', rateRecipe);

module.exports = router;
