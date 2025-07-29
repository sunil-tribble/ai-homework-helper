# AI Homework Helper

A comprehensive Swift-based iOS application that provides AI-powered homework assistance to students, backed by a robust Node.js/Express backend deployed on DigitalOcean.

## Table of Contents
- [Overview](#overview)
- [Architecture](#architecture)
- [Backend Infrastructure](#backend-infrastructure)
- [API Documentation](#api-documentation)
- [iOS App Features](#ios-app-features)
- [Security & Compliance](#security--compliance)
- [Deployment](#deployment)
- [Development Setup](#development-setup)
- [Monitoring & Maintenance](#monitoring--maintenance)

## Overview

AI Homework Helper is an educational technology platform that leverages OpenAI's GPT-4 to provide step-by-step explanations and learning assistance for students. The system consists of:

- **iOS App**: Native Swift application with gamification, progress tracking, and intuitive UI
- **Backend API**: Node.js/Express server with PostgreSQL database and Redis caching
- **AI Integration**: OpenAI GPT-4o-mini for generating educational content
- **Infrastructure**: Hosted on DigitalOcean with production-grade security and monitoring

## Architecture

### System Components

```
┌─────────────────┐     HTTPS      ┌──────────────────────┐
│                 │ ─────────────> │                      │
│   iOS App       │                │  DigitalOcean VPS    │
│  (Swift/SwiftUI)│ <───────────── │  159.203.129.37      │
│                 │     JSON        │                      │
└─────────────────┘                └──────────┬───────────┘
                                              │
                                              │
                                   ┌──────────┴───────────┐
                                   │                      │
                              ┌────┴─────┐        ┌───────┴──────┐
                              │PostgreSQL│        │    Redis     │
                              │   DB     │        │   Cache      │
                              └──────────┘        └──────────────┘
                                                         │
                                                         │
                                                  ┌──────┴───────┐
                                                  │   OpenAI     │
                                                  │  GPT-4o-mini │
                                                  └──────────────┘
```

### Technology Stack

**Frontend (iOS)**:
- Swift 5.0+
- SwiftUI
- Combine Framework
- StoreKit (In-App Purchases)
- Vision Framework (OCR)

**Backend**:
- Node.js v18+
- Express.js 4.18.2
- PostgreSQL 14+
- Redis 7+ (caching & rate limiting)
- PM2 (process management)
- Nginx (reverse proxy)

**Infrastructure**:
- DigitalOcean Droplet (Ubuntu 22.04)
- SSL/TLS with self-signed certificate
- PM2 for process management
- Winston for logging

## Backend Infrastructure

### DigitalOcean Deployment Details

**Server Location**: DigitalOcean Droplet
- **IP Address**: 159.203.129.37
- **OS**: Ubuntu 22.04 LTS
- **SSL**: Self-signed certificate (production should use Let's Encrypt)
- **Process Manager**: PM2 with ecosystem.config.js
- **Web Server**: Nginx reverse proxy

### Database Schema

**PostgreSQL Tables**:

1. **users**
   ```sql
   - id: SERIAL PRIMARY KEY
   - device_id: VARCHAR(255) UNIQUE
   - email: VARCHAR(255)
   - password_hash: VARCHAR(255)
   - is_premium: BOOLEAN
   - daily_solves_used: INTEGER
   - total_solves_used: INTEGER
   - last_reset_date: DATE
   - age: INTEGER
   - parental_consent: BOOLEAN
   - created_at: TIMESTAMP
   - updated_at: TIMESTAMP
   ```

2. **problems**
   ```sql
   - id: SERIAL PRIMARY KEY
   - user_id: INTEGER REFERENCES users(id)
   - question: TEXT
   - subject: VARCHAR(50)
   - solution: TEXT
   - tokens_used: INTEGER
   - cost_cents: INTEGER
   - created_at: TIMESTAMP
   ```

3. **sessions**
   ```sql
   - id: SERIAL PRIMARY KEY
   - user_id: INTEGER REFERENCES users(id)
   - token: VARCHAR(255) UNIQUE
   - device_info: JSONB
   - expires_at: TIMESTAMP
   - created_at: TIMESTAMP
   ```

4. **api_usage**
   ```sql
   - id: SERIAL PRIMARY KEY
   - date: DATE
   - endpoint: VARCHAR(255)
   - count: INTEGER
   - tokens_used: INTEGER
   - cost_cents: INTEGER
   ```

### Redis Configuration

Redis is used for:
- Rate limiting per user/IP
- OpenAI token usage tracking
- Session caching
- Real-time usage metrics

**Key Patterns**:
- `openai:user:{userId}:{date}` - Daily OpenAI token usage per user
- `rl:general:*` - General rate limiting
- `rl:auth:*` - Authentication rate limiting
- `rl:solve:*` - Homework solve rate limiting

## API Documentation

### Base URL
- **Production**: `https://159.203.129.37/api/v1`
- **Development**: `http://localhost:3000/api/v1`

### Endpoints

#### Health Check
```
GET /health
Response: {
  "status": "ok",
  "timestamp": "2025-07-29T12:20:22.733Z",
  "environment": "production",
  "version": "1.0.0",
  "redis": "connected"
}
```

#### Authentication
```
POST /api/v1/auth/device
Body: {
  "deviceId": "unique-device-id",
  "deviceModel": "iPhone 14",
  "osVersion": "iOS 17.0"
}
Response: {
  "sessionToken": "jwt-token",
  "user": {
    "id": 123,
    "isPremium": false,
    "dailySolvesUsed": 0,
    "dailySolvesLimit": 5
  }
}
```

#### Homework Solving
```
POST /api/v1/homework/solve
Headers: {
  "Authorization": "Bearer {token}"
}
Body: {
  "question": "What is the derivative of x^2?",
  "subject": "math",
  "imageData": "base64-encoded-image" (optional)
}
Response: {
  "id": "1234567890",
  "solution": "Step-by-step solution...",
  "question": "What is the derivative of x^2?",
  "subject": "math",
  "createdAt": "2025-07-29T12:00:00Z",
  "dailySolvesRemaining": 4
}
```

#### User Profile
```
GET /api/v1/users/me
Headers: {
  "Authorization": "Bearer {token}"
}
Response: {
  "id": 123,
  "isPremium": false,
  "dailySolvesUsed": 1,
  "dailySolvesLimit": 5,
  "totalSolvesUsed": 42
}
```

#### Problem History
```
GET /api/v1/problems?page=1&limit=20
Headers: {
  "Authorization": "Bearer {token}"
}
Response: {
  "problems": [...],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 100,
    "totalPages": 5
  }
}
```

### Rate Limits

- **General API**: 100 requests per 15 minutes
- **Authentication**: 5 attempts per 15 minutes
- **Homework Solving**: 10 requests per minute
- **Daily Solve Limits**: 
  - Free users: 5 solves/day
  - Premium users: Unlimited

## iOS App Features

### Core Features
1. **AI-Powered Solutions**: Step-by-step explanations using GPT-4
2. **Photo Scanning**: OCR capability to scan homework problems
3. **Subject Support**: Math, Physics, Chemistry, Biology, English, History, CS
4. **Progress Tracking**: Daily streaks, XP system, achievements
5. **Gamification**: Avatars, leaderboards, badges
6. **Premium Features**: Unlimited solves, advanced explanations

### Security Features
- Device-based authentication
- JWT token management
- Secure API communication over HTTPS
- Input validation and sanitization
- Academic integrity checks

### User Interface
- SwiftUI-based modern interface
- Particle effects and animations
- Dark mode support
- Accessibility features
- Haptic feedback

## Security & Compliance

### Security Measures
1. **API Security**:
   - Helmet.js for security headers
   - Rate limiting on all endpoints
   - Input validation with express-validator
   - JWT authentication
   - CORS restrictions

2. **Data Protection**:
   - PostgreSQL with parameterized queries
   - Bcrypt for password hashing
   - SSL/TLS encryption in transit
   - Token-based sessions

3. **Academic Integrity**:
   - Pattern detection for exam/test content
   - Educational explanations vs direct answers
   - Usage tracking and monitoring

### Compliance
- **COPPA**: Age verification and parental consent for users under 13
- **Privacy**: Minimal data collection, device-based authentication
- **App Store**: Compliant with Apple's guidelines for educational apps

## Deployment

### Backend Deployment Process

1. **Server Setup**:
   ```bash
   # SSH into DigitalOcean droplet
   ssh root@159.203.129.37
   
   # Install dependencies
   apt update && apt upgrade
   apt install nodejs npm postgresql redis nginx
   
   # Setup PostgreSQL
   sudo -u postgres createdb ai_homework_db
   sudo -u postgres createuser ai_homework_user
   ```

2. **Application Deployment**:
   ```bash
   # Clone repository
   git clone [repository-url]
   cd AIHomeworkHelper/backend
   
   # Install dependencies
   npm install
   
   # Setup environment variables
   cp .env.production .env
   # Edit .env with actual values
   
   # Start with PM2
   npm run prod
   ```

3. **Nginx Configuration**:
   ```nginx
   server {
       listen 443 ssl;
       server_name 159.203.129.37;
       
       ssl_certificate /path/to/cert.pem;
       ssl_certificate_key /path/to/key.pem;
       
       location / {
           proxy_pass http://localhost:3000;
           proxy_http_version 1.1;
           proxy_set_header Upgrade $http_upgrade;
           proxy_set_header Connection 'upgrade';
           proxy_set_header Host $host;
           proxy_cache_bypass $http_upgrade;
       }
   }
   ```

### iOS App Deployment

1. **Build Configuration**:
   - Update `Config.swift` with production backend URL
   - Set proper bundle identifier
   - Configure App Store Connect

2. **Release Process**:
   ```bash
   # Archive in Xcode
   Product > Archive
   
   # Upload to App Store Connect
   Window > Organizer > Distribute App
   ```

## Development Setup

### Backend Development

1. **Prerequisites**:
   - Node.js 18+
   - PostgreSQL 14+
   - Redis 7+

2. **Local Setup**:
   ```bash
   cd AIHomeworkHelper/backend
   npm install
   
   # Setup local PostgreSQL
   createdb ai_homework_dev
   
   # Copy environment variables
   cp .env.example .env
   # Edit .env with local values
   
   # Run development server
   npm run dev
   ```

### iOS Development

1. **Prerequisites**:
   - Xcode 15+
   - iOS 17.0+ SDK
   - Apple Developer Account

2. **Setup**:
   ```bash
   cd AIHomeworkHelper
   open AIHomeworkHelper.xcodeproj
   
   # Update Config.swift for local backend
   # Build and run on simulator/device
   ```

## Monitoring & Maintenance

### Monitoring Tools

1. **Application Logs**:
   ```bash
   # View PM2 logs
   pm2 logs ai-homework-backend
   
   # View combined logs
   tail -f logs/combined.log
   
   # View error logs
   tail -f logs/error.log
   ```

2. **System Monitoring**:
   - PM2 monitoring: `pm2 monit`
   - PostgreSQL stats: `SELECT * FROM api_usage WHERE date = CURRENT_DATE;`
   - Redis monitoring: `redis-cli monitor`

3. **Admin Endpoints**:
   ```bash
   # Get system stats (requires admin key)
   curl -H "x-admin-key: YOUR_ADMIN_KEY" https://159.203.129.37/api/v1/admin/stats
   ```

### Maintenance Tasks

1. **Daily**:
   - Monitor API usage and costs
   - Check error logs
   - Verify rate limiting effectiveness

2. **Weekly**:
   - Database backups
   - Security updates
   - Performance optimization review

3. **Monthly**:
   - SSL certificate renewal
   - Dependency updates
   - Cost analysis and optimization

### Cost Management

**OpenAI API Costs**:
- Model: GPT-4o-mini ($0.15 per 1K tokens)
- Daily budget limit: $10 (configurable)
- Per-user daily limit: 50 requests
- Cost tracking in `api_usage` table

**Infrastructure Costs**:
- DigitalOcean Droplet: ~$20-40/month
- PostgreSQL storage: Included
- SSL Certificate: Free (Let's Encrypt)

## Troubleshooting

### Common Issues

1. **SSL Certificate Errors**:
   - Current setup uses self-signed certificate
   - Production should use Let's Encrypt: `certbot --nginx -d your-domain.com`

2. **Rate Limiting Issues**:
   - Check Redis connection: `redis-cli ping`
   - Review rate limit settings in server configuration

3. **Database Connection**:
   - Verify PostgreSQL is running: `systemctl status postgresql`
   - Check connection string in `.env`

4. **High OpenAI Costs**:
   - Monitor `api_usage` table
   - Adjust `OPENAI_DAILY_LIMIT` and `OPENAI_USER_DAILY_LIMIT`
   - Consider using cheaper models or reducing token limits

## Future Enhancements

1. **Infrastructure**:
   - Implement proper SSL with Let's Encrypt
   - Add CDN for static assets
   - Implement database replication
   - Add comprehensive monitoring (Datadog/New Relic)

2. **Features**:
   - Multi-language support
   - Voice input/output
   - Collaborative study sessions
   - Parent dashboard
   - Teacher portal

3. **Security**:
   - Implement OAuth2 authentication
   - Add two-factor authentication
   - Enhanced fraud detection
   - Regular security audits

## Support

For technical support or questions:
- Backend issues: Check logs in `/logs` directory
- iOS app issues: Review Xcode console logs
- API documentation: See above API section
- Infrastructure: SSH to 159.203.129.37 (requires access)

---

Last Updated: July 29, 2025