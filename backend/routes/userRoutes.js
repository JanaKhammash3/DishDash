// routes/userRoutes.js
const express = require('express');
const router = express.Router();
const { register, login, updateProfile, getUserProfile } = require('../controllers/userController');

router.post('/register', register);
router.post('/login', login);
router.put('/profile/:id', updateProfile);
router.get('/profile/:id', getUserProfile);

module.exports = router;