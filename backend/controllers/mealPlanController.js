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

exports.markMealAsUndone = async (req, res) => {
  const { planId, date, recipeId } = req.body;
  try {
    const plan = await MealPlan.findById(planId);
    if (!plan) return res.status(404).json({ message: 'Meal plan not found' });

    const day = plan.days.find(d => d.date === date);
    if (!day) return res.status(404).json({ message: 'Date not found in plan' });

    const meal = day.meals.find(m => m.recipe.toString() === recipeId);
    if (!meal) return res.status(404).json({ message: 'Meal not found for this date' });

    meal.done = false;
    await plan.save();
    res.status(200).json({ message: 'Meal marked as undone', plan });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};


exports.addRecipeToPlan = async (req, res) => {
  const { planId } = req.params;
  const { date, recipeId } = req.body;

  try {
    const plan = await MealPlan.findById(planId);
    const recipe = await Recipe.findById(recipeId);
    if (!plan || !recipe) {
      return res.status(404).json({ message: 'Plan or Recipe not found' });
    }

    const day = plan.days.find(d => d.date === date);

    // 🔁 Prevent duplicates
    if (day) {
      const alreadyExists = day.meals.some(
        m => m.recipe.toString() === recipeId
      );
      if (alreadyExists) {
        return res.status(409).json({ message: 'Recipe already exists for this day' });
      }
      day.meals.push({ recipe: recipeId, done: false });
    } else {
      plan.days.push({ date, meals: [{ recipe: recipeId, done: false }] });
    }

    // ✅ Add ingredients to groceryList
    const ingredientsToAdd = recipe.ingredients || [];
    if (!Array.isArray(plan.groceryList)) plan.groceryList = [];
    ingredientsToAdd.forEach(ing => {
      if (!plan.groceryList.includes(ing)) {
        plan.groceryList.push(ing);
      }
    });

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
    today.setHours(23, 59, 59, 999); // End of today

    const startOfWeek = new Date(today);
    startOfWeek.setDate(today.getDate() - today.getDay()); // Sunday
    startOfWeek.setHours(0, 0, 0, 0); // Start of Sunday

    const plans = await MealPlan.find({ userId }).lean();

    const recipeIdsToLoad = [];

    // Collect recipes from 'done' meals within the current week
    plans.forEach(plan => {
      plan.days.forEach(day => {
        if (!day.date) return;

        const [year, month, dayNum] = day.date.split('-').map(Number);
        const parsedDate = new Date(year, month - 1, dayNum); // normalize
        parsedDate.setHours(0, 0, 0, 0);

        if (parsedDate >= startOfWeek && parsedDate <= today) {
          day.meals.forEach(meal => {
            if (meal.done && meal.recipe) {
              recipeIdsToLoad.push(meal.recipe.toString());
            }
          });
        }
      });
    });

    const recipes = await Recipe.find({ _id: { $in: recipeIdsToLoad } }).lean();
    const recipeMap = {};
    recipes.forEach(r => {
      recipeMap[r._id.toString()] = r.calories || 0;
    });

    let totalCalories = 0;
    const dailyCalories = Array(7).fill(0); // Sunday to Saturday

    plans.forEach(plan => {
      plan.days.forEach(day => {
        if (!day.date) return;

        const [year, month, dayNum] = day.date.split('-').map(Number);
        const parsedDate = new Date(year, month - 1, dayNum);
        parsedDate.setHours(0, 0, 0, 0);

        if (parsedDate >= startOfWeek && parsedDate <= today) {
          const dayIndex = parsedDate.getDay();

          day.meals.forEach(meal => {
            if (meal.done) {
              const kcal = recipeMap[meal.recipe?.toString()] || 0;
              dailyCalories[dayIndex] += kcal;
              totalCalories += kcal;
              console.log(`✅ ${kcal} kcal added for recipe ${meal.recipe}`);
            }
          });
        }
      });
    });

    console.log('📊 Final totalCalories:', totalCalories);
    console.log('📆 dailyCalories:', dailyCalories);

    return res.json({ totalCalories, dailyCalories });

  } catch (err) {
    console.error('❌ Error in getWeeklyCalories:', err);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};


exports.getGroceryList = async (req, res) => {
  try {
    const plan = await MealPlan.findById(req.params.planId);
    res.status(200).json(plan.groceryList || []);
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

// controllers/mealPlanController.js
exports.removeRecipeFromPlan = async (req, res) => {
  const { planId } = req.params;
  const { date, recipeId } = req.body;

  try {
    const plan = await MealPlan.findById(planId);
    if (!plan) return res.status(404).json({ message: 'Plan not found' });

    const day = plan.days.find(d => d.date === date);
    if (!day) return res.status(404).json({ message: 'Date not found in plan' });

    day.meals = day.meals.filter(m => m.recipe.toString() !== recipeId);

    // Update grocery list
    const allRecipeIds = plan.days.flatMap(d => d.meals.map(m => m.recipe.toString()));
    const remainingRecipes = await Recipe.find({ _id: { $in: allRecipeIds } });
    const remainingIngredients = new Set(
      remainingRecipes.flatMap(r => r.ingredients)
    );
    plan.groceryList = plan.groceryList.filter(ing => remainingIngredients.has(ing));

    await plan.save();
    res.status(200).json(plan);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};


