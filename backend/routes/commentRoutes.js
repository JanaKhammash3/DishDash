const express = require('express');
const router = express.Router();
const { addComment, getCommentsByRecipe, deleteComment } = require('../controllers/commentController');

router.post('/:recipeId', addComment);
router.get('/:recipeId', getCommentsByRecipe);
router.delete('/:commentId', deleteComment);

module.exports = router;
