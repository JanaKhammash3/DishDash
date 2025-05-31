const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema({
  recipientId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User', // ✅ Always reference 'User' model
    required: true,
  },
  recipientModel: {
    type: String,
    enum: ['User', 'Store', 'Admin'], // ✅ for filtering, not refPath
    required: true,
  },
  senderId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User', // ✅ Always reference 'User' model
    required: true,
  },
  senderModel: {
    type: String,
    enum: ['User', 'Store', 'Admin'], // ✅ for filtering/styling
    required: true,
  },
  type: {
    type: String,
    enum: [
      'like', 'comment', 'follow', 'message',
      'challenge', 'Alerts', 'Other', 'purchase', 'rating'
    ],
    required: true,
  },
  message: {
    type: String,
    required: true,
  },
  relatedId: {
    type: mongoose.Schema.Types.Mixed, // can be ObjectId or string
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
