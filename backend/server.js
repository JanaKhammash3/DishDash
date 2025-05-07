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

  socket.on('join', (userId) => {
    users[userId] = socket.id;
    console.log(`👤 User ${userId} joined with socket ID: ${socket.id}`);
  });

  socket.on('send_message', async (data) => {
    const { senderId, receiverId, message } = data;
  
    // Save to DB
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
  
    // ✅ Send to receiver (if online)
    const receiverSocket = users[receiverId];
    if (receiverSocket) {
      io.to(receiverSocket).emit('receive_message', messagePayload);
    }
  
    // ✅ Also send to sender so their own UI updates instantly with name/avatar
    const senderSocket = users[senderId];
    if (senderSocket) {
      io.to(senderSocket).emit('receive_message', messagePayload);
    }
  });
  

  socket.on('disconnect', () => {
    for (const uid in users) {
      if (users[uid] === socket.id) {
        delete users[uid];
        break;
      }
    }
    console.log('🔴 Socket disconnected:', socket.id);
  });
});

// ✅ Start server
const PORT = process.env.PORT || 3000;
server.listen(PORT, () =>
  console.log(`🚀 Server running with sockets on http://localhost:${PORT}`)
);
