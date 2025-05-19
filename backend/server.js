const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const http = require('http'); // 👈 Required for socket.io
const socketIO = require('socket.io');
require('dotenv').config();
const path = require('path');
const chatRoutes = require('./routes/chatRoutes');
const Chat = require('./models/chat');
const User = require('./models/User');
const storeRoutes = require('./routes/storeRoutes');
const { translateText }= require( './translate.js');

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
app.use('/api/chats', chatRoutes);
app.use(storeRoutes);
app.use('/api', require('./routes/storeRoutes'));
const nutritionRoutes = require('./routes/nutritionRoutes');
app.use('/api', nutritionRoutes);

app.post('/translate', async (req, res) => {
  const { text, target } = req.body;

  if (!text) {
    return res.status(400).json({ error: 'Missing "text" in request body' });
  }

  try {
    const translated = await translateText(text, target || 'ar');
    res.json({ translated });
  } catch (error) {
    console.error('Translation Error:', error.message);
    res.status(500).json({ error: 'Translation failed' });
  }
});



// ✅ Create HTTP server and attach Socket.IO
const server = http.createServer(app);
const io = socketIO(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST'],
  }
});

const users = {};

io.on('connection', (socket) => {
  console.log('🟢 Socket connected:', socket.id);

  let currentUserId = null;

  socket.on('join', (userId) => {
    users[userId] = socket.id;
    currentUserId = userId;
    console.log(`👤 User ${userId} joined with socket ID: ${socket.id}`);

    // ✅ Notify all clients this user is online
    io.emit('userOnlineStatus', { userId, online: true });
  });
  socket.on('userOffline', (userId) => {
    console.log(`🚪 User ${userId} manually logged out`);
  
    if (users[userId]) {
      delete users[userId];
      io.emit('userOnlineStatus', { userId, online: false });
      console.log(`🔴 User ${userId} marked offline by logout`);
    }
  });

  socket.on('send_message', async (data) => {
    const { senderId, receiverId, message } = data;

    const chat = new Chat({ senderId, receiverId, message });
    await chat.save();

    const populatedSender = await User.findById(senderId).select('name avatar');

    const messagePayload = {
      ...data,
      timestamp: chat.timestamp,
      senderId: {
        _id: senderId,
        name: populatedSender?.name || 'User',
        avatar: populatedSender?.avatar || '',
      },
    };

    const receiverSocket = users[receiverId];
    if (receiverSocket) {
      io.to(receiverSocket).emit('receive_message', messagePayload);
    }

    const senderSocket = users[senderId];
    if (senderSocket) {
      io.to(senderSocket).emit('receive_message', messagePayload);
    }
  });

  socket.on('disconnect', () => {
    let disconnectedUserId = null;

    for (const uid in users) {
      if (users[uid] === socket.id) {
        disconnectedUserId = uid;
        delete users[uid];
        break;
      }
    }

    if (disconnectedUserId) {
      // ✅ Notify all clients this user went offline
      io.emit('userOnlineStatus', { userId: disconnectedUserId, online: false });
      console.log(`🔴 User ${disconnectedUserId} is now OFFLINE`);
    }

    console.log('🔌 Socket disconnected:', socket.id);
  });
});

const frontendPath = path.join(__dirname, '../frontend_web/build');
app.use(express.static(frontendPath));

// ✅ Only match non-API routes
app.get(/^\/(?!api).*/, (req, res) => {
  res.sendFile(path.join(frontendPath, 'index.html'));
});

// ✅ Start server
const PORT = process.env.PORT || 3000;
server.listen(PORT, '0.0.0.0', () => console.log(`Server running on 0.0.0.0:${PORT}`));

