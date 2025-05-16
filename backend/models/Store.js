const mongoose = require('mongoose');

const storeItemSchema = new mongoose.Schema({
  name: { type: String, required: true },
  price: { type: Number, required: true },
  image: { type: String },
  category: { type: String },
}, { _id: false });

const purchaseSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  ingredient: { type: String, required: true },
  date: { type: Date, default: Date.now },
}, { _id: false });

const storeSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  telephone: { type: String, required: true },
  location: {
    lat: { type: Number, required: true },
    lng: { type: Number, required: true },
  },
  image: { type: String },
  items: [storeItemSchema],
  purchases: [purchaseSchema], // ✅ Track which user bought what
  ratings: [{
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  value: { type: Number, required: true } // 1 to 5
}],
openHours: {
  from: { type: String, required: true, default: '08:00' },
  to: { type: String, required: true, default: '24:00' }
},

}, { timestamps: true });

module.exports = mongoose.models.Store || mongoose.model('Store', storeSchema);
