const mongoose = require('mongoose');

const challengeSchema = new mongoose.Schema({
  title: { type: String, required: true },
  description: { type: String },
  type: { 
    type: String, 
    enum: [
      'Recipe Creation', 
      'Meal Planning', 
      'Grocery', 
      'Community Engagement', 
      'Health Tracking',
      'Bookmarking'
    ],
    required: true
  },
  startDate: { type: Date, required: true },
  endDate: { type: Date, required: true },
  reward: { type: String }, // e.g., "Badge", "Points"
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'Admin' },
  participants: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  submissions: [{
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    recipe: { type: mongoose.Schema.Types.ObjectId, ref: 'Recipe' },
    notes: { type: String },
    image: { type: String }, // ✅ Add this line
    score: { type: Number },
    completedAt: { type: Date }
  }],
  winners: [{
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    position: { type: Number }
  }]
}, { timestamps: true });

module.exports = mongoose.model('Challenge', challengeSchema);
