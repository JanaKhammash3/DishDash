const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
require('dotenv').config();
const path = require('path');


const app = express();
app.use(cors());
app.use(express.json({ limit: '25mb' })); 
app.use(express.urlencoded({ extended: true, limit: '25mb' }));

// ✅ Connect to MongoDB
mongoose.connect(process.env.MONGO_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
}).then(() => console.log('✅ MongoDB connected'))
  .catch(err => console.error('❌ MongoDB connection error:', err.message));

// ✅ Routes
app.use('/api', require('./routes/userRoutes'));
app.use('/api/users', require('./routes/userRoutes'));
app.use('/api/recipes', require('./routes/recipeRoutes'));
app.use('/api/mealplans', require('./routes/mealPlanRoutes'));
app.use('/api/challenges', require('./routes/challengeRoutes'));
app.use('/api/comments', require('./routes/commentRoutes'));
app.use('/api/notifications', require('./routes/notificationRoutes'));
app.use('/api/stores', require('./routes/storeRoutes'));
app.use('/uploads', express.static('uploads'));
app.use('/images', express.static(path.join(__dirname, './public/images')));


const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`🚀 Server running on http://localhost:${PORT}`));
