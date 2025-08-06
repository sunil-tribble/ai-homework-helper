#!/bin/bash

# Nginx and SSL Setup Script for AI Homework Helper
# This sets up Nginx as a reverse proxy with self-signed SSL for now

SERVER_IP="159.203.129.37"

echo "🔒 Setting up Nginx with SSL..."

# Create Nginx configuration
cat > nginx-config.conf << 'EOF'
server {
    listen 80;
    listen 443 ssl;
    server_name 159.203.129.37;

    # SSL Configuration (self-signed for now)
    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # API endpoints
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Health check endpoint
    location /health {
        proxy_pass http://localhost:3000/health;
        access_log off;
    }
}
EOF

echo "📤 Deploying Nginx configuration..."

# Deploy to server
ssh root@$SERVER_IP << 'ENDSSH' || {
    echo "⚠️  Cannot SSH to server. Please run these commands manually on the server:"
    echo ""
    echo "1. Install Nginx:"
    echo "   apt-get update && apt-get install -y nginx"
    echo ""
    echo "2. Create SSL certificates:"
    echo "   mkdir -p /etc/nginx/ssl"
    echo "   openssl req -x509 -nodes -days 365 -newkey rsa:2048 \\"
    echo "     -keyout /etc/nginx/ssl/key.pem \\"
    echo "     -out /etc/nginx/ssl/cert.pem \\"
    echo "     -subj '/CN=159.203.129.37'"
    echo ""
    echo "3. Configure Nginx (copy the nginx-config.conf content to /etc/nginx/sites-available/ai-homework)"
    echo ""
    echo "4. Enable the site:"
    echo "   ln -s /etc/nginx/sites-available/ai-homework /etc/nginx/sites-enabled/"
    echo "   rm /etc/nginx/sites-enabled/default"
    echo "   nginx -t && systemctl restart nginx"
    exit 0
}

# Install Nginx
apt-get update
apt-get install -y nginx

# Create SSL directory and generate self-signed certificate
mkdir -p /etc/nginx/ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/nginx/ssl/key.pem \
  -out /etc/nginx/ssl/cert.pem \
  -subj "/CN=159.203.129.37"

# Remove default site
rm -f /etc/nginx/sites-enabled/default

# Add our configuration
cat > /etc/nginx/sites-available/ai-homework << 'EOCONF'
server {
    listen 80;
    listen 443 ssl;
    server_name 159.203.129.37;

    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /health {
        proxy_pass http://localhost:3000/health;
        access_log off;
    }
}
EOCONF

# Enable the site
ln -sf /etc/nginx/sites-available/ai-homework /etc/nginx/sites-enabled/

# Test and restart Nginx
nginx -t && systemctl restart nginx

echo "✅ Nginx configured with SSL"
ENDSSH

echo "✅ SSL setup complete! The server now accepts HTTPS connections."
echo "⚠️  Note: Using self-signed certificate. For production, get a real domain and use Let's Encrypt."