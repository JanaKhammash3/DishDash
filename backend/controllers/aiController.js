const { OpenAI } = require('openai');

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
    const prompt = `
You are a recipe assistant. ONLY respond in raw JSON. DO NOT explain anything.

Generate a personalized ${diet} ${mealTime} recipe for ${servings || 1} people.
Use ingredients: ${preferredIngredients.join(', ') || 'any'}.
Avoid ingredients: ${avoidIngredients.join(', ') || 'none'}.
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
