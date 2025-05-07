const Chat = require('../models/chat');

// Send message
exports.sendMessage = async (req, res) => {
  const { senderId, receiverId, message } = req.body;

  if (!senderId || !receiverId || !message) {
    return res.status(400).json({ message: 'Missing fields' });
  }

  const chat = new Chat({ senderId, receiverId, message });
  await chat.save();

  res.status(201).json(chat);
};

// Get conversation between two users
exports.getConversation = async (req, res) => {
  const { userId, otherUserId } = req.params;

  const messages = await Chat.find({
    $or: [
      { senderId: userId, receiverId: otherUserId },
      { senderId: otherUserId, receiverId: userId },
    ]
  })
    .sort({ timestamp: 1 })
    .populate('senderId', 'name avatar')
    .populate('receiverId', 'name avatar');

  res.json(messages);
};
