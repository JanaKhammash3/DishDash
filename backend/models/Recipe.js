const mongoose = require('mongoose');

const recipeSchema = new mongoose.Schema({
  title: { type: String, required: true },               // ✅ Keep English as-is
  titleAr: { type: String },                             // ➕ Arabic title

  description: String,                                   // ✅ Existing English
  descriptionAr: String,                                 // ➕ Arabic description

  ingredients: [String],                                 // ✅ English ingredients
  ingredientsAr: [String],                               // ➕ Arabic ingredients

  instructions: String,                                  // ✅ English
  instructionsAr: String,  
  image: String,
  calories: Number,

  diet: {
    type: String,
    enum: ['Vegan', 'Keto', 'Low-Carb', 'Paleo', 'Vegetarian', 'None'],
  },
  mealTime: {
    type: String,
    enum: ['Breakfast', 'Lunch', 'Dinner', 'Snack', 'Dessert'],
  },

  prepTime: Number, // in minutes

  difficulty: {
    type: String,
    enum: ['Easy', 'Medium', 'Hard'],
    default: 'Easy',
  },

  tags: [String],
  ratings: {
    type: [Number],
    default: [],
  },
  likes: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  author: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  isPublic: {
    type: Boolean,
    default: true,
  }
}, { timestamps: true });

recipeSchema.virtual('averageRating').get(function () {
  if (this.ratings.length === 0) return 0;
  const sum = this.ratings.reduce((acc, r) => acc + r, 0);
  return sum / this.ratings.length;
});

module.exports = mongoose.model('Recipe', recipeSchema);
