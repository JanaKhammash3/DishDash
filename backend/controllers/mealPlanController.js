const MealPlan = require('../models/MealPlan');

exports.createMealPlan = async (req, res) => {
  try {
    const plan = await MealPlan.create(req.body);
    res.status(201).json(plan);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

exports.addRecipeToPlan = async (req, res) => {
  const { planId } = req.params;
  const { date, recipeId } = req.body;
  try {
    const plan = await MealPlan.findById(planId);
    const day = plan.days.find(d => d.date === date);
    if (day) {
      day.meals.push(recipeId);
    } else {
      plan.days.push({ date, meals: [recipeId] });
    }
    await plan.save();
    res.status(200).json(plan);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

exports.getMealPlanByUser = async (req, res) => {
  try {
    const plans = await MealPlan.find({ userId: req.params.userId });
    res.status(200).json(plans);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

exports.getGroceryList = async (req, res) => {
  try {
    const plan = await MealPlan.findById(req.params.planId).populate('days.meals');
    const ingredients = new Set();
    plan.days.forEach(day => {
      day.meals.forEach(recipe => {
        recipe.ingredients.forEach(ing => ingredients.add(ing));
      });
    });
    res.status(200).json([...ingredients]);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};
