// app.js - Aplicación Node.js de ejemplo
const fs = require('fs');
const express = require('express');

// === Leer Variables de Entorno ===
const PORT = process.env.PORT || 3000;
const NODE_ENV = process.env.NODE_ENV || 'development';
const LOG_LEVEL = process.env.LOG_LEVEL || 'debug';

// === Leer Archivo de Configuración ===
let config;
try {
  const configFile = fs.readFileSync('/app/config/app-config.json', 'utf8');
  config = JSON.parse(configFile);
  console.log('✅ Configuración cargada desde /app/config/app-config.json');
} catch (error) {
  console.error('❌ Error leyendo configuración:', error.message);
  process.exit(1);
}

// === Credenciales desde Secrets ===
const dbPassword = process.env.DB_PASSWORD;
const redisPassword = process.env.REDIS_PASSWORD;
const apiKey = process.env.API_KEY;

if (!dbPassword || !redisPassword || !apiKey) {
  console.error('❌ Faltan credenciales requeridas');
  process.exit(1);
}

// === Crear Aplicación Express ===
const app = express();

// Middleware
app.use(express.json());

// === Endpoints ===

// Health check (liveness)
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Readiness check
app.get('/ready', (req, res) => {
  // Aquí verificarías conexión a DB, Redis, etc.
  const ready = true;  // Simplificado
  
  if (ready) {
    res.status(200).json({ 
      status: 'ready',
      environment: NODE_ENV
    });
  } else {
    res.status(503).json({ status: 'not ready' });
  }
});

// Endpoint de configuración (para debugging - ⚠️ NO exponer passwords en prod)
app.get('/config', (req, res) => {
  res.json({
    environment: NODE_ENV,
    port: PORT,
    logLevel: LOG_LEVEL,
    database: {
      host: config.database.host,
      port: config.database.port,
      name: config.database.name,
      pool: config.database.pool
    },
    redis: config.redis,
    features: config.features
  });
});

// Endpoint principal
app.get('/', (req, res) => {
  res.json({
    message: '🚀 API funcionando correctamente',
    version: '1.0.0',
    environment: NODE_ENV
  });
});

// === Iniciar Servidor ===
app.listen(PORT, () => {
  console.log(`🚀 Servidor corriendo en puerto ${PORT}`);
  console.log(`📦 Entorno: ${NODE_ENV}`);
  console.log(`📊 Log Level: ${LOG_LEVEL}`);
  console.log(`🗄️  Database: ${config.database.host}:${config.database.port}`);
  console.log(`🔴 Redis: ${config.redis.host}:${config.redis.port}`);
  console.log(`✨ Features: Cache=${config.features.enableCache}, Metrics=${config.features.enableMetrics}`);
});

// Manejo de señales para shutdown graceful
process.on('SIGTERM', () => {
  console.log('👋 SIGTERM recibido, cerrando servidor...');
  server.close(() => {
    console.log('✅ Servidor cerrado');
    process.exit(0);
  });
});
