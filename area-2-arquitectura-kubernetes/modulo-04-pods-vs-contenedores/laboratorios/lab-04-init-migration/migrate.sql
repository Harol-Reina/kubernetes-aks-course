-- Ejercicio 3: Migracion SQL - migrate.sql
-- Descripcion:
--   Script SQL ejecutado por el Init Container db-migration.
--   Crea la tabla users con datos de prueba usando INSERT ... ON CONFLICT
--   para garantizar idempotencia (puede ejecutarse multiples veces sin error).
--
-- Conceptos clave:
--   - Migraciones idempotentes con ON CONFLICT DO NOTHING
--   - Init Container ejecuta este script via psql antes de iniciar la app
--   - Montado como ConfigMap en /migrations/migrate.sql
--
-- Uso: psql -h db-service -U user -d myapp -f migrate.sql

CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO users (name, email) VALUES
('Alice Johnson', 'alice@example.com'),
('Bob Smith', 'bob@example.com'),
('Charlie Brown', 'charlie@example.com')
ON CONFLICT (email) DO NOTHING;
