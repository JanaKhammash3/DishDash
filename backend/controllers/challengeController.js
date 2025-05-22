// controllers/challengeController.js
const Challenge = require('../models/Challenge');

// Admin
exports.createChallenge = async (req, res) => {
  try {
    const challenge = await Challenge.create(req.body);
    res.status(201).json(challenge);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};

exports.getAllChallenges = async (req, res) => {
  try {
    const challenges = await Challenge.find().sort({ updatedAt: -1 });
    res.json(challenges);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.getChallengeById = async (req, res) => {
  try {
    const challenge = await Challenge.findById(req.params.id)
      .populate('participants', 'name avatar'); // 👈 only fetch name and avatar

    if (!challenge) {
      return res.status(404).json({ error: 'Challenge not found' });
    }

    res.json(challenge);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};

exports.updateChallenge = async (req, res) => {
  try {
    const challenge = await Challenge.findByIdAndUpdate(req.params.id, req.body, { new: true });
    res.json(challenge);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};

exports.deleteChallenge = async (req, res) => {
  try {
    await Challenge.findByIdAndDelete(req.params.id);
    res.json({ message: 'Challenge deleted' });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};

// Users
exports.joinChallenge = async (req, res) => {
  try {
    const { userId } = req.body;
    const challenge = await Challenge.findById(req.params.id);
    if (!challenge.participants.includes(userId)) {
      challenge.participants.push(userId);
      await challenge.save();
    }
    res.json({ message: 'Joined challenge' });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};

exports.submitChallenge = async (req, res) => {
  try {
    const { userId, recipeId } = req.body;
    const challenge = await Challenge.findById(req.params.id);

    challenge.submissions.push({
      user: userId,
      recipe: recipeId,
      completedAt: new Date()
    });

    await challenge.save();
    res.json({ message: 'Submission received' });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};
