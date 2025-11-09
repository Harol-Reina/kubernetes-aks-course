const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

// Middleware para parsear JSON
app.use(express.json());

// Middleware para logging
app.use((req, res, next) => {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] ${req.method} ${req.path}`);
  next();
});

// Ruta principal
app.get('/', (req, res) => {
  res.json({
    message: '¡Hola desde Docker! 🐳',
    application: 'Ejemplo Node.js dockerizado',
    version: '1.0.0',
    environment: process.env.NODE_ENV || 'development',
    timestamp: new Date().toISOString()
  });
});

// Health check endpoint (usado por Docker HEALTHCHECK)
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'OK',
    uptime: process.uptime(),
    timestamp: new Date().toISOString()
  });
});

// Información del sistema
app.get('/info', (req, res) => {
  res.json({
    hostname: require('os').hostname(),
    platform: process.platform,
    nodeVersion: process.version,
    memory: {
      total: Math.round(require('os').totalmem() / 1024 / 1024) + ' MB',
      free: Math.round(require('os').freemem() / 1024 / 1024) + ' MB'
    },
    uptime: Math.round(process.uptime()) + ' segundos'
  });
});

// Ruta de prueba con parámetros
app.get('/api/users/:id', (req, res) => {
  const userId = req.params.id;
  res.json({
    userId: userId,
    name: `Usuario ${userId}`,
    email: `user${userId}@example.com`,
    status: 'active'
  });
});

// Manejo de rutas no encontradas
app.use((req, res) => {
  res.status(404).json({
    error: 'Ruta no encontrada',
    path: req.path,
    method: req.method
  });
});

// Iniciar servidor
app.listen(PORT, '0.0.0.0', () => {
  console.log('=================================');
  console.log(`🚀 Servidor iniciado`);
  console.log(`📍 Puerto: ${PORT}`);
  console.log(`🌍 Entorno: ${process.env.NODE_ENV || 'development'}`);
  console.log(`⏰ Timestamp: ${new Date().toISOString()}`);
  console.log('=================================');
  console.log('');
  console.log('Endpoints disponibles:');
  console.log(`  GET  http://localhost:${PORT}/         - Mensaje de bienvenida`);
  console.log(`  GET  http://localhost:${PORT}/health   - Health check`);
  console.log(`  GET  http://localhost:${PORT}/info     - Información del sistema`);
  console.log(`  GET  http://localhost:${PORT}/api/users/:id - Ejemplo con parámetros`);
  console.log('');
});

// Manejo de señales de terminación
process.on('SIGTERM', () => {
  console.log('⚠️  SIGTERM recibido. Cerrando servidor gracefully...');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('⚠️  SIGINT recibido. Cerrando servidor gracefully...');
  process.exit(0);
});
