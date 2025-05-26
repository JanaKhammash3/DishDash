const Challenge = require('../models/Challenge');
const Notification = require('../models/Notification');

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
      .populate('participants', 'name avatar');
    if (!challenge) return res.status(404).json({ error: 'Challenge not found' });
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
    const { userId, recipeId, notes, image } = req.body;

    const challenge = await Challenge.findById(req.params.id);

    const alreadySubmitted = challenge.submissions.some(
      (s) => s.user.toString() === userId
    );
    if (alreadySubmitted) {
      return res.status(400).json({ message: 'Already submitted' });
    }

    challenge.submissions.push({
      user: userId,
      recipe: recipeId,
      notes,
      image, // ✅ include image
      completedAt: new Date()
    });

    await challenge.save();
    res.json({ message: 'Submission received' });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};


// Admin: View submissions
exports.getSubmissions = async (req, res) => {
  try {
    const challenge = await Challenge.findById(req.params.id)
      .populate('submissions.user', 'name avatar')
      .populate('submissions.recipe', 'title image description');

    if (!challenge) return res.status(404).json({ error: 'Challenge not found' });

    res.json(challenge.submissions);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};

// Admin: Score a submission
exports.scoreSubmission = async (req, res) => {
  try {
    const { score, notes } = req.body;
    const challenge = await Challenge.findById(req.params.id);

    const submission = challenge.submissions.find(s => s.user.toString() === req.params.userId);
    if (!submission) return res.status(404).json({ message: 'Submission not found' });

    submission.score = score;
    submission.notes = notes;
    await challenge.save();

    res.json({ message: 'Submission scored' });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};

// Admin: Set winners
exports.setWinners = async (req, res) => {
  try {
    const challenge = await Challenge.findById(req.params.id);
    const { winners } = req.body; // [{ user: userId, position: 1 }]

    challenge.winners = winners;
    await challenge.save();

    // Notify winners
    for (const winner of winners) {
      await Notification.create({
        recipientId: winner.user,
        recipientModel: 'User',
        senderId: challenge.createdBy,
        senderModel: 'Admin',
        type: 'challenge',
        message: `🎉 Congratulations! You won "${challenge.title}"`,
        relatedId: challenge._id,
        isRead: false
      });
    }

    res.json({ message: 'Winners saved and notified' });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};
