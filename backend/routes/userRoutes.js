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
  updateCustomRecipe,
  getFollowingUsers,
  resetPasswordWithOtp,
  requestOtp
} = require('../controllers/userController');

// ✅ Auth & Profile
router.post('/register', register);
router.post('/login', login);
router.get('/profile/:id', getProfile);
router.put('/profile/:id', updateProfile);
router.put('/profile/:id/avatar', uploadAvatar);
router.patch('/updateAllergies/:id', updateAllergies);
router.put('/profile/:id/update', updateProfile);

// ✅ Recipes
router.post('/:userId/saveRecipe', saveRecipeToUser);
router.post('/:userId/unsaveRecipe', unsaveRecipe);
router.get('/:id/savedRecipes', getSavedRecipes);
router.post('/:userId/customRecipe', createCustomRecipe);
router.get('/:userId/myRecipes', getMyRecipes);
router.put('/recipes/:recipeId', updateCustomRecipe);

// ✅ Follow System
router.post('/toggleFollow', toggleFollow);
router.get('/:id/followers/count', getFollowerCount);
router.get('/followers/:userId', getFollowers);

// ✅ Grocery & Ingredients
router.get('/:userId/grocery-list', getGroceryList);
router.put('/:userId/grocery-list', saveGroceryList);
router.get('/:userId/available-ingredients', getAvailableIngredients);
router.put('/:userId/available-ingredients', updateAvailableIngredients);

// ✅ Survey & Recommendations
router.put('/:id/survey', updateSurvey);
router.get('/:id/recommendations', getRecommendations);

// ✅ Scraping
router.post('/:userId/scrape-pin', scrapeAndSaveRecipe);

// ✅ Users management
router.get('/', async (req, res) => {
  const User = require('../models/User');
  try {
    const users = await User.find();
    res.status(200).json(users);
  } catch (err) {
    res.status(500).json({ message: 'Failed to fetch users', error: err.message });
  }
});
router.delete('/:id', deleteUser);
router.get('/:id/following', getFollowingUsers);
router.post('/request-otp', requestOtp);
router.post('/reset-password', resetPasswordWithOtp);

// ✅ Export the router
module.exports = router;
