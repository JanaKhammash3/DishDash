// models/Recipe.js
const mongoose = require('mongoose');

const recipeSchema = new mongoose.Schema({
    title: { type: String, required: true },
    description: String,
    ingredients: [String],
    instructions: [String],
    imageUrl: String,
    createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    isPublic: { type: Boolean, default: true },
    folder: String,
    nutrition: {
      calories: Number,
      protein: Number,
      carbs: Number,
      fat: Number
    },
    ratings: [
      {
        userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
        value: Number
      }
    ]
  });
  
  module.exports = mongoose.model('Recipe', recipeSchema);
  