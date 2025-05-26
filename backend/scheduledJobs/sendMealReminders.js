const cron = require('node-cron');
const MealPlan = require('../models/MealPlan');
const Notification = require('../models/Notification');
const Recipe = require('../models/Recipe');

function sendMealReminders() {
  cron.schedule('0 9 * * *', async () => {
    try {
      const tomorrow = new Date();
      tomorrow.setDate(tomorrow.getDate() + 1);
      //const today = new Date(); // 👈 today instead of tomorrow
      //const yyyyMMdd = today.toISOString().split('T')[0];
      const yyyyMMdd = tomorrow.toISOString().split('T')[0];
      const plans = await MealPlan.find({ 'days.date': yyyyMMdd }).populate('days.meals.recipe');

      for (const plan of plans) {
        const day = plan.days.find(d => d.date === yyyyMMdd);
        if (!day) continue;

        for (const meal of day.meals) {
          const recipe = meal.recipe;

          const message = `Reminder: "${recipe.title}" is planned for tomorrow!`;

          await Notification.create({
            recipientId: plan.userId,
            recipientModel: 'User',
            senderId: plan.userId,
            senderModel: 'User',
            type: 'Alerts',
            message,
            relatedId: recipe._id
          });

          console.log(`🔔 Sent reminder to user ${plan.userId} for recipe "${recipe.title}"`);
        }
      }
    } catch (err) {
      console.error('❌ Meal reminder job failed:', err.message);
    }
  }, {
    timezone: 'Asia/Gaza' // ✅ set your local timezone
  });
}

module.exports = sendMealReminders;
