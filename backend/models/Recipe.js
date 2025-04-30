const mongoose = require('mongoose');

const recipeSchema = new mongoose.Schema({
  title: { type: String, required: true },
  description: String,
  ingredients: [String],
  instructions: String,
  image: String, // can be a URL or base64 (if used)
  calories: Number, // ✅ for calorie filtering
  type: String,     // e.g., 'Vegan', 'Dessert', etc.
  mealTime: String, // e.g., 'Breakfast', 'Dinner', etc.
  ratings: [Number], 
}, { timestamps: true });

recipeSchema.virtual('averageRating').get(function () {
  if (this.ratings.length === 0) return 0;
  const sum = this.ratings.reduce((acc, r) => acc + r.value, 0);
  return sum / this.ratings.length;
});

module.exports = mongoose.model('Recipe', recipeSchema);
