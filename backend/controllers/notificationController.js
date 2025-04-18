const Notification = require('../models/Notification');

exports.sendNotification = async (req, res) => {
  try {
    const notif = await Notification.create(req.body);
    res.status(201).json(notif);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

exports.getUserNotifications = async (req, res) => {
  try {
    const notifs = await Notification.find({ userId: req.params.userId });
    res.status(200).json(notifs);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

exports.markAsSeen = async (req, res) => {
  try {
    const notif = await Notification.findByIdAndUpdate(req.params.id, { seen: true }, { new: true });
    res.status(200).json(notif);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};
