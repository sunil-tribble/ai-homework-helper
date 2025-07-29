const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
const crypto = require('crypto');
const app = express();

// Middleware
app.use(cors({
  origin: process.env.CORS_ORIGIN || '*',
  credentials: true
}));
app.use(express.json({ limit: '10mb' }));

// PostgreSQL connection
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

// Initialize database tables
async function initDatabase() {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        device_id VARCHAR(255) UNIQUE NOT NULL,
        is_premium BOOLEAN DEFAULT false,
        daily_solves_used INTEGER DEFAULT 0,
        last_reset_date DATE DEFAULT CURRENT_DATE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    await pool.query(`
      CREATE TABLE IF NOT EXISTS problems (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id),
        question TEXT NOT NULL,
        subject VARCHAR(50),
        solution TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    await pool.query(`
      CREATE TABLE IF NOT EXISTS sessions (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id),
        token VARCHAR(255) UNIQUE NOT NULL,
        expires_at TIMESTAMP NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    console.log('Database initialized successfully');
  } catch (error) {
    console.error('Database initialization error:', error);
  }
}

// Helper functions
function generateToken() {
  return crypto.randomBytes(32).toString('hex');
}

async function getUserByDeviceId(deviceId) {
  const result = await pool.query(
    'SELECT * FROM users WHERE device_id = $1',
    [deviceId]
  );
  return result.rows[0];
}

async function createUser(deviceId) {
  const result = await pool.query(
    'INSERT INTO users (device_id) VALUES ($1) RETURNING *',
    [deviceId]
  );
  return result.rows[0];
}

async function checkAndResetDailyLimit(userId) {
  const user = await pool.query(
    'SELECT * FROM users WHERE id = $1',
    [userId]
  );
  
  if (user.rows.length === 0) return null;
  
  const userData = user.rows[0];
  const today = new Date().toISOString().split('T')[0];
  const lastReset = userData.last_reset_date.toISOString().split('T')[0];
  
  if (today !== lastReset) {
    await pool.query(
      'UPDATE users SET daily_solves_used = 0, last_reset_date = CURRENT_DATE WHERE id = $1',
      [userId]
    );
    userData.daily_solves_used = 0;
  }
  
  return userData;
}

// Health check
app.get('/health', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({ 
      status: 'ok', 
      timestamp: new Date().toISOString(),
      environment: process.env.NODE_ENV || 'development'
    });
  } catch (error) {
    res.status(500).json({ status: 'error', message: 'Database connection failed' });
  }
});

// Authentication endpoint
app.post('/api/v1/auth/device', async (req, res) => {
  try {
    const { deviceId, deviceModel, osVersion } = req.body;
    
    if (!deviceId) {
      return res.status(400).json({ error: 'Device ID required' });
    }
    
    let user = await getUserByDeviceId(deviceId);
    if (!user) {
      user = await createUser(deviceId);
    }
    
    // Check daily limits
    user = await checkAndResetDailyLimit(user.id);
    
    // Create session
    const token = generateToken();
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 30); // 30 day expiry
    
    await pool.query(
      'INSERT INTO sessions (user_id, token, expires_at) VALUES ($1, $2, $3)',
      [user.id, token, expiresAt]
    );
    
    res.json({
      token,
      user: {
        id: user.id,
        isPremium: user.is_premium,
        dailySolvesUsed: user.daily_solves_used,
        dailySolvesLimit: user.is_premium ? 999 : 5
      }
    });
  } catch (error) {
    console.error('Auth error:', error);
    res.status(500).json({ error: 'Authentication failed' });
  }
});

// Middleware to verify token
async function authenticateToken(req, res, next) {
  const authHeader = req.headers.authorization;
  const token = authHeader && authHeader.split(' ')[1];
  
  if (!token) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  
  try {
    const result = await pool.query(
      'SELECT s.*, u.* FROM sessions s JOIN users u ON s.user_id = u.id WHERE s.token = $1 AND s.expires_at > NOW()',
      [token]
    );
    
    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'Invalid or expired token' });
    }
    
    req.user = result.rows[0];
    next();
  } catch (error) {
    console.error('Auth middleware error:', error);
    res.status(500).json({ error: 'Authentication failed' });
  }
}

// Homework solving endpoint
app.post('/api/v1/homework/solve', authenticateToken, async (req, res) => {
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
    
    // Call OpenAI
    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${process.env.OPENAI_API_KEY}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        model: 'gpt-4o-mini',
        messages: [
          {
            role: 'system',
            content: `You are an expert ${subject} tutor. Provide clear, step-by-step solutions to homework problems. Format your response with clear sections and explanations.`
          },
          {
            role: 'user',
            content: imageData ? 
              `Please solve this problem: ${question}. [Image data provided]` : 
              question
          }
        ],
        max_tokens: 2000,
        temperature: 0.7
      })
    });
    
    if (!response.ok) {
      throw new Error('OpenAI API error');
    }
    
    const data = await response.json();
    const solution = data.choices[0].message.content;
    
    // Save problem to database
    await pool.query(
      'INSERT INTO problems (user_id, question, subject, solution) VALUES ($1, $2, $3, $4)',
      [user.id, question, subject, solution]
    );
    
    // Update daily count
    if (!user.is_premium) {
      await pool.query(
        'UPDATE users SET daily_solves_used = daily_solves_used + 1 WHERE id = $1',
        [user.id]
      );
    }
    
    res.json({
      id: Date.now().toString(),
      solution,
      question,
      subject,
      createdAt: new Date().toISOString(),
      dailySolvesRemaining: user.is_premium ? 999 : (5 - user.daily_solves_used - 1)
    });
    
  } catch (error) {
    console.error('Solve error:', error);
    res.status(500).json({ error: 'Failed to solve problem' });
  }
});

// Get user info
app.get('/api/v1/users/me', authenticateToken, async (req, res) => {
  const user = req.user;
  res.json({
    id: user.id,
    isPremium: user.is_premium,
    dailySolvesUsed: user.daily_solves_used,
    dailySolvesLimit: user.is_premium ? 999 : 5
  });
});

// Get problem history
app.get('/api/v1/problems', authenticateToken, async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT * FROM problems WHERE user_id = $1 ORDER BY created_at DESC LIMIT 50',
      [req.user.id]
    );
    res.json(result.rows);
  } catch (error) {
    console.error('History error:', error);
    res.status(500).json({ error: 'Failed to get history' });
  }
});

// Initialize database on startup
initDatabase();

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
});