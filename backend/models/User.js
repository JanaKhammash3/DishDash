// models/User.js
const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  allergies: [{ type: String }], // user can write multiple allergy strings
  calorieScore: { type: Number, default: 0 },
  following: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  recipes: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Recipe' }],
  savedPlans: [{ type: mongoose.Schema.Types.ObjectId, ref: 'MealPlan' }]
});

module.exports = mongoose.model('User', userSchema);