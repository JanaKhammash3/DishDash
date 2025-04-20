const express = require('express');
const router = express.Router();
const {
  register,
  login,
  updateProfile,
  getUserProfile,
  updateAllergies,
  uploadAvatar
} = require('../controllers/userController');

router.post('/register', register);
router.post('/login', login);
router.put('/profile/:id', updateProfile);
router.get('/profile/:id', getUserProfile);
router.put('/profile/:id/allergies', updateAllergies); // For allergy update
router.put('/profile/:id/avatar', uploadAvatar); // For Base64 avatar update

module.exports = router;
