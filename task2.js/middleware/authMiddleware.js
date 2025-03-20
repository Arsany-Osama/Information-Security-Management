const jwt = require('jsonwebtoken');
require('dotenv').config();

const authMiddleware = (req, res, next) => {
    const token = req.header('Authorization');
    if (!token) return res.status(401).json({ error: 'Access denied' });

    //Best Practice: To use "Bearer " prefix because it's part of OAuth 2.0 standard and commonly used in APIs for security reasons.
    //But i made it optional here.
    const formattedToken = token.startsWith('Bearer ') ? token.replace('Bearer ', '') : token;

    try {
        const verified = jwt.verify(formattedToken, process.env.JWT_SECRET);
        req.user = verified;
        next();
    } catch (error) {
        res.status(400).json({ error: 'Invalid token' });
    }
};

module.exports = authMiddleware;
