const { DataTypes } = require('sequelize');
const db = require('./index');

const Product = db.sequelize.define('Product', {
    pid: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    pname: { type: DataTypes.STRING, allowNull: false },
    description: { type: DataTypes.TEXT },
    price: { type: DataTypes.DECIMAL, allowNull: false },
    stock: { type: DataTypes.INTEGER, allowNull: false },
    created_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW }
});

module.exports = Product;
