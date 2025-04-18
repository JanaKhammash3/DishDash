const Challenge = require('../models/Challenge');

exports.createChallenge = async (req, res) => {
  try {
    const challenge = await Challenge.create(req.body);
    res.status(201).json(challenge);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

exports.getChallenges = async (req, res) => {
  try {
    const challenges = await Challenge.find();
    res.status(200).json(challenges);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

exports.participateInChallenge = async (req, res) => {
  try {
    const challenge = await Challenge.findById(req.params.id);
    challenge.participants.push(req.body.userId);
    await challenge.save();
    res.status(200).json(challenge);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};