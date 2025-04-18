// models/Store.js
const mongoose = require('mongoose');

const storeSchema = new mongoose.Schema({
    name: String,
    location: {
      lat: Number,
      lng: Number
    },
    items: [
      {
        name: String,
        price: Number
      }
    ]
  });
  
  module.exports = mongoose.model('Store', storeSchema);
  