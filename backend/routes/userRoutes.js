const express = require('express');
const router = express.Router();
const {
  register,
  login,
  updateProfile,
  getUserProfile,
  updateAllergies,
  uploadAvatar,
  saveRecipeToUser,
  unsaveRecipe,
  getSavedRecipes,
  createCustomRecipe,
  getMyRecipes,
  toggleFollow,
  getFollowerCount,
  getGroceryList,
  saveGroceryList,
  getRecommendations,
  updateSurvey,
   getAvailableIngredients,
  updateAvailableIngredients,
  getProfile,
  getFollowers,
  deleteUser,
  scrapeAndSaveRecipe,
  updateCustomRecipe
} = require('../controllers/userController');

// Auth & profile
router.post('/register', register);
router.post('/login', login);
router.get('/profile/:id', getProfile);
router.put('/profile/:id', updateProfile);
router.patch('/updateAllergies/:id', updateAllergies);
router.put('/profile/:id/avatar', uploadAvatar);

// Recipe-related
router.post('/:userId/saveRecipe', saveRecipeToUser);
router.post('/:userId/unsaveRecipe', unsaveRecipe);
router.get('/:id/savedRecipes', getSavedRecipes);
router.post('/:userId/customRecipe', createCustomRecipe);
router.get('/:userId/myRecipes', getMyRecipes);

// Follow system
router.post('/toggleFollow', toggleFollow);
router.get('/:id/followers/count', getFollowerCount);
router.get('/followers/:userId', getFollowers);

// ✅ Grocery list
router.get('/:userId/grocery-list', getGroceryList);
router.post('/:userId/grocery-list', saveGroceryList);
// ✅ Available Ingredients Routes
router.get('/:userId/available-ingredients', getAvailableIngredients);
router.put('/:userId/available-ingredients', updateAvailableIngredients);


module.exports = router;
router.get('/:id/followers/count', getFollowerCount);
router.get('/:id/recommendations', getRecommendations);
router.put('/users/:id/survey', updateSurvey);
const User = require('../models/User'); // ✅ Required for GET /

router.get('/', async (req, res) => {
  try {
    const users = await User.find();
    res.status(200).json(users);
  } catch (err) {
    res.status(500).json({ message: 'Failed to fetch users', error: err.message });
  }
});
router.delete('/:id', deleteUser);
router.post('/users/:userId/scrape-pin', scrapeAndSaveRecipe);
router.put('/recipes/:recipeId', updateCustomRecipe);






