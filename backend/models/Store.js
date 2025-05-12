const mongoose = require('mongoose');

const storeSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  telephone: { type: String, required: true }, // ✅ Added telephone field
  location: {
    lat: { type: Number, required: true },
    lng: { type: Number, required: true },
  },
  items: [
    {
      name: { type: String, required: true },
      price: { type: Number, required: true },
    },
  ],
});

module.exports = mongoose.model('Store', storeSchema);
