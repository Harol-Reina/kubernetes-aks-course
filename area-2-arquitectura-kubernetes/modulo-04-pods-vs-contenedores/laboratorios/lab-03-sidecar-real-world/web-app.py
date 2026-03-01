# Ejercicio 1: Aplicacion Flask - web-app.py
# Descripcion:
#   Aplicacion web Flask que genera logs en formato JSON estructurado.
#   Escribe logs al shared volume /var/log/app/access.log para que el
#   sidecar Fluent Bit pueda procesarlos en tiempo real.
#
# Conceptos clave:
#   - Logs JSON estructurados para procesamiento automatico
#   - Shared volume (emptyDir) para comunicacion con sidecar
#   - 3 endpoints: /, /api/users, /health

from flask import Flask, request, jsonify
import logging
import json
import time
from datetime import datetime

app = Flask(__name__)

# Configurar logging para escribir JSON estructurado
logging.basicConfig(
    level=logging.INFO,
    format='%(message)s',
    handlers=[
        logging.FileHandler('/var/log/app/access.log'),
        logging.StreamHandler()
    ]
)

@app.route('/')
def home():
    log_entry = {
        'timestamp': datetime.now().isoformat(),
        'method': request.method,
        'path': request.path,
        'user_agent': request.headers.get('User-Agent'),
        'ip': request.remote_addr,
        'message': 'Home page accessed'
    }
    app.logger.info(json.dumps(log_entry))
    return jsonify({'message': '🏠 Welcome to Sidecar Demo', 'status': 'ok'})

@app.route('/api/users')
def users():
    log_entry = {
        'timestamp': datetime.now().isoformat(),
        'method': request.method,
        'path': request.path,
        'user_agent': request.headers.get('User-Agent'),
        'ip': request.remote_addr,
        'message': 'Users API accessed'
    }
    app.logger.info(json.dumps(log_entry))
    return jsonify([{'id': 1, 'name': 'Alice'}, {'id': 2, 'name': 'Bob'}])

@app.route('/health')
def health():
    return jsonify({'status': 'healthy', 'timestamp': datetime.now().isoformat()})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
