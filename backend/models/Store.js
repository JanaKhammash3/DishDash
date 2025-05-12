const mongoose = require('mongoose');

const storeItemSchema = new mongoose.Schema({
  name: { type: String, required: true },
  price: { type: Number, required: true },
  image: { type: String }, // Optional: useful if items might have pictures
  category: { type: String }, // Optional: support filtering later
}, { _id: false }); // prevent duplicate _id fields in embedded items

const storeSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  telephone: { type: String, required: true },
  location: {
    lat: { type: Number, required: true },
    lng: { type: Number, required: true },
  },
  image: { type: String }, // store photo (URL or Base64)
  items: [storeItemSchema], // Embedded item list
}, { timestamps: true });

module.exports = mongoose.models.Store || mongoose.model('Store', storeSchema);
