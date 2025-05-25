const Chat = require('../models/chat');
const User = require('../models/User');
const mongoose = require('mongoose');

// Send message
exports.sendMessage = async (req, res) => {
  try {
    const { senderId, receiverId, message, image } = req.body;

    if (!senderId || !receiverId || (!message && !image)) {
      return res.status(400).json({ message: 'Message or image is required' });
    }

    const chat = new Chat({
      senderId: mongoose.Types.ObjectId(senderId),      // <-- FIX HERE
      receiverId: mongoose.Types.ObjectId(receiverId),  // <-- FIX HERE
      message,
      image,
      isRead: false,
    });

    await chat.save();

    res.status(201).json(chat);
  } catch (err) {
    console.error('Send message error:', err.message);
    res.status(500).json({ error: err.message });
  }
};


// GET /api/chats/unread-count/:userId
exports.getUnreadCount = async (req, res) => {
  try {
    const count = await Chat.countDocuments({
      receiverId: new mongoose.Types.ObjectId(req.params.userId),
      isRead: false,
    });
    res.json({ count });
  } catch (err) {
    console.error('Unread count error:', err.message);
    res.status(500).json({ error: err.message });
  }
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
    .select('senderId receiverId message image timestamp') // ✅ include image
    .populate('senderId', 'name avatar')
    .populate('receiverId', 'name avatar');

  res.json(messages);
};


// Mark all messages from otherUserId → userId as read
exports.markMessagesAsRead = async (req, res) => {
  try {
    const { senderId, receiverId } = req.body; // ✅ from body

    await Chat.updateMany(
      {
        senderId: new mongoose.Types.ObjectId(senderId),
        receiverId: new mongoose.Types.ObjectId(receiverId),
        isRead: false
      },
      { $set: { isRead: true } }
    );

    res.json({ message: 'Messages marked as read' });
  } catch (err) {
    console.error('Mark read error:', err.message);
    res.status(500).json({ error: err.message });
  }
};


// Get list of chat users with last message and unread count
exports.getChatUsers = async (req, res) => {
  try {
    const userId = new mongoose.Types.ObjectId(req.params.userId);

    const chats = await Chat.aggregate([
      {
        $match: {
          $or: [
            { senderId: userId },
            { receiverId: userId }
          ]
        }
      },
      {
        $sort: { timestamp: -1 }
      },
      {
        $group: {
          _id: {
            $cond: [
              { $eq: ['$senderId', userId] },
              '$receiverId',
              '$senderId'
            ]
          },
          lastMessage: { $first: '$message' },
          lastImage: { $first: '$image' }, // 👈 capture image too
          lastTimestamp: { $first: '$timestamp' },
          unreadCount: {
            $sum: {
              $cond: [
                {
                  $and: [
                    { $eq: ['$receiverId', userId] },
                    { $eq: ['$isRead', false] }
                  ]
                },
                1,
                0
              ]
            }
          }
        }
      },
      {
        $lookup: {
          from: 'users',
          localField: '_id',
          foreignField: '_id',
          as: 'user'
        }
      },
      { $unwind: '$user' },

      // ✅ Use [Image] fallback if message is empty but image exists
      {
        $project: {
          _id: '$user._id',
          name: '$user.name',
          avatar: '$user.avatar',
          lastMessage: {
            $cond: [
              { $eq: ['$lastMessage', ''] },
              '[Image]',
              '$lastMessage'
            ]
          },
          lastTimestamp: 1,
          unreadCount: 1
        }
      },
      {
        $sort: { lastTimestamp: -1 }
      }
    ]);

    res.json(chats);
  } catch (err) {
    console.error('Error in getChatUsers:', err.message);
    res.status(500).json({ error: err.message });
  }
};

