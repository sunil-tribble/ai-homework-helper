module.exports = {
  apps: [{
    name: 'ai-homework-backend',
    script: './server-production.js',
    instances: 1,
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    error_file: './logs/error.log',
    out_file: './logs/out.log',
    log_file: './logs/combined.log',
    time: true,
    max_memory_restart: '256M',
    restart_delay: 3000,
    autorestart: true,
    max_restarts: 10,
    min_uptime: '10s',
    watch: false,
    merge_logs: true,
    env_production: {
      NODE_ENV: 'production',
      PORT: 3000
    }
  }]
};