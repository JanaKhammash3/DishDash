// models/Challenge.js
const mongoose = require('mongoose');

const challengeSchema = new mongoose.Schema({
    title: { type: String, required: true },
    description: String,
    startDate: Date,
    endDate: Date,
    participants: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
    topRecipes: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Recipe' }]
  });
  
  module.exports = mongoose.model('Challenge', challengeSchema);