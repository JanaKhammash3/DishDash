const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema({
  recipientId: {
    type: mongoose.Schema.Types.ObjectId,
    required: true,
    refPath: 'recipientModel',
  },
  recipientModel: {
    type: String,
    enum: ['User', 'Store', 'Admin'],
    required: true,
  },
  senderId: {
    type: mongoose.Schema.Types.ObjectId,
    refPath: 'senderModel',
  },
  senderModel: {
    type: String,
    enum: ['User', 'Store', 'Admin'],
  },
  type: {
    type: String,
    enum: [
      'like',
      'comment',
      'follow',
      'message',
      'challenge',
      'Alerts',
      'Other',
      'purchase',  // ✅ Added
      'rating'     // ✅ Added
    ],
    required: true,
  },
  message: {
    type: String,
    required: true,
  },
  relatedId: {
  type: mongoose.Schema.Types.Mixed, // 👈 allows either ObjectId or String
},

  isRead: {
    type: Boolean,
    default: false,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  }
});

module.exports = mongoose.model('Notification', notificationSchema);
