const express = require('express');
const axios = require('axios');
const router = express.Router();

const EDAMAM_APP_ID = '27461690';
const EDAMAM_APP_KEY = '47c77a3fdf7db641eff66d1597509d00';

// Helper to safely sum nutrients
function getTotal(ingredients, key) {
  return ingredients.reduce((sum, item) => {
    const parsed = item.parsed?.[0];
    const value = parsed?.nutrients?.[key]?.quantity || 0;
    return sum + value;
  }, 0);
}

// ✅ POST /api/analyze-nutrition
router.post('/analyze-nutrition', async (req, res) => {
  const { title, ingredients } = req.body;

  if (!Array.isArray(ingredients) || ingredients.length === 0) {
    return res.status(400).json({ message: 'Ingredients list is required' });
  }

  try {
    const response = await axios.post(
      `https://api.edamam.com/api/nutrition-details?app_id=${EDAMAM_APP_ID}&app_key=${EDAMAM_APP_KEY}`,
      { title, ingr: ingredients },
      { headers: { 'Content-Type': 'application/json' } }
    );

    const data = response.data;

    const calories = getTotal(data.ingredients, 'ENERC_KCAL');
    const protein = getTotal(data.ingredients, 'PROCNT');
    const fat = getTotal(data.ingredients, 'FAT');
    const carbs = getTotal(data.ingredients, 'CHOCDF');

    res.status(200).json({
      calories: Math.round(calories),
      protein: Math.round(protein),
      fat: Math.round(fat),
      carbs: Math.round(carbs),
      unit: 'g'
    });
  } catch (err) {
    console.error('❌ Edamam error:', err.response?.data || err.message);
    res.status(500).json({
      message: 'Failed to analyze nutrition',
      error: err.response?.data || err.message
    });
  }
});

module.exports = router;
