const express = require('express');
const router = express.Router();

const {
  createMealPlan,
  addRecipeToPlan,
  getMealPlanByUser,
  getGroceryList,
  getWeeklyCalories,
  markMealAsDone,
  removeRecipeFromPlan, // ✅ New import
} = require('../controllers/mealPlanController');

// 🗓️ Meal Plan creation
router.post('/', createMealPlan);

// ➕ Add a recipe to a meal plan
router.put('/:planId/add-recipe', addRecipeToPlan);

// ❌ Remove a recipe from a specific day in the meal plan
router.put('/:planId/remove-recipe', removeRecipeFromPlan); // ✅ Use correct path and handler

// 🔁 Mark a recipe as done
router.put('/mark-done', markMealAsDone);

// 📅 Get meal plans by user
router.get('/user/:userId', getMealPlanByUser);

// 🛒 Get grocery list by plan ID
router.get('/:planId/grocery-list', getGroceryList);

// 🔥 Weekly calorie summary
router.get('/weekly-calories/:userId', getWeeklyCalories);

module.exports = router;
