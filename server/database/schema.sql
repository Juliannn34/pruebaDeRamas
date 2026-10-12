-- ============================================================
-- VortexManager · Hayya Fitness Club
-- Esquema de base de datos (idempotente: se puede ejecutar varias veces)
-- Ejecutar con:  cd server && npm run db:setup
-- ============================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 1. Usuarios (autenticación del panel)
CREATE TABLE IF NOT EXISTS usuarios (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    correo VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    rol VARCHAR(50) DEFAULT 'admin',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. Socios
CREATE TABLE IF NOT EXISTS socios (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    dni VARCHAR(20) UNIQUE NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    correo VARCHAR(255),
    telefono VARCHAR(50),
    plan VARCHAR(50) NOT NULL DEFAULT 'Mensual',
    ficha_medica_entregada BOOLEAN DEFAULT FALSE,
    estado VARCHAR(20) DEFAULT 'Activo',
    puntos INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. Registro de accesos (Tótem DNI)
CREATE TABLE IF NOT EXISTS registro_accesos (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    socio_id UUID REFERENCES socios(id) ON DELETE SET NULL,
    dni_ingresado VARCHAR(20) NOT NULL,
    nombre_socio VARCHAR(200),
    estado_acceso VARCHAR(20) NOT NULL,      -- PERMITIDO | DENEGADO
    motivo VARCHAR(255),                     -- "Acceso Correcto", "Ficha Médica Pendiente", ...
    fecha_hora TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Índices para las consultas del dashboard y la ficha del socio
CREATE INDEX IF NOT EXISTS idx_registro_accesos_fecha ON registro_accesos (fecha_hora DESC);
CREATE INDEX IF NOT EXISTS idx_registro_accesos_socio ON registro_accesos (socio_id, fecha_hora DESC);
CREATE INDEX IF NOT EXISTS idx_socios_estado ON socios (estado);

-- 4. Planes (Membresías y Aranceles)
CREATE TABLE IF NOT EXISTS planes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion TEXT,
    precio NUMERIC(10, 2) NOT NULL DEFAULT 0,
    beneficios JSONB DEFAULT '[]'::jsonb,
    imagen_url TEXT,
    estado VARCHAR(20) DEFAULT 'Activo',
    orden INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_planes_estado ON planes (estado);
CREATE INDEX IF NOT EXISTS idx_planes_orden ON planes (orden, created_at);

-- Socios de prueba
INSERT INTO socios (dni, nombre, apellido, correo, telefono, plan, ficha_medica_entregada, estado, puntos)
VALUES
    ('40123456', 'Juan',  'Pérez',     'juan.perez@gmail.com',    '3537123456', 'Mensual',   TRUE,  'Activo',   150),
    ('38987654', 'María', 'Gómez',     'maria.gomez@hotmail.com', '3537654321', 'Quincenal', TRUE,  'Activo',   80),
    ('42111222', 'Lucas', 'Rodríguez', 'lucas.rod@gmail.com',     '3537998877', 'Diario',    FALSE, 'Activo',   20),
    ('39444555', 'Ana',   'Martínez',  'ana.martinez@yahoo.com',  '3537332211', 'Mensual',   FALSE, 'Inactivo', 0)
ON CONFLICT (dni) DO NOTHING;

-- Planes de prueba iniciales basados en el diseño de Figma
INSERT INTO planes (nombre, descripcion, precio, beneficios, imagen_url, estado, orden)
VALUES
    (
        'Mensual',
        'Plan mensual integral con acceso libre a sala de musculación, clases de Hayya Cross y entrenamiento metabólico.',
        10000.00,
        '["Musculación", "Hayya Cross", "Hayya Metabolic"]'::jsonb,
        'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?auto=format&fit=crop&w=800&q=80',
        'Activo',
        1
    ),
    (
        'Quincenal',
        'Pase de 15 días consecutivos con acceso total a todas las actividades y áreas del club.',
        10000.00,
        '["Musculación", "Hayya Cross", "Hayya Metabolic"]'::jsonb,
        'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?auto=format&fit=crop&w=800&q=80',
        'Activo',
        2
    ),
    (
        '1 Día',
        'Pase diario para entrenar por la jornada en musculación y clases grupales sin matrícula.',
        10000.00,
        '["Musculación", "Hayya Cross", "Hayya Metabolic"]'::jsonb,
        'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?auto=format&fit=crop&w=800&q=80',
        'Activo',
        3
    ),
    (
        'Mujeres',
        'Programa exclusivo y clases adaptadas para mujeres, enfocado en tonificación y fuerza.',
        10000.00,
        '["Hayya Mujeres"]'::jsonb,
        'https://images.unsplash.com/photo-1518611012118-696072aa579a?auto=format&fit=crop&w=800&q=80',
        'Activo',
        4
    ),
    (
        'Kids',
        'Actividades deportivas, juegos funcionales y desarrollo psicomotriz para niños de 6 a 12 años.',
        10000.00,
        '["Hayya Kids"]'::jsonb,
        'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?auto=format&fit=crop&w=800&q=80',
        'Activo',
        5
    ),
    (
        'Infanto',
        'Estimulación motriz temprana y dinámicas recreativas guiadas por profesores especializados.',
        10000.00,
        '["Hayya Infanto"]'::jsonb,
        'https://images.unsplash.com/photo-1485546246426-74dc88dec4d9?auto=format&fit=crop&w=800&q=80',
        'Activo',
        6
    )
ON CONFLICT (nombre) DO NOTHING;

-- NOTA: el usuario admin NO se inserta acá. Lo crea scripts/setup-db.js
-- generando un hash bcrypt real de la contraseña (el hash de ejemplo
-- que circulaba no correspondía a "admin123" y el login fallaba).

