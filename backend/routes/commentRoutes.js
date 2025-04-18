const express = require('express');
const router = express.Router();
const { addComment, getCommentsByRecipe } = require('../controllers/commentController');

router.post('/:recipeId', addComment);
router.get('/:recipeId', getCommentsByRecipe);

module.exports = router;
