// routes/mealPlanRoutes.js
const express = require('express');
const router = express.Router();
const { createMealPlan, addRecipeToPlan, getMealPlanByUser, getGroceryList, getWeeklyCalories, markMealAsDone} = require('../controllers/mealPlanController');

router.post('/', createMealPlan);
router.put('/:planId/add-recipe', addRecipeToPlan);
router.get('/user/:userId', getMealPlanByUser);
router.get('/:planId/grocery-list', getGroceryList);
router.get('/weekly-calories/:userId', getWeeklyCalories);
router.put('/mark-done', markMealAsDone);

module.exports = router;