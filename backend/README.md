# AI Homework Helper Backend

Secure backend API for the AI Homework Helper iOS app. This backend proxies OpenAI requests and manages user authentication, subscriptions, and usage limits.

## Quick Start

### 1. Install Dependencies

```bash
npm install
```

### 2. Set Up Environment Variables

Copy `.env.example` to `.env` and fill in your values:

```bash
cp .env.example .env
```

Required environment variables:
- `DATABASE_URL` - PostgreSQL connection string
- `OPENAI_API_KEY` - Your OpenAI API key (the one currently in the iOS app)
- `JWT_SECRET` - A secure random string for JWT signing

### 3. Set Up Database

```bash
# Generate database migrations
npm run db:generate

# Apply migrations
npm run db:push
```

### 4. Run Development Server

```bash
npm run dev
```

The server will start on `http://localhost:3000`

## Deployment Options

### Option 1: Vercel (Recommended for Quick Deploy)

1. Install Vercel CLI: `npm i -g vercel`
2. Run `vercel` in the backend directory
3. Follow the prompts
4. Set environment variables in Vercel dashboard

### Option 2: Railway

1. Create account at [railway.app](https://railway.app)
2. Connect your GitHub repo
3. Railway will auto-detect the configuration
4. Add environment variables in Railway dashboard

### Option 3: Render

1. Create account at [render.com](https://render.com)
2. Create a new Web Service
3. Connect your GitHub repo
4. Render will use the `render.yaml` configuration
5. Add environment variables in Render dashboard

### Option 4: Docker (Any Cloud Provider)

```bash
# Build image
docker build -t ai-homework-helper-api .

# Run container
docker run -p 3000:3000 --env-file .env ai-homework-helper-api
```

## API Endpoints

### Authentication
- `POST /api/v1/auth/signup` - Create new account
- `POST /api/v1/auth/login` - Login with email/password
- `POST /api/v1/auth/device-login` - Anonymous device login (for iOS)
- `POST /api/v1/auth/logout` - Logout
- `GET /api/v1/auth/me` - Get current user

### Homework
- `POST /api/v1/homework/solve` - Solve homework problem (requires auth)
- `GET /api/v1/homework/history` - Get problem history
- `GET /api/v1/homework/problem/:id` - Get specific problem
- `POST /api/v1/homework/problem/:id/rate` - Rate a solution
- `POST /api/v1/homework/resources` - Get curated resources

### Subscription
- `POST /api/v1/subscription/process` - Process App Store subscription
- `GET /api/v1/subscription/status` - Get subscription status
- `GET /api/v1/subscription/history` - Get subscription history

## Security Features

- JWT-based authentication
- Rate limiting on all endpoints
- Secure password hashing with bcrypt
- CORS protection
- SQL injection protection (via Drizzle ORM)
- Environment-based configuration

## Database Schema

The backend uses PostgreSQL with the following main tables:
- `users` - User accounts and settings
- `sessions` - Authentication sessions
- `problems` - Homework problems and solutions
- `subscriptions` - App Store subscriptions
- `analytics` - Usage analytics

## iOS App Integration

Update your iOS app to use the backend API:

1. Replace direct OpenAI calls with backend API calls
2. Add authentication headers to requests
3. Handle rate limits and subscription status
4. Update the `Config.swift` file with your backend URL

Example iOS integration:
```swift
// Instead of calling OpenAI directly:
let backendURL = "https://your-backend.com/api/v1"
let headers = ["Authorization": "Bearer \(sessionToken)"]
```

## Monitoring

- Health check endpoint: `GET /health`
- Logs are written to stdout (captured by deployment platform)
- Analytics events are stored in the database

## Support

For issues or questions:
1. Check the logs in your deployment platform
2. Verify environment variables are set correctly
3. Ensure database is accessible
4. Check rate limits haven't been exceeded