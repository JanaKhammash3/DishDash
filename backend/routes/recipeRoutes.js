const express = require('express');
const router = express.Router();
const {
  createCustomRecipe,
  getAllRecipes,
  getRecipeById,
  searchByIngredients,
  rateRecipe,
  getPopularRecipes,
  getRecommendedRecipes,
  searchRecipes,
  filterRecipes,
  deleteRecipe,
  toggleLike
} = require('../controllers/recipeController');

router.post('/', createCustomRecipe);
router.get('/popular', getPopularRecipes);
router.get('/recommendations', getRecommendedRecipes);
router.get('/search', searchRecipes);
router.get('/search/:ingredients', searchByIngredients);
router.get('/filter', filterRecipes);
router.get('/', getAllRecipes);
router.post('/:id/rate', rateRecipe);
router.patch('/rate/:id', rateRecipe);
router.delete('/:id', deleteRecipe);
router.post('/:id/like', toggleLike); 
router.get('/:id', getRecipeById);


module.exports = router;
