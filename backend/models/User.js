// models/User.js
const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  avatar: { type: String, default: '' }, // User's profile picture URL
  location: {
    latitude: { type: Number },
    longitude: { type: Number }
  },
  allergies: [{ type: String }],
  calorieScore: { type: Number, default: 0 },
  following: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  recipes: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Recipe' }],
  savedPlans: [{ type: mongoose.Schema.Types.ObjectId, ref: 'MealPlan' }],
  currentGroceryList: [{ type: String }],
  role: { type: String, enum: ['user', 'admin'], default: 'user' }
});

module.exports = mongoose.model('User', userSchema);
