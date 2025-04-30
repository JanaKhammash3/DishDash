const User = require('../models/User');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const multer = require('multer');
const path = require('path');

// Setup storage for Multer
const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, 'uploads/'), // Folder 'uploads'
  filename: (req, file, cb) => cb(null, `${req.params.id}_${Date.now()}${path.extname(file.originalname)}`),
});

const upload = multer({ storage });
// Register user
exports.register = async (req, res) => {
  const { name, email, password, location } = req.body;

  try {
    const exists = await User.findOne({ email });
    if (exists) return res.status(400).json({ message: 'Email already in use' });

    const hashed = await bcrypt.hash(password, 10);

    const newUser = await User.create({
      name,
      email,
      password: hashed,
      avatar: '',
      location: location || { latitude: null, longitude: null },
      allergies: [],
      calorieScore: 0,
      following: [],
      recipes: [],
      savedPlans: [],
      currentGroceryList: [],
      role: 'user'
    });

    res.status(201).json({ message: 'User created', userId: newUser._id });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

// Login user
exports.login = async (req, res) => {
  const { email, password } = req.body;

  try {
    const user = await User.findOne({ email });
    if (!user) return res.status(400).json({ message: 'Invalid credentials' });

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) return res.status(400).json({ message: 'Invalid credentials' });

    const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET, { expiresIn: '1d' });

    res.status(200).json({
      message: 'Login successful',
      token,
      user: {
        _id: user._id,
        name: user.name,
        email: user.email,
        avatar: user.avatar,
        location: user.location,
        allergies: user.allergies,
        calorieScore: user.calorieScore
      }
    });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

// Get full user profile (excluding password)
exports.getUserProfile = async (req, res) => {
  try {
    const user = await User.findById(req.params.id).select('-password');
    if (!user) return res.status(404).json({ message: 'User not found' });
    res.status(200).json(user);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

// Update full profile
exports.updateProfile = async (req, res) => {
  try {
    const updated = await User.findByIdAndUpdate(req.params.id, req.body, { new: true });
    res.status(200).json(updated);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

// Update allergies
exports.updateAllergies = async (req, res) => {
  try {
    const { allergies } = req.body;
    if (!Array.isArray(allergies)) {
      return res.status(400).json({ message: 'Allergies must be an array' });
    }

    const updatedUser = await User.findByIdAndUpdate(
      req.params.id,
      { allergies },
      { new: true }
    );

    res.status(200).json(updatedUser);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

// Controller for Upload Avatar (base64)
exports.uploadAvatar = async (req, res) => {
  try {
    const { avatar } = req.body;

    if (!avatar || typeof avatar !== 'string' || avatar.length < 50) {
      return res.status(400).json({ message: 'Invalid avatar data' });
    }

    const updatedUser = await User.findByIdAndUpdate(
      req.params.id,
      { avatar }, // saving base64 string
      { new: true }
    );

    if (!updatedUser) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.status(200).json(updatedUser);
  } catch (err) {
    console.error('Avatar Upload Error:', err.message);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};
exports.saveRecipeToUser = async (req, res) => {
  try {
    const { userId } = req.params;
    const { recipeId } = req.body;

    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ message: 'User not found' });

    if (user.recipes.includes(recipeId)) {
      return res.status(400).json({ message: 'Recipe already saved' });
    }

    user.recipes.push(recipeId);
    await user.save();

    res.status(200).json({ message: 'Recipe saved successfully' });
  } catch (err) {
    console.error('Error saving recipe:', err.message);
    res.status(500).json({ message: 'Internal server error' });
  }
};
exports.unsaveRecipe = async (req, res) => {
  try {
    const { userId } = req.params;
    const { recipeId } = req.body;

    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ error: 'User not found' });

    user.recipes = user.recipes.filter(
      id => id.toString() !== recipeId.toString()
    );

    await user.save();
    res.status(200).json({ message: 'Recipe removed from saved list' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};
exports.getSavedRecipes = async (req, res) => {
  const user = await User.findById(req.params.id).populate('recipes');
  res.json(user.recipes);
};
