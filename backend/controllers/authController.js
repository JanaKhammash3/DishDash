const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');

// Register controller
exports.register = async (req, res) => {
  const { name, email, password } = req.body;


  try {
    const exists = await User.findOne({ email });
    if (exists) return res.status(400).json({ message: 'Email already in use' });

    const hashed = await bcrypt.hash(password, 10);
    await User.create({ name, email, password: hashed });
    console.log('REGISTER BODY:', req.body);

    return res.status(201).json({ message: 'User created' });
    
  } catch (err) {
    return res.status(500).json({ message: 'Server error', error: err.message });
  }
};

// Login controller
exports.login = async (req, res) => {
  const { email, password } = req.body;

  try {
    const user = await User.findOne({ email });
    if (!user) return res.status(400).json({ message: 'Invalid credentials' });

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) return res.status(400).json({ message: 'Invalid credentials' });

    const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET, { expiresIn: '1d' });
    return res.status(200).json({
      message: 'Login successful',
      token,
      user: { name: user.name, email: user.email }
    });
  } catch (err) {
    return res.status(500).json({ message: 'Server error', error: err.message });
  }
};
