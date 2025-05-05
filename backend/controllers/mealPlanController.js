const MealPlan = require('../models/MealPlan');
const Recipe = require('../models/Recipe'); 

exports.createMealPlan = async (req, res) => {
  try {
    const plan = await MealPlan.create(req.body);
    res.status(201).json(plan);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};
exports.markMealAsDone = async (req, res) => {
  const { planId, date, recipeId } = req.body;
  try {
    const plan = await MealPlan.findById(planId);
    const day = plan.days.find(d => d.date === date);
    if (day) {
      const meal = day.meals.find(m => m.recipe.toString() === recipeId);
      if (meal) {
        meal.done = true;
      }
    }
    await plan.save();
    res.status(200).json(plan);
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
      day.meals.push({ recipe: recipeId, done: false });
    } else {
      plan.days.push({ date, meals: [{ recipe: recipeId, done: false }] });
    }

    await plan.save();
    res.status(200).json(plan);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

exports.getWeeklyCalories = async (req, res) => {
  try {
    const { userId } = req.params;
    const today = new Date();
    const startOfWeek = new Date(today);
    startOfWeek.setDate(today.getDate() - today.getDay()); // Sunday

    // Get plans as plain JS objects
    const plans = await MealPlan.find({ userId }).lean();

    // Fetch all recipe IDs in the week that are marked as done
    const recipeIdsToLoad = [];

    plans.forEach(plan => {
      plan.days.forEach(day => {
        const date = new Date(day.date);
        if (date >= startOfWeek && date <= today) {
          day.meals.forEach(meal => {
            if (meal.done && meal.recipe) {
              recipeIdsToLoad.push(meal.recipe.toString());
            }
          });
        }
      });
    });

    // Get recipe calorie values
    const recipes = await Recipe.find({ _id: { $in: recipeIdsToLoad } }).lean();
    const recipeMap = {};
    recipes.forEach(r => {
      recipeMap[r._id.toString()] = r.calories || 0;
    });

    let totalCalories = 0;
    const dailyCalories = Array(7).fill(0);

    plans.forEach(plan => {
      plan.days.forEach(day => {
        const date = new Date(day.date);
        if (date >= startOfWeek && date <= today) {
          const dayIndex = date.getDay();
          day.meals.forEach(meal => {
            if (meal.done) {
              const kcal = recipeMap[meal.recipe?.toString()] || 0;
              dailyCalories[dayIndex] += kcal;
              totalCalories += kcal;
            }
          });
        }
      });
    });

    return res.json({ totalCalories, dailyCalories });
  } catch (err) {
    console.error(err);
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
exports.getMealPlanByUser = async (req, res) => {
  try {
    const plans = await MealPlan.find({ userId: req.params.userId });
    res.status(200).json(plans);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};
