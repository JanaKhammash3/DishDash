const { OpenAI } = require('openai');

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY, // Store this in your .env file
});

exports.generateAIRecipe = async (req, res) => {
  const {
    mealTime,
    preferredIngredients,
    avoidIngredients,
    cuisine,
    diet,
    allergies,
    prepTime,
    calories
  } = req.body;

  try {
    const prompt = `
Create a personalized ${diet} ${mealTime} recipe.
Use ingredients: ${preferredIngredients.join(', ') || 'any available'}.
Avoid ingredients: ${avoidIngredients.join(', ') || 'none'}.
Cuisine style: ${cuisine || 'any'}.
Allergies to avoid: ${allergies.join(', ') || 'none'}.
Prep time under ${prepTime || 30} minutes.
Calories around ${calories || 500}.

Return the response in this JSON format:
{
  "title": "...",
  "description": "...",
  "ingredients": ["...", "..."],
  "instructions": ["Step 1...", "Step 2..."],
  "calories": number
}
`;

    const completion = await openai.chat.completions.create({
      model: 'gpt-4', // or 'gpt-3.5-turbo'
      messages: [{ role: 'user', content: prompt }],
      temperature: 0.8,
    });

    const content = completion.choices[0].message.content;

    // Try parsing the JSON safely
    let recipe;
    try {
      recipe = JSON.parse(content);
    } catch (err) {
      return res.status(500).json({ error: 'Invalid response format from AI.' });
    }

    res.json(recipe);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to generate recipe.' });
  }
};
