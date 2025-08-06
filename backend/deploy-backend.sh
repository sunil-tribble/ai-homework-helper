#!/bin/bash

# AI Homework Helper Backend Deployment Script
# This script deploys and configures the backend on DigitalOcean

SERVER_IP="159.203.129.37"
REMOTE_DIR="/root/ai-homework-backend"

echo "🚀 AI Homework Helper Backend Deployment"
echo "========================================="

# Check if we have an OpenAI API key
if [ -z "$OPENAI_API_KEY" ]; then
    echo "❌ Error: OPENAI_API_KEY environment variable is not set"
    echo "Please run: export OPENAI_API_KEY='your-key-here'"
    exit 1
fi

echo "📦 Preparing deployment package..."

# Create a temporary deployment directory
DEPLOY_DIR=$(mktemp -d)
cp server-production.js "$DEPLOY_DIR/server.js"
cp package.json "$DEPLOY_DIR/"
cp ecosystem.config.js "$DEPLOY_DIR/"

# Create .env file with all required variables
cat > "$DEPLOY_DIR/.env" <<EOF
# Database Configuration
DATABASE_URL=postgresql://homework_user:hw_helper_secure_2025@localhost:5432/ai_homework

# OpenAI Configuration
OPENAI_API_KEY=$OPENAI_API_KEY

# Security Keys (generated)
JWT_SECRET=$(openssl rand -base64 32)
SESSION_SECRET=$(openssl rand -base64 32)
ADMIN_KEY=$(openssl rand -base64 16)

# Server Configuration
NODE_ENV=production
PORT=3000
CORS_ORIGIN=*

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# OpenAI Usage Limits
OPENAI_DAILY_LIMIT=10
OPENAI_USER_DAILY_LIMIT=50

# App Version
APP_VERSION=1.0.0
EOF

echo "📤 Uploading files to server..."
scp -r "$DEPLOY_DIR"/* root@$SERVER_IP:$REMOTE_DIR/ 2>/dev/null || {
    echo "❌ Failed to upload files. Setting up server from scratch..."
    
    # If SCP fails, use alternative method
    ssh root@$SERVER_IP << 'ENDSSH'
    # Create directory
    mkdir -p /root/ai-homework-backend
    cd /root/ai-homework-backend
    
    # Install Node.js if needed
    if ! command -v node &> /dev/null; then
        curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
        apt-get install -y nodejs
    fi
    
    # Install PostgreSQL if needed
    if ! command -v psql &> /dev/null; then
        apt-get update
        apt-get install -y postgresql postgresql-contrib
        systemctl start postgresql
        systemctl enable postgresql
    fi
    
    # Install PM2
    npm install -g pm2
ENDSSH
}

echo "🗄️ Setting up PostgreSQL database..."
ssh root@$SERVER_IP << 'ENDSSH'
# Create database and user
sudo -u postgres psql << EOF
-- Create database if not exists
SELECT 'CREATE DATABASE ai_homework' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'ai_homework')\gexec

-- Create user if not exists
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_user WHERE usename = 'homework_user') THEN
        CREATE USER homework_user WITH ENCRYPTED PASSWORD 'hw_helper_secure_2025';
    END IF;
END
\$\$;

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE ai_homework TO homework_user;
EOF
ENDSSH

echo "📦 Installing dependencies..."
ssh root@$SERVER_IP "cd $REMOTE_DIR && npm ci --only=production"

echo "🔧 Starting application with PM2..."
ssh root@$SERVER_IP << ENDSSH
cd $REMOTE_DIR

# Stop any existing instance
pm2 stop ai-homework-backend 2>/dev/null || true
pm2 delete ai-homework-backend 2>/dev/null || true

# Start new instance
pm2 start ecosystem.config.js --env production

# Save PM2 configuration
pm2 save
pm2 startup systemd -u root --hp /root

# Show status
pm2 status
ENDSSH

echo "✅ Deployment complete!"
echo ""
echo "📊 Server Status:"
curl -s https://$SERVER_IP/health -k | python3 -m json.tool

echo ""
echo "🔑 Important Information:"
echo "- Server URL: https://$SERVER_IP"
echo "- Health Check: https://$SERVER_IP/health"
echo "- Make sure to save the admin key from the server"
echo ""
echo "⚠️  Next Steps:"
echo "1. Set up a domain name and SSL certificate"
echo "2. Update the iOS app with the correct backend URL"
echo "3. Test the API endpoints"

# Clean up
rm -rf "$DEPLOY_DIR"