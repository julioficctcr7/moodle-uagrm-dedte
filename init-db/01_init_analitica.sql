-- =======================================================
-- Script 01: Inicializacion de bases de datos UAGRM
-- Se ejecuta automaticamente al primer arranque de MariaDB
-- =======================================================

-- Ajustar charset global
SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;

-- -------------------------------------------------------
-- 1. Verificar y configurar la BD de Moodle
-- -------------------------------------------------------
ALTER DATABASE moodle CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- -------------------------------------------------------
-- 2. Crear la base de datos analitica desacoplada
-- -------------------------------------------------------
CREATE DATABASE IF NOT EXISTS bd_analitica_ava
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

-- -------------------------------------------------------
-- 3. Usuario de SOLO LECTURA para Moodle (analitica_ro)
--    Solo puede hacer SELECT en la BD de Moodle
-- -------------------------------------------------------
CREATE USER IF NOT EXISTS 'analitica_ro'@'%' IDENTIFIED BY 'AnaliticaRO_2024!';
GRANT SELECT ON moodle.* TO 'analitica_ro'@'%';

-- -------------------------------------------------------
-- 4. El usuario 'moodle' tambien accede a bd_analitica_ava
-- -------------------------------------------------------
GRANT ALL PRIVILEGES ON bd_analitica_ava.* TO 'moodle'@'%';

FLUSH PRIVILEGES;

-- -------------------------------------------------------
-- 5. Tablas de la BD Analitica (Etapa 2 - DEDTE)
-- -------------------------------------------------------
USE bd_analitica_ava;

-- Tabla: roles_institucionales
CREATE TABLE IF NOT EXISTS roles_institucionales (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    nombre_rol      VARCHAR(100) NOT NULL,
    descripcion     TEXT,
    nivel_acceso    TINYINT NOT NULL DEFAULT 1 COMMENT '1=Consulta, 2=Analisis, 3=Admin',
    activo          BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla: usuarios_sistema
CREATE TABLE IF NOT EXISTS usuarios_sistema (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    username        VARCHAR(100) NOT NULL UNIQUE,
    nombre_completo VARCHAR(200) NOT NULL,
    email           VARCHAR(200) NOT NULL,
    rol_id          INT NOT NULL,
    unidad          VARCHAR(200) COMMENT 'Ej: DEDTE, FACBA, FCIENCIAS',
    activo          BOOLEAN NOT NULL DEFAULT TRUE,
    ultimo_acceso   TIMESTAMP NULL,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (rol_id) REFERENCES roles_institucionales(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla: asignacion_alcance
CREATE TABLE IF NOT EXISTS asignacion_alcance (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    usuario_id      INT NOT NULL,
    tipo_alcance    ENUM('CURSO','CARRERA','FACULTAD','GLOBAL') NOT NULL,
    referencia_id   INT COMMENT 'ID del curso/carrera/facultad en Moodle',
    referencia_nombre VARCHAR(300),
    activo          BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (usuario_id) REFERENCES usuarios_sistema(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla: bitacora_accesos
CREATE TABLE IF NOT EXISTS bitacora_accesos (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    usuario_id      INT NOT NULL,
    accion          VARCHAR(200) NOT NULL,
    detalle         TEXT,
    ip_address      VARCHAR(45),
    fecha_acceso    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (usuario_id) REFERENCES usuarios_sistema(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla: consolidado_semestral
CREATE TABLE IF NOT EXISTS consolidado_semestral (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    id_curso_moodle INT NOT NULL COMMENT 'mdl_course.id',
    sigla_grupo     VARCHAR(50) NOT NULL,
    gestion         VARCHAR(10) NOT NULL COMMENT 'Ej: 2025-I, 2025-II',
    total_matriculados INT NOT NULL DEFAULT 0,
    total_aprobados INT NOT NULL DEFAULT 0,
    total_reprobados INT NOT NULL DEFAULT 0,
    total_segunda_instancia INT NOT NULL DEFAULT 0,
    total_sin_nota  INT NOT NULL DEFAULT 0,
    total_abandono_critico INT NOT NULL DEFAULT 0 COMMENT 'Sin acceso >= 14 dias',
    promedio_general DECIMAL(5,2),
    fecha_consolidado TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    generado_por    INT COMMENT 'usuarios_sistema.id',
    UNIQUE KEY uq_curso_gestion (id_curso_moodle, gestion)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -------------------------------------------------------
-- 6. Indices para performance en consultas analiticas
-- -------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_consolidado_gestion ON consolidado_semestral(gestion);
CREATE INDEX IF NOT EXISTS idx_consolidado_curso   ON consolidado_semestral(id_curso_moodle);
CREATE INDEX IF NOT EXISTS idx_bitacora_fecha      ON bitacora_accesos(fecha_acceso);
CREATE INDEX IF NOT EXISTS idx_bitacora_usuario    ON bitacora_accesos(usuario_id);

-- -------------------------------------------------------
-- 7. Datos semilla: roles iniciales del sistema
-- -------------------------------------------------------
INSERT IGNORE INTO roles_institucionales (id, nombre_rol, descripcion, nivel_acceso) VALUES
(1, 'Analista DEDTE',    'Consulta de reportes academicos institucionales',         1),
(2, 'Director DEDTE',    'Analisis de rendimiento y toma de decisiones',            2),
(3, 'Admin Sistema',     'Gestion completa del sistema de analitica',               3),
(4, 'Docente',           'Consulta de reportes de sus propios cursos',              1),
(5, 'Autoridad Carrera', 'Consulta de reportes por carrera/programa academico',     2);

-- Usuario administrador inicial del sistema analitico
INSERT IGNORE INTO usuarios_sistema (id, username, nombre_completo, email, rol_id, unidad) VALUES
(1, 'admin.dedte', 'Administrador DEDTE', 'admin@dedte.uagrm.edu.bo', 3, 'DEDTE - UAGRM');

SELECT 'bd_analitica_ava inicializada correctamente con 5 tablas.' AS estado;
