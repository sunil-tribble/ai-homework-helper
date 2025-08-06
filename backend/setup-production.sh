#!/bin/bash

# Production setup script for AI Homework Helper backend
# Run this on your DigitalOcean server

echo "Setting up AI Homework Helper Backend..."

# Update system
apt-get update
apt-get upgrade -y

# Install PostgreSQL
echo "Installing PostgreSQL..."
apt-get install -y postgresql postgresql-contrib

# Start PostgreSQL
systemctl start postgresql
systemctl enable postgresql

# Create database and user
echo "Setting up database..."
sudo -u postgres psql <<EOF
CREATE DATABASE ai_homework;
CREATE USER homework_user WITH ENCRYPTED PASSWORD 'secure_hw_helper_2025';
GRANT ALL PRIVILEGES ON DATABASE ai_homework TO homework_user;
EOF

# Install Node.js if not present
if ! command -v node &> /dev/null; then
    echo "Installing Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt-get install -y nodejs
fi

# Install PM2 globally
npm install -g pm2

# Set up environment variables
echo "Creating .env file..."
cat > /root/ai-homework-backend/.env <<EOF
# Database
DATABASE_URL=postgresql://homework_user:secure_hw_helper_2025@localhost:5432/ai_homework

# OpenAI
OPENAI_API_KEY=${OPENAI_API_KEY}

# Security
JWT_SECRET=$(openssl rand -base64 32)
SESSION_SECRET=$(openssl rand -base64 32)

# Server
NODE_ENV=production
PORT=3000
CORS_ORIGIN=*

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
EOF

# Install dependencies
cd /root/ai-homework-backend
npm ci --only=production

# Start the application
pm2 restart ecosystem.config.js --env production
pm2 save
pm2 startup

echo "Setup complete! Please set your OPENAI_API_KEY:"
echo "export OPENAI_API_KEY='your-key-here'"
echo "Then run: source ~/.bashrc && pm2 restart ai-homework-backend"