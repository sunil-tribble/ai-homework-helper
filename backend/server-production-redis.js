require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const { body, validationResult } = require('express-validator');
const winston = require('winston');
const redis = require('redis');
// const RedisStore = require('rate-limit-redis'); // TODO: Fix compatibility with redis v4
const app = express();

// Enhanced logging setup
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  defaultMeta: { service: 'ai-homework-backend' },
  transports: [
    new winston.transports.File({ filename: 'logs/error.log', level: 'error' }),
    new winston.transports.File({ filename: 'logs/combined.log' }),
    new winston.transports.Console({
      format: winston.format.simple()
    })
  ]
});

// Redis client setup
let redisClient;
let redisConnected = false;

async function setupRedis() {
  try {
    redisClient = redis.createClient({
      socket: {
        host: 'localhost',
        port: 6379
      },
      password: process.env.REDIS_PASSWORD
    });

    redisClient.on('error', (err) => {
      logger.error('Redis Client Error', err);
      redisConnected = false;
    });

    redisClient.on('connect', () => {
      logger.info('Redis connected successfully');
      redisConnected = true;
    });

    await redisClient.connect();
    return true;
  } catch (error) {
    logger.error('Failed to connect to Redis:', error);
    return false;
  }
}

// Security middleware
app.use(helmet());

// Trust proxy for rate limiting with Nginx
app.set('trust proxy', 1);

// CORS configuration - restrict in production
app.use(cors({
  origin: process.env.NODE_ENV === 'production' 
    ? process.env.ALLOWED_ORIGINS?.split(',') || ['http://localhost:3000']
    : '*',
  credentials: true
}));

app.use(express.json({ limit: '10mb' }));

// Request logging
app.use((req, res, next) => {
  logger.info({
    method: req.method,
    url: req.url,
    ip: req.ip,
    userAgent: req.get('user-agent')
  });
  next();
});

// Rate limiting - using memory for now due to Redis client compatibility issues
// TODO: Upgrade to redis-rate-limit when it supports redis v4 client
const createRateLimiter = (options) => {
  // For now, always use memory store but keep Redis for OpenAI tracking
  return rateLimit(options);
};

// PostgreSQL connection with better configuration
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.NODE_ENV === 'production' && process.env.DATABASE_SSL === 'true'
    ? { rejectUnauthorized: false } // Local PostgreSQL doesn't use SSL
    : false,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

// JWT secret - ensure this is set in production
const JWT_SECRET = process.env.JWT_SECRET || crypto.randomBytes(64).toString('hex');
if (!process.env.JWT_SECRET && process.env.NODE_ENV === 'production') {
  logger.error('JWT_SECRET not set in production!');
  process.exit(1);
}

// OpenAI rate limiting and cost control - now using Redis
const OPENAI_DAILY_LIMIT = parseInt(process.env.OPENAI_DAILY_LIMIT || '1000');
const OPENAI_USER_DAILY_LIMIT = parseInt(process.env.OPENAI_USER_DAILY_LIMIT || '50');

// Helper function to track OpenAI usage in Redis
async function getUserOpenAIUsage(userId) {
  if (!redisConnected) return 0;
  
  const key = `openai:user:${userId}:${new Date().toDateString()}`;
  const usage = await redisClient.get(key);
  return parseInt(usage || '0');
}

async function incrementUserOpenAIUsage(userId, tokens) {
  if (!redisConnected) return;
  
  const key = `openai:user:${userId}:${new Date().toDateString()}`;
  await redisClient.incrBy(key, tokens);
  await redisClient.expire(key, 86400); // Expire after 24 hours
}

// Initialize database with additional tables
async function initDatabase() {
  try {
    // Users table with enhanced fields
    await pool.query(`
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        device_id VARCHAR(255) UNIQUE NOT NULL,
        email VARCHAR(255),
        password_hash VARCHAR(255),
        is_premium BOOLEAN DEFAULT false,
        daily_solves_used INTEGER DEFAULT 0,
        total_solves_used INTEGER DEFAULT 0,
        last_reset_date DATE DEFAULT CURRENT_DATE,
        age INTEGER,
        parental_consent BOOLEAN DEFAULT false,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // Problems table with cost tracking
    await pool.query(`
      CREATE TABLE IF NOT EXISTS problems (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id),
        question TEXT NOT NULL,
        subject VARCHAR(50),
        solution TEXT,
        tokens_used INTEGER,
        cost_cents INTEGER,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // Sessions table with expiry
    await pool.query(`
      CREATE TABLE IF NOT EXISTS sessions (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id),
        token VARCHAR(255) UNIQUE NOT NULL,
        device_info JSONB,
        expires_at TIMESTAMP NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // API usage tracking
    await pool.query(`
      CREATE TABLE IF NOT EXISTS api_usage (
        id SERIAL PRIMARY KEY,
        date DATE DEFAULT CURRENT_DATE,
        endpoint VARCHAR(255),
        count INTEGER DEFAULT 0,
        tokens_used INTEGER DEFAULT 0,
        cost_cents INTEGER DEFAULT 0,
        UNIQUE(date, endpoint)
      )
    `);

    // Create indexes for performance
    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_users_device_id ON users(device_id);
      CREATE INDEX IF NOT EXISTS idx_sessions_token ON sessions(token);
      CREATE INDEX IF NOT EXISTS idx_problems_user_id ON problems(user_id);
      CREATE INDEX IF NOT EXISTS idx_api_usage_date ON api_usage(date);
    `);

    logger.info('Database initialized successfully');
  } catch (error) {
    logger.error('Database initialization error:', error);
    throw error;
  }
}

// Helper functions
function generateToken() {
  return crypto.randomBytes(32).toString('hex');
}

function generateJWT(userId, deviceId) {
  return jwt.sign(
    { userId, deviceId },
    JWT_SECRET,
    { expiresIn: '30d' }
  );
}

async function trackAPIUsage(endpoint, tokens = 0, costCents = 0) {
  try {
    await pool.query(`
      INSERT INTO api_usage (date, endpoint, count, tokens_used, cost_cents)
      VALUES (CURRENT_DATE, $1, 1, $2, $3)
      ON CONFLICT (date, endpoint)
      DO UPDATE SET 
        count = api_usage.count + 1,
        tokens_used = api_usage.tokens_used + $2,
        cost_cents = api_usage.cost_cents + $3
    `, [endpoint, tokens, costCents]);
  } catch (error) {
    logger.error('Error tracking API usage:', error);
  }
}

async function checkOpenAIBudget() {
  const result = await pool.query(`
    SELECT SUM(cost_cents) as total_cost 
    FROM api_usage 
    WHERE date = CURRENT_DATE
  `);
  
  const dailyCostCents = result.rows[0]?.total_cost || 0;
  if (dailyCostCents > OPENAI_DAILY_LIMIT * 100) {
    throw new Error('Daily OpenAI budget exceeded');
  }
}

// Input validation middleware
const validateDeviceAuth = [
  body('deviceId').isString().notEmpty().isLength({ max: 255 }),
  body('deviceModel').optional().isString().isLength({ max: 100 }),
  body('osVersion').optional().isString().isLength({ max: 50 })
];

const validateSolveRequest = [
  body('question').isString().notEmpty().isLength({ max: 5000 }),
  body('subject').isString().isIn(['math', 'physics', 'chemistry', 'biology', 'english', 'history', 'computerScience', 'programming']),
  body('imageData').optional().isString().isLength({ max: 10000000 }) // 10MB base64
];

// Middleware to verify JWT token
async function authenticateToken(req, res, next) {
  const authHeader = req.headers.authorization;
  const token = authHeader && authHeader.split(' ')[1];
  
  if (!token) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    
    // Also check session in database
    const result = await pool.query(
      'SELECT s.*, u.* FROM sessions s JOIN users u ON s.user_id = u.id WHERE s.user_id = $1 AND s.expires_at > NOW()',
      [decoded.userId]
    );
    
    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'Invalid or expired session' });
    }
    
    req.user = result.rows[0];
    next();
  } catch (error) {
    logger.error('Auth error:', error);
    return res.status(401).json({ error: 'Invalid token' });
  }
}

// Initialize app with Redis support
async function initializeApp() {
  // Set up Redis
  const redisReady = await setupRedis();
  
  // Set up rate limiters after Redis is initialized
  const generalLimiter = createRateLimiter({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100,
    message: 'Too many requests from this IP, please try again later.',
    prefix: 'rl:general:'
  });

  const authLimiter = createRateLimiter({
    windowMs: 15 * 60 * 1000,
    max: 5,
    message: 'Too many authentication attempts, please try again later.',
    prefix: 'rl:auth:'
  });

  const solveLimiter = createRateLimiter({
    windowMs: 60 * 1000, // 1 minute
    max: 10,
    message: 'Too many solve requests, please slow down.',
    prefix: 'rl:solve:'
  });

  app.use('/api/', generalLimiter);
  app.use('/api/v1/auth/', authLimiter);
  app.use('/api/v1/homework/solve', solveLimiter);

  // Health check endpoint
  app.get('/health', async (req, res) => {
    try {
      await pool.query('SELECT 1');
      res.json({ 
        status: 'ok', 
        timestamp: new Date().toISOString(),
        environment: process.env.NODE_ENV || 'development',
        version: process.env.APP_VERSION || '1.0.0',
        redis: redisConnected ? 'connected' : 'disconnected'
      });
    } catch (error) {
      logger.error('Health check failed:', error);
      res.status(500).json({ status: 'error', message: 'Database connection failed' });
    }
  });

  // Authentication endpoint with validation
  app.post('/api/v1/auth/device', validateDeviceAuth, async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    try {
      const { deviceId, deviceModel, osVersion } = req.body;
      
      let user = await pool.query(
        'SELECT * FROM users WHERE device_id = $1',
        [deviceId]
      );
      
      if (user.rows.length === 0) {
        const result = await pool.query(
          'INSERT INTO users (device_id) VALUES ($1) RETURNING *',
          [deviceId]
        );
        user = result;
      }
      
      const userData = user.rows[0];
      
      // Check and reset daily limits
      const today = new Date().toISOString().split('T')[0];
      const lastReset = userData.last_reset_date.toISOString().split('T')[0];
      
      if (today !== lastReset) {
        await pool.query(
          'UPDATE users SET daily_solves_used = 0, last_reset_date = CURRENT_DATE WHERE id = $1',
          [userData.id]
        );
        userData.daily_solves_used = 0;
      }
      
      // Create JWT token
      const token = generateJWT(userData.id, deviceId);
      
      // Store session
      const expiresAt = new Date();
      expiresAt.setDate(expiresAt.getDate() + 30);
      
      await pool.query(
        'INSERT INTO sessions (user_id, token, device_info, expires_at) VALUES ($1, $2, $3, $4)',
        [userData.id, token, JSON.stringify({ deviceModel, osVersion }), expiresAt]
      );
      
      res.json({
        sessionToken: token,
        user: {
          id: userData.id,
          isPremium: userData.is_premium,
          dailySolvesUsed: userData.daily_solves_used,
          dailySolvesLimit: userData.is_premium ? 999 : 5,
          requiresParentalConsent: !userData.parental_consent && userData.age && userData.age < 13
        }
      });
    } catch (error) {
      logger.error('Auth error:', error);
      res.status(500).json({ error: 'Authentication failed' });
    }
  });

  // Homework solving endpoint with comprehensive validation and cost control
  app.post('/api/v1/homework/solve', authenticateToken, validateSolveRequest, async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    try {
      const { question, subject, imageData } = req.body;
      const user = req.user;
      
      // Check daily limit
      if (!user.is_premium && user.daily_solves_used >= 5) {
        return res.status(429).json({ 
          error: 'Daily limit reached',
          upgradeUrl: 'https://apps.apple.com/app/ai-homework-helper'
        });
      }
      
      // Check user's daily OpenAI usage from Redis
      const currentUsage = await getUserOpenAIUsage(user.id);
      if (currentUsage >= OPENAI_USER_DAILY_LIMIT) {
        return res.status(429).json({ 
          error: 'Daily AI usage limit reached. Please try again tomorrow.'
        });
      }
      
      // Check overall OpenAI budget
      await checkOpenAIBudget();
      
      // Academic integrity check
      const suspiciousPatterns = [
        /exam/i, /test/i, /quiz/i, /assessment/i,
        /do not share/i, /confidential/i, /honor code/i
      ];
      
      if (suspiciousPatterns.some(pattern => pattern.test(question))) {
        logger.warn('Suspicious academic content detected', { userId: user.id, question: question.substring(0, 100) });
        return res.status(400).json({ 
          error: 'This content appears to be from an active assessment. Please use this tool only for homework and study purposes.'
        });
      }
      
      // Call OpenAI with token tracking
      const startTime = Date.now();
      const response = await fetch('https://api.openai.com/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${process.env.OPENAI_API_KEY}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          model: 'gpt-4o-mini', // Use cheaper model
          messages: [
            {
              role: 'system',
              content: `You are an expert ${subject} tutor. Provide clear, educational explanations that help students learn. 
                       Do not simply give answers - explain the concepts and methodology. 
                       If you detect this might be from an exam or test, refuse to answer.`
            },
            {
              role: 'user',
              content: imageData ? 
                `Please help me understand this problem: ${question}. [Image provided]` : 
                `Please help me understand this problem: ${question}`
            }
          ],
          max_tokens: 1000, // Limit tokens
          temperature: 0.7
        })
      });
      
      if (!response.ok) {
        throw new Error('OpenAI API error');
      }
      
      const data = await response.json();
      const solution = data.choices[0].message.content;
      const tokensUsed = data.usage?.total_tokens || 0;
      
      // Calculate cost (gpt-4o-mini pricing)
      const costCents = Math.ceil(tokensUsed * 0.015 / 1000); // $0.15 per 1K tokens
      
      // Update user usage in Redis
      await incrementUserOpenAIUsage(user.id, tokensUsed);
      
      // Save to database
      await pool.query(
        'INSERT INTO problems (user_id, question, subject, solution, tokens_used, cost_cents) VALUES ($1, $2, $3, $4, $5, $6)',
        [user.id, question, subject, solution, tokensUsed, costCents]
      );
      
      // Update user stats
      await pool.query(
        'UPDATE users SET daily_solves_used = daily_solves_used + 1, total_solves_used = total_solves_used + 1 WHERE id = $1',
        [user.id]
      );
      
      // Track API usage
      await trackAPIUsage('homework_solve', tokensUsed, costCents);
      
      // Log performance
      logger.info('Solve request completed', {
        userId: user.id,
        subject,
        tokensUsed,
        costCents,
        responseTime: Date.now() - startTime
      });
      
      res.json({
        id: Date.now().toString(),
        solution,
        question,
        subject,
        createdAt: new Date().toISOString(),
        dailySolvesRemaining: user.is_premium ? 999 : (5 - user.daily_solves_used - 1)
      });
      
    } catch (error) {
      logger.error('Solve error:', error);
      
      if (error.message === 'Daily OpenAI budget exceeded') {
        return res.status(503).json({ 
          error: 'Service temporarily unavailable due to high demand. Please try again later.' 
        });
      }
      
      res.status(500).json({ error: 'Failed to solve problem' });
    }
  });

  // User info endpoint
  app.get('/api/v1/users/me', authenticateToken, async (req, res) => {
    const user = req.user;
    res.json({
      id: user.id,
      isPremium: user.is_premium,
      dailySolvesUsed: user.daily_solves_used,
      dailySolvesLimit: user.is_premium ? 999 : 5,
      totalSolvesUsed: user.total_solves_used,
      requiresParentalConsent: !user.parental_consent && user.age && user.age < 13
    });
  });

  // Problem history with pagination
  app.get('/api/v1/problems', authenticateToken, async (req, res) => {
    try {
      const page = parseInt(req.query.page) || 1;
      const limit = Math.min(parseInt(req.query.limit) || 20, 100);
      const offset = (page - 1) * limit;
      
      const result = await pool.query(
        'SELECT id, question, subject, solution, created_at FROM problems WHERE user_id = $1 ORDER BY created_at DESC LIMIT $2 OFFSET $3',
        [req.user.id, limit, offset]
      );
      
      const countResult = await pool.query(
        'SELECT COUNT(*) FROM problems WHERE user_id = $1',
        [req.user.id]
      );
      
      res.json({
        problems: result.rows,
        pagination: {
          page,
          limit,
          total: parseInt(countResult.rows[0].count),
          totalPages: Math.ceil(countResult.rows[0].count / limit)
        }
      });
    } catch (error) {
      logger.error('History error:', error);
      res.status(500).json({ error: 'Failed to get history' });
    }
  });

  // Admin endpoint for monitoring (protect this in production)
  app.get('/api/v1/admin/stats', async (req, res) => {
    // In production, add proper admin authentication
    const adminKey = req.headers['x-admin-key'];
    if (adminKey !== process.env.ADMIN_KEY) {
      return res.status(401).json({ error: 'Unauthorized' });
    }
    
    try {
      const stats = await pool.query(`
        SELECT 
          (SELECT COUNT(*) FROM users) as total_users,
          (SELECT COUNT(*) FROM users WHERE is_premium = true) as premium_users,
          (SELECT COUNT(*) FROM problems) as total_problems,
          (SELECT SUM(cost_cents) FROM api_usage WHERE date = CURRENT_DATE) as daily_cost_cents,
          (SELECT SUM(tokens_used) FROM api_usage WHERE date = CURRENT_DATE) as daily_tokens
      `);
      
      res.json({
        ...stats.rows[0],
        redis: redisConnected ? 'connected' : 'disconnected'
      });
    } catch (error) {
      logger.error('Stats error:', error);
      res.status(500).json({ error: 'Failed to get stats' });
    }
  });

  // COPPA compliance endpoint
  app.post('/api/v1/users/age-verification', authenticateToken, [
    body('age').isInt({ min: 1, max: 120 }),
    body('parentalConsentToken').optional().isString()
  ], async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    
    try {
      const { age, parentalConsentToken } = req.body;
      
      if (age < 13 && !parentalConsentToken) {
        return res.status(400).json({ 
          error: 'Parental consent required for users under 13',
          requiresParentalConsent: true 
        });
      }
      
      await pool.query(
        'UPDATE users SET age = $1, parental_consent = $2 WHERE id = $3',
        [age, age >= 13 || !!parentalConsentToken, req.user.id]
      );
      
      res.json({ success: true });
    } catch (error) {
      logger.error('Age verification error:', error);
      res.status(500).json({ error: 'Failed to verify age' });
    }
  });

  // Error handling middleware
  app.use((err, req, res, next) => {
    logger.error('Unhandled error:', err);
    res.status(500).json({ error: 'Internal server error' });
  });

  // 404 handler
  app.use((req, res) => {
    res.status(404).json({ error: 'Not found' });
  });

  // Graceful shutdown
  process.on('SIGTERM', async () => {
    logger.info('SIGTERM received, shutting down gracefully');
    if (redisClient) {
      await redisClient.quit();
    }
    await pool.end();
    process.exit(0);
  });

  // Initialize database and start server
  try {
    await initDatabase();
    const PORT = process.env.PORT || 3000;
    app.listen(PORT, () => {
      logger.info(`Server running on port ${PORT} in ${process.env.NODE_ENV || 'development'} mode`);
      logger.info(`Redis: ${redisConnected ? 'Connected' : 'Not available (using in-memory fallback)'}`);
    });
  } catch (err) {
    logger.error('Failed to initialize:', err);
    process.exit(1);
  }
}

// Start the application
initializeApp();