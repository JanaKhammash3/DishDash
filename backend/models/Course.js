// models/Course.js
const mongoose = require('mongoose');

const episodeSchema = new mongoose.Schema({
  title: String,
  videoUrl: String,       // Full Cloudinary video URL
  startTime: Number,      // in seconds
  endTime: Number,        // in seconds
  duration: Number,       // in minutes
  sourceType: {
    type: String,
    enum: ['cloudinary', 'youtube', 'vimeo', 'external'],
    default: 'cloudinary'
  }
});

const courseSchema = new mongoose.Schema({
  title: String,
  chefName: String,
  chefAvatar: String,
  description: String,
  image: String, // course cover image
  episodes: [episodeSchema],
  ratings: [Number], // array of rating values (1–5)
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Course', courseSchema);
