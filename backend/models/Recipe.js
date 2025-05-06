const mongoose = require('mongoose');

const recipeSchema = new mongoose.Schema({
  title: { type: String, required: true },
  description: String,
  ingredients: [String],
  instructions: String,
  image: String, // URL or base64 string
  calories: Number,

  diet: {
    type: String,
    enum: ['Vegan', 'Keto', 'Low-Carb', 'Paleo', 'Vegetarian', 'None'],
  },      
  mealTime: {
    type: String,
    enum: ['Breakfast', 'Lunch', 'Dinner', 'Snack', 'Dessert'],
  },  
  prepTime: Number,   // in minutes

  tags: [String],     // e.g., ['gluten-free', 'spicy', 'lactose-free']

  ratings: {
    type: [Number],
    default: [],
  },
  likes: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  author: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
}, { timestamps: true });

// ✅ Fix average rating logic
recipeSchema.virtual('averageRating').get(function () {
  if (this.ratings.length === 0) return 0;
  const sum = this.ratings.reduce((acc, r) => acc + r, 0);
  return sum / this.ratings.length;
});

module.exports = mongoose.model('Recipe', recipeSchema);
