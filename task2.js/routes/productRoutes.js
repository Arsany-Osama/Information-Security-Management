const express = require('express');
const Product = require('../models/Product');
const authMiddleware = require('../middleware/authMiddleware');

const router = express.Router();

//authMiddleware usage: Only authenticated users with a valid JWT token can perform CRUD operations on products.

// Retrieve all products
router.get('/', authMiddleware, async (req, res) => {
  try {
      const products = await Product.findAll();
      res.json(products);
  } catch (error) {
      res.status(500).json({ error: error.message });
  }
});

// Retrieve a single product by ID
router.get('/:pid', authMiddleware, async (req, res) => {
  try {
      const product = await Product.findByPk(req.params.pid);
      if (!product) return res.status(404).json({ error: 'Product not found' });
      res.json(product);
  } catch (error) {
      res.status(500).json({ error: error.message });
  }
});

// Add a new product
router.post('/', authMiddleware, async (req, res) => {
    try {
        const { name, price, description } = req.body;
        const product = await Product.create({ name, price, description });
        res.status(201).json({ message: 'Product created', product });
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
});

// Update product details
router.put('/:pid', authMiddleware, async (req, res) => {
    try {
        const product = await Product.findByPk(req.params.pid);
        if (!product) return res.status(404).json({ error: 'Product not found' });

        const { name, price, description } = req.body;
        if (name) product.name = name;
        if (price) product.price = price;
        if (description) product.description = description;
        
        await product.save();
        res.json({ message: 'Product updated successfully', product });
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
});

// Delete a product
router.delete('/:pid', authMiddleware, async (req, res) => {
    try {
        const product = await Product.findByPk(req.params.pid);
        if (!product) return res.status(404).json({ error: 'Product not found' });

        await product.destroy();
        res.json({ message: 'Product deleted successfully' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

module.exports = router;
