const express = require('express');
const router = express.Router();
const { generateAIRecipe } = require('../controllers/aiController');

router.post('/generate-recipe', generateAIRecipe);

module.exports = router;