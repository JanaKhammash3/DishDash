const mongoose = require('mongoose');

// 🔹 Store Item Schema
const storeItemSchema = new mongoose.Schema({
  _id: {
    type: mongoose.Schema.Types.ObjectId,
    default: () => new mongoose.Types.ObjectId()
  },
  name: { type: String, required: true },
  price: { type: Number, required: true },
  image: { type: String },
  category: { type: String },
  status: {
    type: String,
    enum: ['Available', 'Out of Stock', 'Will be Available Soon'],
    default: 'Available'
  }
}, { _id: false }); // keep false if items are embedded

// 🔹 Purchase Schema
const purchaseSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  ingredient: { type: String, required: true },
  date: { type: Date, default: Date.now }
}, { _id: false }); // embedded array, no need for _id

// 🔹 Rating Schema (embedded array of subdocuments)
const ratingSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  value: { type: Number, required: true } // 1 to 5
}, { _id: false });

// 🔹 Store Schema
const storeSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  telephone: { type: String, required: true },
  location: {
    lat: { type: Number, required: true },
    lng: { type: Number, required: true }
  },
  image: { type: String },
  items: [storeItemSchema],
  purchases: [purchaseSchema],
  ratings: [ratingSchema],
  openHours: {
    from: { type: String, required: true, default: '08:00' },
    to: { type: String, required: true, default: '23:59' }
  }
}, { timestamps: true });

// 🔹 Export Store model
module.exports = mongoose.models.Store || mongoose.model('Store', storeSchema);
