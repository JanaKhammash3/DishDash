const mongoose = require('mongoose');

const mealPlanSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  weekStartDate: Date,
  days: [
    {
      date: String, // 'YYYY-MM-DD'
      meals: [
        {
          recipe: { type: mongoose.Schema.Types.ObjectId, ref: 'Recipe' },
          done: { type: Boolean, default: false }
        }
      ]
    }
  ],
  groceryList: [String]
});

module.exports = mongoose.model('MealPlan', mealPlanSchema);
