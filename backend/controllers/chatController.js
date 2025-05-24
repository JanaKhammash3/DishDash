const Chat = require('../models/chat');
const User = require('../models/User');
const mongoose = require('mongoose');

// Send message
exports.sendMessage = async (req, res) => {
  const { senderId, receiverId, message } = req.body;

  if (!senderId || !receiverId || !message) {
    return res.status(400).json({ message: 'Missing fields' });
  }

  const chat = new Chat({
    senderId,
    receiverId,
    message,
    isRead: false // ✅ mark as unread
  });
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
      {
        $project: {
          _id: '$user._id',
          name: '$user.name',
          avatar: '$user.avatar',
          lastMessage: 1,
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
