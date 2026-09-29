-- =======================================================
-- Script 03: Consultas de Validacion Analitica
-- Version corregida y optimizada para Moodle 5.1 / UAGRM
-- =======================================================
-- Ejecutar dentro del contenedor:
--   docker exec -it moodle_uagrm_db mysql -u analitica_ro -p'AnaliticaRO_2024!' moodle
-- =======================================================

USE moodle;

-- =======================================================
-- CONSULTA 1: Rendimiento academico del curso
-- (Aprobados, Reprobados, 2da Instancia - Escala UAGRM)
-- =======================================================
SELECT
    c.id                                                        AS id_curso,
    c.shortname                                                 AS sigla_grupo,
    c.fullname                                                  AS nombre_curso,
    COUNT(DISTINCT ue.userid)                                   AS total_matriculados,
    COUNT(DISTINCT CASE WHEN gg.finalgrade >= 51.00             THEN ue.userid END) AS aprobados,
    COUNT(DISTINCT CASE WHEN gg.finalgrade IS NOT NULL
                         AND gg.finalgrade >= 40.00
                         AND gg.finalgrade <= 50.00             THEN ue.userid END) AS segunda_instancia,
    COUNT(DISTINCT CASE WHEN gg.finalgrade IS NOT NULL
                         AND gg.finalgrade >= 1.00
                         AND gg.finalgrade < 40.00              THEN ue.userid END) AS reprobados,
    COUNT(DISTINCT CASE WHEN gg.finalgrade = 0.00               THEN ue.userid END) AS reprobados_con_cero,
    COUNT(DISTINCT CASE WHEN gg.finalgrade IS NULL               THEN ue.userid END) AS sin_nota,
    ROUND(AVG(CASE WHEN gg.finalgrade IS NOT NULL
               THEN gg.finalgrade END), 2)                      AS promedio_general,
    ROUND(
        COUNT(DISTINCT CASE WHEN gg.finalgrade >= 51 THEN ue.userid END) * 100.0
        / NULLIF(COUNT(DISTINCT ue.userid), 0), 1)             AS porcentaje_aprobacion
FROM mdl_course c
JOIN mdl_enrol e             ON e.courseid = c.id
JOIN mdl_user_enrolments ue  ON ue.enrolid = e.id AND ue.status = 0
LEFT JOIN mdl_grade_items gi ON gi.courseid = c.id AND gi.itemtype = 'course'
LEFT JOIN mdl_grade_grades gg ON gg.itemid = gi.id AND gg.userid = ue.userid
WHERE c.id = 2  -- Ajustar al ID del curso restaurado
GROUP BY c.id, c.shortname, c.fullname;

-- =======================================================
-- CONSULTA 2: Inactividad y Abandono Critico
-- Umbrales UAGRM: Alerta >= 7 dias, Critico >= 14 dias
-- =======================================================
SELECT
    u.id                                                                            AS id_estudiante,
    u.username                                                                      AS registro_universitario,
    CONCAT(u.firstname, ' ', u.lastname)                                            AS estudiante,
    MAX(l.timecreated)                                                              AS ultimo_acceso_epoch,
    FROM_UNIXTIME(MAX(l.timecreated), '%d/%m/%Y %H:%i')                            AS ultimo_acceso_fecha,
    CASE
        WHEN MAX(l.timecreated) IS NULL THEN 999
        ELSE DATEDIFF(NOW(), FROM_UNIXTIME(MAX(l.timecreated)))
    END                                                                             AS dias_inactivo,
    CASE
        WHEN MAX(l.timecreated) IS NULL THEN 'SIN_ACCESO'
        WHEN DATEDIFF(NOW(), FROM_UNIXTIME(MAX(l.timecreated))) >= 14 THEN 'ABANDONO_CRITICO'
        WHEN DATEDIFF(NOW(), FROM_UNIXTIME(MAX(l.timecreated))) >= 7  THEN 'ALERTA_TEMPRANA'
        ELSE 'ACTIVO'
    END                                                                             AS estado_inactividad,
    gg.finalgrade                                                                   AS nota_final,
    CASE
        WHEN gg.finalgrade >= 51  THEN 'APROBADO'
        WHEN gg.finalgrade >= 40  THEN '2DA_INSTANCIA'
        WHEN gg.finalgrade >= 1   THEN 'REPROBADO'
        WHEN gg.finalgrade = 0    THEN 'REPROBADO_0'
        ELSE 'SIN_NOTA'
    END                                                                             AS estado_academico
FROM mdl_user_enrolments ue
JOIN mdl_enrol e        ON e.id = ue.enrolid AND e.courseid = 2
JOIN mdl_user u         ON u.id = ue.userid
LEFT JOIN mdl_logstore_standard_log l ON l.courseid = 2 AND l.userid = u.id
LEFT JOIN mdl_grade_items gi ON gi.courseid = 2 AND gi.itemtype = 'course'
LEFT JOIN mdl_grade_grades gg ON gg.itemid = gi.id AND gg.userid = u.id
WHERE ue.status = 0
GROUP BY u.id, u.username, u.firstname, u.lastname, gg.finalgrade
ORDER BY dias_inactivo DESC, u.lastname;

-- =======================================================
-- CONSULTA 3: Resumen de inactividad por estado
-- =======================================================
SELECT
    estado_inactividad,
    COUNT(*) AS cantidad,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS porcentaje
FROM (
    SELECT
        u.id,
        CASE
            WHEN MAX(l.timecreated) IS NULL THEN 'SIN_ACCESO'
            WHEN DATEDIFF(NOW(), FROM_UNIXTIME(MAX(l.timecreated))) >= 14 THEN 'ABANDONO_CRITICO'
            WHEN DATEDIFF(NOW(), FROM_UNIXTIME(MAX(l.timecreated))) >= 7  THEN 'ALERTA_TEMPRANA'
            ELSE 'ACTIVO'
        END AS estado_inactividad
    FROM mdl_user_enrolments ue
    JOIN mdl_enrol e ON e.id = ue.enrolid AND e.courseid = 2
    JOIN mdl_user u  ON u.id = ue.userid
    LEFT JOIN mdl_logstore_standard_log l ON l.courseid = 2 AND l.userid = u.id
    WHERE ue.status = 0
    GROUP BY u.id
) resumen
GROUP BY estado_inactividad
ORDER BY FIELD(estado_inactividad, 'ACTIVO','ALERTA_TEMPRANA','ABANDONO_CRITICO','SIN_ACCESO');

-- =======================================================
-- CONSULTA 4: Consolidar en bd_analitica_ava
-- =======================================================
INSERT INTO bd_analitica_ava.consolidado_semestral
    (id_curso_moodle, sigla_grupo, gestion, total_matriculados,
     total_aprobados, total_reprobados, total_segunda_instancia,
     total_sin_nota, total_abandono_critico, promedio_general, generado_por)
SELECT
    c.id,
    c.shortname,
    '2025-II',
    COUNT(DISTINCT ue.userid),
    COUNT(DISTINCT CASE WHEN gg.finalgrade >= 51 THEN ue.userid END),
    COUNT(DISTINCT CASE WHEN gg.finalgrade IS NOT NULL AND gg.finalgrade < 40 THEN ue.userid END),
    COUNT(DISTINCT CASE WHEN gg.finalgrade BETWEEN 40 AND 50 THEN ue.userid END),
    COUNT(DISTINCT CASE WHEN gg.finalgrade IS NULL THEN ue.userid END),
    COUNT(DISTINCT CASE WHEN DATEDIFF(NOW(), FROM_UNIXTIME(ultimo_acceso.max_ts)) >= 14 THEN ue.userid END),
    ROUND(AVG(CASE WHEN gg.finalgrade IS NOT NULL THEN gg.finalgrade END), 2),
    1
FROM mdl_course c
JOIN mdl_enrol e ON e.courseid = c.id
JOIN mdl_user_enrolments ue ON ue.enrolid = e.id AND ue.status = 0
LEFT JOIN mdl_grade_items gi ON gi.courseid = c.id AND gi.itemtype = 'course'
LEFT JOIN mdl_grade_grades gg ON gg.itemid = gi.id AND gg.userid = ue.userid
LEFT JOIN (
    SELECT userid, MAX(timecreated) AS max_ts
    FROM mdl_logstore_standard_log WHERE courseid = 2
    GROUP BY userid
) ultimo_acceso ON ultimo_acceso.userid = ue.userid
WHERE c.id = 2
GROUP BY c.id, c.shortname
ON DUPLICATE KEY UPDATE
    total_matriculados      = VALUES(total_matriculados),
    total_aprobados         = VALUES(total_aprobados),
    total_reprobados        = VALUES(total_reprobados),
    total_segunda_instancia = VALUES(total_segunda_instancia),
    promedio_general        = VALUES(promedio_general),
    fecha_consolidado       = CURRENT_TIMESTAMP;

-- =======================================================
-- Indices de performance (via stored procedure para compatibilidad)
-- =======================================================
DROP PROCEDURE IF EXISTS crear_indices_moodle;
DELIMITER //
CREATE PROCEDURE crear_indices_moodle()
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.STATISTICS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'mdl_logstore_standard_log'
          AND INDEX_NAME = 'idx_log_course_user_time'
    ) THEN
        CREATE INDEX idx_log_course_user_time
            ON mdl_logstore_standard_log(courseid, userid, timecreated);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.STATISTICS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'mdl_grade_grades'
          AND INDEX_NAME = 'idx_grade_user_item'
    ) THEN
        CREATE INDEX idx_grade_user_item ON mdl_grade_grades(userid, itemid);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.STATISTICS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'mdl_user_enrolments'
          AND INDEX_NAME = 'idx_enrol_status'
    ) THEN
        CREATE INDEX idx_enrol_status ON mdl_user_enrolments(enrolid, status, userid);
    END IF;
END //
DELIMITER ;
CALL crear_indices_moodle();
DROP PROCEDURE IF EXISTS crear_indices_moodle;

SELECT 'Consultas de validacion ejecutadas correctamente.' AS resultado;

