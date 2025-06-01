const { OpenAI } = require('openai');
require('dotenv').config();

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

// Extract JSON block from GPT
function extractJSONFromText(text) {
  const match = text.match(/```(?:json)?\s*([\s\S]*?)\s*```/);
  return match ? match[1].trim() : text.trim();
}

exports.generateAIRecipe = async (req, res) => {
  const {
    mealTime,
    preferredIngredients,
    avoidIngredients,
    cuisine,
    diet,
    allergies,
    prepTime,
    calories,
    servings,
  } = req.body;

  try {
    const formattedDiet = diet && diet.toLowerCase() !== 'none' ? `${diet} ` : '';
    const prompt = `
You are a recipe assistant. ONLY respond in raw JSON. DO NOT explain anything.

Generate a personalized ${formattedDiet}${mealTime} recipe for ${servings || 1} people.
Use ingredients: ${preferredIngredients.join(', ') || 'any'}.
Avoid these ingredients strictly: ${avoidIngredients.join(', ') || 'none'}. do not include them in the recipe.
Cuisine: ${cuisine || 'any'}.
Avoid these allergies strictly: ${allergies.join(', ') || 'none'}. Do not include them in any form.
Prep time: under ${prepTime || 30} minutes.
Calories: around ${calories || 500}.

Respond ONLY in this exact format (no intro or explanation):

{
  "title": "...",
  "description": "...",
  "ingredients": ["..."],
  "instructions": ["..."],
  "calories": number,
  "servings": number
}
`;

    const chatResponse = await openai.chat.completions.create({
      model: 'gpt-3.5-turbo',
      messages: [{ role: 'user', content: prompt }],
      temperature: 0.8,
    });

    const raw = chatResponse.choices[0].message.content;
    const cleaned = extractJSONFromText(raw);

    let recipe;
    try {
      recipe = JSON.parse(cleaned);
    } catch (err) {
      console.error('❌ JSON parse failed:', cleaned);
      return res.status(500).json({ error: 'Invalid response format from AI.' });
    }

    // 🖼️ Generate image using DALL·E 2
    const imagePrompt = `A high-quality photo of a cooked ${recipe.title}, served on a plate, food photography`;
    const imageResponse = await openai.images.generate({
      prompt: imagePrompt,
      n: 1,
      size: '512x512',
      response_format: 'b64_json',
    });

    recipe.image = imageResponse.data[0].b64_json;

    res.json(recipe);
  } catch (err) {
    console.error('❌ Error:', err.message);
    res.status(500).json({ error: 'Failed to generate recipe or image.' });
  }
};





exports.imageToRecipe = async (req, res) => {
  const { image } = req.body;

  if (!image) {
    return res.status(400).json({ error: 'Image is required as base64' });
  }

  try {
    const response = await openai.chat.completions.create({
      model: "gpt-4o",
      messages: [
        {
          role: "user",
          content: [
            {
              type: "text",
              text:
                "Analyze this food image and generate a recipe including: title, description, ingredients, instructions, calories. Return ONLY JSON with this format:\n\n" +
                `{
  "title": "...",
  "description": "...",
  "ingredients": ["..."],
  "instructions": ["..."],
  "calories": number
}`
            },
            {
              type: "image_url",
              image_url: {
                url: `data:image/jpeg;base64,${image}`,
              },
            },
          ],
        },
      ],
      max_tokens: 1000,
    });
    const raw = response.choices[0].message.content;
    console.log('🧠 Vision AI Raw Response:', raw);
    
    let cleaned = raw.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.replace(/```json|```/g, '').trim();
    }
    
    let recipe;
    try {
      recipe = JSON.parse(cleaned);
    } catch (e) {
      console.error('❌ Parse failed:', cleaned);
      return res.status(500).json({ error: 'Failed to parse recipe. AI response may not be in proper format.', raw });
    }

    // Attach the original image for frontend preview
    recipe.image = image;

    res.json(recipe);
  } catch (err) {
    console.error("❌ Error generating recipe from image:", err.message);
    res.status(500).json({ error: 'Failed to generate recipe from image.' });
  }
};
exports.instructionsToSteps = async (req, res) => {
  const { instructions } = req.body;

  try {
    const prompt = `Break down the following recipe instructions into clear step-by-step cooking steps:\n\n${instructions}\n\nReturn them as a numbered list.`;

    const completion = await openai.chat.completions.create({  // ✅ CORRECT
      model: "gpt-4",
      messages: [{ role: "user", content: prompt }],
    });

    const content = completion.choices[0].message.content;

    const steps = content
      .split(/\n+/)
      .map(s => s.replace(/^\d+\.\s*/, "").trim())
      .filter(Boolean);

    res.json({ steps });
  } catch (err) {
    console.error("❌ Error processing steps:", err);
    res.status(500).json({ message: "Failed to process steps", error: err.message });
  }
};
exports.generateFromAvailableIngredients = async (req, res) => {
  const { availableIngredients, mealTime = 'Lunch', servings = 1 } = req.body;

  if (!availableIngredients || availableIngredients.length === 0) {
    return res.status(400).json({ error: 'availableIngredients is required' });
  }

  try {
    const prompt = `
You are a recipe assistant. ONLY respond in raw JSON. DO NOT explain anything.

Create a ${mealTime.toLowerCase()} recipe using ONLY the following available ingredients: ${availableIngredients.join(', ')}.
Do NOT use any ingredient that is not in the list above.
Make it suitable for ${servings} people.

Choose an appropriate diet (e.g., Vegetarian, Vegan, Keto, None), estimate preparation time in minutes, and provide calorie count.

Respond ONLY in this exact JSON format:

{
  "title": "...",
  "description": "...",
  "ingredients": ["..."],
  "instructions": ["..."],
  "calories": number,
  "prepTime": number,
  "diet": "None" | "Vegan" | "Vegetarian" | "Keto" | "Gluten-Free",
  "mealTime": "${mealTime}",
  "servings": number
}
`;

    const chatResponse = await openai.chat.completions.create({
      model: 'gpt-4',
      messages: [{ role: 'user', content: prompt }],
      temperature: 0.8,
    });

    const raw = chatResponse.choices[0].message.content;
    const cleaned = raw.trim().replace(/```json|```/g, '');

    let recipe;
    try {
      recipe = JSON.parse(cleaned);
    } catch (err) {
      console.error('❌ JSON parse failed:', cleaned);
      return res.status(500).json({ error: 'Invalid AI response', raw });
    }

    // 🖼️ Generate image using DALL·E 2
    const imagePrompt = `A high-quality photo of a cooked ${recipe.title}, made using only: ${availableIngredients.join(', ')}, served on a plate.`;
    const imageResponse = await openai.images.generate({
      prompt: imagePrompt,
      n: 1,
      size: '512x512',
      response_format: 'b64_json',
    });

    recipe.image = imageResponse.data[0].b64_json;
    recipe.diet ??= 'None';
    recipe.prepTime ??= 30;
    recipe.mealTime ??= mealTime;
    res.json(recipe);
  } catch (err) {
    console.error('❌ Error:', err.message);
    res.status(500).json({ error: 'Failed to generate recipe from available ingredients' });
  }
};

