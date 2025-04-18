// models/Notification.js
const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema({
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    message: String,
    type: { type: String, enum: ['reminder', 'challenge', 'grocery', 'message'] },
    seen: { type: Boolean, default: false },
    createdAt: { type: Date, default: Date.now }
  });
  
  module.exports = mongoose.model('Notification', notificationSchema);