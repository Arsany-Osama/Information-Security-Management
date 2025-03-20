# User & Product Management API

This task is a simple Node.js and Express-based API that provides user authentication and product management features using JWT authentication and PostgreSQL.

## Folder Structure

```
root/
│-- models/           # Contains database models using Sequelize ORM
│   │-- user.js       # Defines the User model schema and database interactions
│   │-- product.js    # Defines the Product model schema and database interactions
│-- routes/           # Express route handlers for managing API requests
│   │-- userRoutes.js  # Routes for user authentication and profile management
│   │-- productRoutes.js # Routes for product CRUD (Create/Read/Update/Delete) operations
│-- middleware/       # Middleware functions for authentication and request validation
│   │-- authMiddleware.js # JWT-based authentication middleware to protect routes
│-- node_modules/     # Dependencies installed via npm (automatically generated)
│-- .env              # Environment variables storing sensitive information (e.g., JWT_SECRET, DB credentials)
│-- server.js         # Main server file that initializes Express, connects to the database, and loads routes
│-- package.json      # Project metadata, dependencies, and npm scripts
│-- package-lock.json # Auto-generated file ensuring consistent dependency versions
│-- README.md         # Documentation containing project setup, API usage, and folder structure explanation
│-- Info. Sec. Mgmt Task.pdf # Task Requirements
```

## Dependencies used:
   ```sh
   npm install
   npm init -y
   npm install express bcryptjs jsonwebtoken dotenv pg sequelize cors
   npm install --save-dev nodemon

## API Endpoints

### User Authentication (Require JWT Token)

- **POST /api/users/signup** → Register a new user.
- **POST /api/users/login** → Authenticate user & get JWT token.
- **PUT /api/users/:id** → Update user details (Authenticated users only).

### Product Operations (Require JWT Token)

- **POST /api/products** → Add a new product.
- **GET /api/products** → Retrieve all products.
- **GET /api/products/:pid** → Retrieve a single product by ID.
- **PUT /api/products/:pid** → Update product details.
- **DELETE /api/products/:pid** → Delete a product.

## Authentication

- Users must authenticate using JWT.
- Include the token in headers:
  ```json
  { "Authorization": "MY_JWT_TOKEN"/(OR)/"Bearer MY_JWT_TOKEN" }
  ```

## Technologies Used

- Node.js & Express
- PostgreSQL with Sequelize ORM
- JWT Authentication
- bcrypt for password hashing