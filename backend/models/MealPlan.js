// models/MealPlan.js
const mongoose = require('mongoose');

const mealPlanSchema = new mongoose.Schema({
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    weekStartDate: Date,
    days: [
      {
        date: String,
        meals: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Recipe' }]
      }
    ],
    groceryList: [String]
  });
  
  module.exports = mongoose.model('MealPlan', mealPlanSchema);