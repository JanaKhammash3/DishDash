const mongoose = require('mongoose');

const adminSchema = new mongoose.Schema({
  name: String,
  email: String,
  avatar: String
});

module.exports = mongoose.model('Admin', adminSchema);
