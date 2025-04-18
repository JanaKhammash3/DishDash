
// models/Comment.js
const mongoose = require('mongoose');

const commentSchema = new mongoose.Schema({
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    recipeId: { type: mongoose.Schema.Types.ObjectId, ref: 'Recipe' },
    content: String,
    createdAt: { type: Date, default: Date.now }
  });
  
  module.exports = mongoose.model('Comment', commentSchema);