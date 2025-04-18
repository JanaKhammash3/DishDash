const Comment = require('../models/Comment');

exports.addComment = async (req, res) => {
  try {
    const comment = await Comment.create({
      userId: req.body.userId,
      recipeId: req.params.recipeId,
      content: req.body.content
    });
    res.status(201).json(comment);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

exports.getCommentsByRecipe = async (req, res) => {
  try {
    const comments = await Comment.find({ recipeId: req.params.recipeId });
    res.status(200).json(comments);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};