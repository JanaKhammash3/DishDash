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
const Notification = require('./models/Notification');
const type = 'purchase'; // or 'rating'
const sendMealReminders = require('./scheduledJobs/sendMealReminders');
sendMealReminders();
//const testReminder = require('./scheduledJobs/sendMealReminders');
//testReminder(); // temporary
const app = express();
app.use(cors());
app.use(express.json({ limit: '25mb' }));
app.use(express.urlencoded({ extended: true, limit: '25mb' }));
app.use('/api/notifications', require('./routes/notificationRoutes'));


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
app.use('/api/ai', require('./routes/aiRoutes'));
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
global.io = io; // ✅ Add this line

const users = {};
const stores = {}; // maps storeId → socketId
global.stores = {}; // 🧠 Track store socket IDs

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

 socket.on('join_store', (storeId) => {
  stores[storeId] = socket.id;
  console.log(`🏪 Store ${storeId} connected with socket ID ${socket.id}`);
});

socket.on('store_notification', async (data) => {
  const { storeId, senderId, type, ingredient, value } = data;

  const message = `A user ${
    type === 'purchase'
      ? `purchased ${ingredient}`
      : `rated your store ${value} stars`
  }`;

  // ✅ Save to DB
  const notif = await Notification.create({
    recipientId: storeId,
    recipientModel: 'Store',
    senderId,
    senderModel: 'User',
    type,
    message,
    relatedId: storeId,
  });

  // ✅ Populate sender info before emitting
  const populatedNotif = await Notification.findById(notif._id)
    .populate('senderId', 'name avatar');

  // ✅ Emit to the correct store socket (if joined)
  const storeSocketId = stores[storeId];
  if (storeSocketId) {
    io.to(storeSocketId).emit('store_notification', populatedNotif);
  }

  console.log(`📨 Real-time notification sent to store ${storeId}`);
});



 socket.on('send_message', async (data) => {
  const { senderId, receiverId, message = '', image = '' } = data;

  if (!senderId || !receiverId || (!message && !image)) return;

  // Save the chat message
  const chat = new Chat({ senderId, receiverId, message, image });
  await chat.save();

  // Populate sender details
  const populatedSender = await User.findById(senderId).select('name avatar');

  // Build the message payload
  const messagePayload = {
    ...data,
    timestamp: chat.timestamp,
    senderId: {
      _id: senderId,
      name: populatedSender?.name || 'User',
      avatar: populatedSender?.avatar || '',
    },
  };

  // Emit to receiver if online
  const receiverSocket = users[receiverId];
  if (receiverSocket) {
    io.to(receiverSocket).emit('receive_message', messagePayload);
  }

  // Emit to sender as confirmation
  const senderSocket = users[senderId];
  if (senderSocket) {
    io.to(senderSocket).emit('receive_message', messagePayload);
  }

  // 🔔 Compose preview message for notification
  let contentPreview = '';
  if (message && message.trim()) {
    contentPreview = `sent you a message: ${message.length > 50 ? message.substring(0, 50) + '...' : message}`;
  } else if (image && image.trim()) {
    contentPreview = 'sent you an image';
  }

  // ✅ Save the notification
  await Notification.create({
    recipientId: receiverId,
    recipientModel: 'User',
    senderId: senderId,
    senderModel: 'User',
    type: 'message',
    message: contentPreview,
    relatedId: chat._id,
  });

  console.log(`📨 Chat and notification sent from ${senderId} to ${receiverId}`);
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

