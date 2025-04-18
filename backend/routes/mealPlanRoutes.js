// routes/mealPlanRoutes.js
const express = require('express');
const router = express.Router();
const { createMealPlan, addRecipeToPlan, getMealPlanByUser, getGroceryList } = require('../controllers/mealPlanController');

router.post('/', createMealPlan);
router.put('/:planId/add-recipe', addRecipeToPlan);
router.get('/user/:userId', getMealPlanByUser);
router.get('/:planId/grocery-list', getGroceryList);

module.exports = router;