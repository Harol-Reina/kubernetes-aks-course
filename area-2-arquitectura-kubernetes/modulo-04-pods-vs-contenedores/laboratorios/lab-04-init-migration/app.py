# Ejercicio 2: Aplicacion Flask con PostgreSQL - app.py
# Descripcion:
#   Aplicacion Flask que se conecta a PostgreSQL y expone 3 endpoints:
#   /, /data (lista usuarios de BD), /config (lee config del init container).
#   Diseñada para ejecutarse DESPUES de que los Init Containers hayan
#   preparado la base de datos y descargado la configuracion.
#
# Conceptos clave:
#   - App principal que depende del trabajo de Init Containers
#   - Lee archivos preparados por init container (setup-status, app-config)
#   - Conexion a PostgreSQL via variables de entorno

from flask import Flask, jsonify
import os
import psycopg2
from psycopg2.extras import RealDictCursor

app = Flask(__name__)

def get_db_connection():
    return psycopg2.connect(
        host=os.environ.get('DB_HOST', 'localhost'),
        database=os.environ.get('DB_NAME', 'myapp'),
        user=os.environ.get('DB_USER', 'user'),
        password=os.environ.get('DB_PASSWORD', 'pass')
    )

@app.route('/')
def home():
    return jsonify({
        'message': '🚀 App with Init Containers',
        'status': 'running',
        'setup_complete': os.path.exists('/app/setup/complete')
    })

@app.route('/data')
def data():
    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute('SELECT * FROM users LIMIT 5')
        users = cur.fetchall()
        cur.close()
        conn.close()
        return jsonify({'users': users})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/config')
def config():
    config_file = '/app/config/app.json'
    if os.path.exists(config_file):
        with open(config_file, 'r') as f:
            import json
            config = json.load(f)
        return jsonify(config)
    return jsonify({'error': 'Config not found'}), 404

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
