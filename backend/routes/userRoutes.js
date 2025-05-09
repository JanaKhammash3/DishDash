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
  getRecommendations
} = require('../controllers/userController');

// Auth & profile
router.post('/register', register);
router.post('/login', login);
router.get('/profile/:id', getUserProfile);
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
router.get('/followers/:userId', async (req, res) => {
  try {
    const userId = req.params.userId;
    const allUsers = await User.find({ following: userId });
    res.json({ followers: allUsers.length });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ✅ Grocery list
router.get('/:userId/grocery-list', getGroceryList);
router.post('/:userId/grocery-list', saveGroceryList);

module.exports = router;
router.get('/:id/followers/count', getFollowerCount);
router.get('/:id/recommendations', getRecommendations);


