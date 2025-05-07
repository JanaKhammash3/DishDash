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
  toggleFollow
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

module.exports = router;
