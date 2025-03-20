const express = require('express');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const User = require('../models/user');
const authMiddleware = require('../middleware/authMiddleware');
require('dotenv').config();

const router = express.Router();

// Get all users
router.get("/", async (req, res) => {
    try {
        const users = await User.findAll(); // Fetch all users from DB
        res.json(users);
    } catch (error) {
        res.status(500).json({ error: "Internal Server Error" });
    }
});


// Signup
router.post('/signup', async (req, res) => {
    try {
        const { name, username, password } = req.body;
        const user = await User.create({ name, username, password });
        res.status(201).json({ message: 'User created', user });
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
});

// Login
router.post('/login', async (req, res) => {
    try {
        const { username, password } = req.body;
        const user = await User.findOne({ where: { username } });

        if (!user || !(await bcrypt.compare(password, user.password))) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }

        const token = jwt.sign({ id: user.id, username: user.username }, process.env.JWT_SECRET, { expiresIn: '10m' });
        res.json({ token });
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
});

// Update Only authorized users with valid tokens
router.put('/:id', authMiddleware, async (req, res) => {
    try {
        const user = await User.findByPk(req.params.id);
        if (!user) return res.status(404).json({ error: "User not found" });

        // Ensure only the logged-in user can update their own profile
        if (req.user.id !== user.id) {
            return res.status(403).json({ error: "Unauthorized" });
        }

        const { name, username, password } = req.body;
        if (name) user.name = name;
        if (username) user.username = username;
        if (password) user.password = await bcrypt.hash(password, 10); // Rehash new password
        await user.save();

        res.json({ message: "User updated successfully", user });
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
});


module.exports = router;
