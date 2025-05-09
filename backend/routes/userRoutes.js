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
  getRecommendations
} = require('../controllers/userController');

router.post('/register', register);
router.post('/login', login);
router.get('/profile/:id', getUserProfile);
router.put('/profile/:id', updateProfile);
router.get('/profile/:id', getUserProfile);
router.patch('/updateAllergies/:id', updateAllergies);
router.put('/profile/:id/avatar', uploadAvatar); // For Base64 avatar update
router.post('/:userId/saveRecipe', saveRecipeToUser);
router.post('/:userId/unsaveRecipe', unsaveRecipe);
router.get('/:id/savedRecipes', getSavedRecipes);
router.post('/:userId/customRecipe', createCustomRecipe);
router.get('/:userId/myRecipes', getMyRecipes);
router.post('/toggleFollow', toggleFollow);
// routes/userRoutes.js
router.get('/followers/:userId', async (req, res) => {
  try {
    const userId = req.params.userId;
    const allUsers = await User.find({ following: userId });
    res.json({ followers: allUsers.length });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});
module.exports = router;
router.get('/:id/followers/count', getFollowerCount);
router.get('/:id/recommendations', getRecommendations);


