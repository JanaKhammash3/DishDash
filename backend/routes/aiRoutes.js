const express = require('express');
const router = express.Router();
const { generateAIRecipe } = require('../controllers/aiController');
const { imageToRecipe } = require('../controllers/aiController');

router.post('/generate-recipe', generateAIRecipe);
router.post('/image-to-recipe', imageToRecipe);
module.exports = router;