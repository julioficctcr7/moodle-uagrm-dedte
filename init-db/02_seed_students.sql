-- =======================================================
-- Script 02: Semillero de Estudiantes y Calificaciones
-- =======================================================
-- PROPOSITO: El archivo .mbz tiene sufijo -nu (No Users).
-- Este script simula 40 estudiantes matriculados al curso
-- restaurado (ID=2 por defecto) con notas reales distribuidas
-- segun el esquema de calificacion de la UAGRM:
--   >= 51 = APROBADO
--   40-50 = SEGUNDA INSTANCIA
--   1-39  = REPROBADO
--   0     = REPROBADO CON 0
--
-- EJECUTAR DESPUES de restaurar el .mbz:
--   docker exec moodle_uagrm_db mysql -u root -prootpass2024 moodle < /tmp/seed.sql
-- =======================================================

USE moodle;

-- -------------------------------------------------------
-- Variables de configuracion (ajustar si cambia el ID del curso)
-- -------------------------------------------------------
SET @course_id = 2;
SET @category_id = 1;

-- -------------------------------------------------------
-- PASO 1: Crear 40 usuarios de prueba
-- -------------------------------------------------------
INSERT IGNORE INTO mdl_user
(id, auth, confirmed, username, password, firstname, lastname, email, lang, timezone, timecreated, timemodified, mnethostid, institution, department, city, country)
VALUES
(101,'manual',1,'est001',MD5('Est001Pass!'),'Ana','Garcia Lopez','est001@uagrm-test.edu.bo','es','America/La_Paz',UNIX_TIMESTAMP(),UNIX_TIMESTAMP(),1,'UAGRM','Derecho','Santa Cruz','BO'),
(102,'manual',1,'est002',MD5('Est002Pass!'),'Carlos','Mendez Rojas','est002@uagrm-test.edu.bo','es','America/La_Paz',UNIX_TIMESTAMP(),UNIX_TIMESTAMP(),1,'UAGRM','Derecho','Santa Cruz','BO'),
(103,'manual',1,'est003',MD5('Est003Pass!'),'Maria','Flores Perez','est003@uagrm-test.edu.bo','es','America/La_Paz',UNIX_TIMESTAMP(),UNIX_TIMESTAMP(),1,'UAGRM','Derecho','Santa Cruz','BO'),
(104,'manual',1,'est004',MD5('Est004Pass!'),'Luis','Vargas Torrez','est004@uagrm-test.edu.bo','es','America/La_Paz',UNIX_TIMESTAMP(),UNIX_TIMESTAMP(),1,'UAGRM','Derecho','Santa Cruz','BO'),
(105,'manual',1,'est005',MD5('Est005Pass!'),'Sofia','Mamani Quispe','est005@uagrm-test.edu.bo','es','America/La_Paz',UNIX_TIMESTAMP(),UNIX_TIMESTAMP(),1,'UAGRM','Derecho','Santa Cruz','BO'),
(106,'manual',1,'est006',MD5('Est006Pass!'),'Diego','Condori Alcon','est006@uagrm-test.edu.bo','es','America/La_Paz',UNIX_TIMESTAMP(),UNIX_TIMESTAMP(),1,'UAGRM','Derecho','Santa Cruz','BO'),
(107,'manual',1,'est007',MD5('Est007Pass!'),'Valentina','Cruz Pinto','est007@uagrm-test.edu.bo','es','America/La_Paz',UNIX_TIMESTAMP(),UNIX_TIMESTAMP(),1,'UAGRM','Derecho','Santa Cruz','BO'),
(108,'manual',1,'est008',MD5('Est008Pass!'),'Andres','Salazar Roca','est008@uagrm-test.edu.bo','es','America/La_Paz',UNIX_TIMESTAMP(),UNIX_TIMESTAMP(),1,'UAGRM','Derecho','Santa Cruz','BO'),
(109,'manual',1,'est009',MD5('Est009Pass!'),'Camila','Suarez Vaca','est009@uagrm-test.edu.bo','es','America/La_Paz',UNIX_TIMESTAMP(),UNIX_TIMESTAMP(),1,'UAGRM','Derecho','Santa Cruz','BO'),
(110,'manual',1,'est010',MD5('Est010Pass!'),'Pablo','Ibañez Soria','est010@uagrm-test.edu.bo','es','America/La_Paz',UNIX_TIMESTAMP(),UNIX_TIMESTAMP(),1,'UAGRM','Derecho','Santa Cruz','BO'),
(111,'manual',1,'est011',MD5('Est011Pass!'),'Laura','Arze Montero','est011@uagrm-test.edu.bo','es','America/La_Paz',UNIX_TIMESTAMP(),UNIX_TIMESTAMP(),1,'UAGRM','Derecho','Santa Cruz','BO'),
(112,'manual',1,'est012',MD5('Est012Pass!'),'Roberto','Camacho Vera','est012@uagrm-test.edu.bo','es','America/La_Paz',UNIX_TIMESTAMP(),UNIX_TIMESTAMP(),1,'UAGRM','Derecho','Santa Cruz','BO'),
(113,'manual',1,'est013',MD5('Est013Pass!'),'Patricia','Delgado Reyes','est013@uagrm-test.edu.bo','es','America/La_Paz',UNIX_TIMESTAMP(),UNIX_TIMESTAMP(),1,'UAGRM','Derecho','Santa Cruz','BO'),
(114,'manual',1,'est014',MD5('Est014Pass!'),'Fernando','Montaño Paz','est014@uagrm-test.edu.bo','es','America/La_Paz',UNIX_TIMESTAMP(),UNIX_TIMESTAMP(),1,'UAGRM','Derecho','Santa Cruz','BO'),
(115,'manual',1,'est015',MD5('Est015Pass!'),'Gabriela','Aguilar Blanco','est015@uagrm-test.edu.bo','es','America/La_Paz',UNIX_TIMESTAMP(),UNIX_TIMESTAMP(),1,'UAGRM','Derecho','Santa Cruz','BO'),
(116,'manual',1,'est016',MD5('Est016Pass!'),'Marco','Rivero Cuellar','est016@uagrm-test.edu.bo','es','America/La_Paz',UNIX_TIMESTAMP(),UNIX_TIMESTAMP(),1,'UAGRM','Derecho','Santa Cruz','BO'),
(117,'manual',1,'est017',MD5('Est017Pass!'),'Elena','Pardo Zurita','est017@uagrm-test.edu.bo','es','America/La_Paz',UNIX_TIMESTAMP(),UNIX_TIMESTAMP(),1,'UAGRM','Derecho','Santa Cruz','BO'),
(118,'manual',1,'est018',MD5('Est018Pass!'),'Juan','Teran Herbas','est018@uagrm-test.edu.bo','es','America/La_Paz',UNIX_TIMESTAMP(),UNIX_TIMESTAMP(),1,'UAGRM','Derecho','Santa Cruz','BO'),
(119,'manual',1,'est019',MD5('Est019Pass!'),'Daniela','Nogales Vedia','est019@uagrm-test.edu.bo','es','America/La_Paz',UNIX_TIMESTAMP(),UNIX_TIMESTAMP(),1,'UAGRM','Derecho','Santa Cruz','BO'),
(120,'manual',1,'est020',MD5('Est020Pass!'),'Ricardo','Seoane Gutierrez','est020@uagrm-test.edu.bo','es','America/La_Paz',UNIX_TIMESTAMP(),UNIX_TIMESTAMP(),1,'UAGRM','Derecho','Santa Cruz','BO'),
(121,'manual',1,'est021',MD5('Est021Pass!'),'Isabella','Quiroga Antelo','est021@uagrm-test.edu.bo','es','America/La_Paz',UNIX_TIMESTAMP(),UNIX_TIMESTAMP(),1,'UAGRM','Derecho','Santa Cruz','BO'),
(122,'manual',1,'est022',MD5('Est022Pass!'),'Mateo','Pizarro Sandoval','est022@uagrm-test.edu.bo','es','America/La_Paz',UNIX_TIMESTAMP(),UNIX_TIMESTAMP(),1,'UAGRM','Derecho','Santa Cruz','BO'),
(123,'manual',1,'est023',MD5('Est023Pass!'),'Natalia','Hurtado Romero','est023@uagrm-test.edu.bo','es','America/La_Paz',UNIX_TIMESTAMP(),UNIX_TIMESTAMP(),1,'UAGRM','Derecho','Santa Cruz','BO'),
(124,'manual',1,'est024',MD5('Est024Pass!'),'Sebastian','Lara Baldivia','est024@uagrm-test.edu.bo','es','America/La_Paz',UNIX_TIMESTAMP(),UNIX_TIMESTAMP(),1,'UAGRM','Derecho','Santa Cruz','BO'),
(125,'manual',1,'est025',MD5('Est025Pass!'),'Valeria','Molina Campos','est025@uagrm-test.edu.bo','es','America/La_Paz',UNIX_TIMESTAMP(),UNIX_TIMESTAMP(),1,'UAGRM','Derecho','Santa Cruz','BO'),
(126,'manual',1,'est026',MD5('Est026Pass!'),'Javier','Antezana Burgoa','est026@uagrm-test.edu.bo','es','America/La_Paz',UNIX_TIMESTAMP(),UNIX_TIMESTAMP(),1,'UAGRM','Derecho','Santa Cruz','BO'),
(127,'manual',1,'est027',MD5('Est027Pass!'),'Renata','Barrero Justiniano','est027@uagrm-test.edu.bo','es','America/La_Paz',UNIX_TIMESTAMP(),UNIX_TIMESTAMP(),1,'UAGRM','Derecho','Santa Cruz','BO'),
(128,'manual',1,'est028',MD5('Est028Pass!'),'Alejandro','Medrano Claure','est028@uagrm-test.edu.bo','es','America/La_Paz',UNIX_TIMESTAMP(),UNIX_TIMESTAMP(),1,'UAGRM','Derecho','Santa Cruz','BO'),
(129,'manual',1,'est029',MD5('Est029Pass!'),'Lucia','Centellas Aviles','est029@uagrm-test.edu.bo','es','America/La_Paz',UNIX_TIMESTAMP(),UNIX_TIMESTAMP(),1,'UAGRM','Derecho','Santa Cruz','BO'),
(130,'manual',1,'est030',MD5('Est030Pass!'),'Emilio','Parada Saravia','est030@uagrm-test.edu.bo','es','America/La_Paz',UNIX_TIMESTAMP(),UNIX_TIMESTAMP(),1,'UAGRM','Derecho','Santa Cruz','BO'),
(131,'manual',1,'est031',MD5('Est031Pass!'),'Mariana','Torrico Fuentes','est031@uagrm-test.edu.bo','es','America/La_Paz',UNIX_TIMESTAMP(),UNIX_TIMESTAMP(),1,'UAGRM','Derecho','Santa Cruz','BO'),
(132,'manual',1,'est032',MD5('Est032Pass!'),'Nicolas','Espinoza Melgar','est032@uagrm-test.edu.bo','es','America/La_Paz',UNIX_TIMESTAMP(),UNIX_TIMESTAMP(),1,'UAGRM','Derecho','Santa Cruz','BO'),
(133,'manual',1,'est033',MD5('Est033Pass!'),'Florencia','Vasquez Callaú','est033@uagrm-test.edu.bo','es','America/La_Paz',UNIX_TIMESTAMP(),UNIX_TIMESTAMP(),1,'UAGRM','Derecho','Santa Cruz','BO'),
(134,'manual',1,'est034',MD5('Est034Pass!'),'Gabriel','Ortiz Peralta','est034@uagrm-test.edu.bo','es','America/La_Paz',UNIX_TIMESTAMP(),UNIX_TIMESTAMP(),1,'UAGRM','Derecho','Santa Cruz','BO'),
(135,'manual',1,'est035',MD5('Est035Pass!'),'Camilo','Alvarado Navia','est035@uagrm-test.edu.bo','es','America/La_Paz',UNIX_TIMESTAMP(),UNIX_TIMESTAMP(),1,'UAGRM','Derecho','Santa Cruz','BO'),
(136,'manual',1,'est036',MD5('Est036Pass!'),'Constanza','Zabala Rocha','est036@uagrm-test.edu.bo','es','America/La_Paz',UNIX_TIMESTAMP(),UNIX_TIMESTAMP(),1,'UAGRM','Derecho','Santa Cruz','BO'),
(137,'manual',1,'est037',MD5('Est037Pass!'),'Tomas','Villarroel Carrasco','est037@uagrm-test.edu.bo','es','America/La_Paz',UNIX_TIMESTAMP(),UNIX_TIMESTAMP(),1,'UAGRM','Derecho','Santa Cruz','BO'),
(138,'manual',1,'est038',MD5('Est038Pass!'),'Agustina','Roca Miranda','est038@uagrm-test.edu.bo','es','America/La_Paz',UNIX_TIMESTAMP(),UNIX_TIMESTAMP(),1,'UAGRM','Derecho','Santa Cruz','BO'),
(139,'manual',1,'est039',MD5('Est039Pass!'),'Rodrigo','Soliz Bascope','est039@uagrm-test.edu.bo','es','America/La_Paz',UNIX_TIMESTAMP(),UNIX_TIMESTAMP(),1,'UAGRM','Derecho','Santa Cruz','BO'),
(140,'manual',1,'est040',MD5('Est040Pass!'),'Antonella','Ledezma Irahola','est040@uagrm-test.edu.bo','es','America/La_Paz',UNIX_TIMESTAMP(),UNIX_TIMESTAMP(),1,'UAGRM','Derecho','Santa Cruz','BO');

-- -------------------------------------------------------
-- PASO 2: Crear metodo de inscripcion manual en el curso
-- -------------------------------------------------------
INSERT IGNORE INTO mdl_enrol (id, enrol, status, courseid, sortorder, timecreated, timemodified)
VALUES (201, 'manual', 0, @course_id, 0, UNIX_TIMESTAMP(), UNIX_TIMESTAMP());

-- -------------------------------------------------------
-- PASO 3: Matricular los 40 estudiantes al curso
-- -------------------------------------------------------
INSERT IGNORE INTO mdl_user_enrolments (enrolid, userid, modifierid, timestart, timeend, timecreated, timemodified, status)
SELECT 201, u.id, 2, UNIX_TIMESTAMP()-5184000, 0, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 0
FROM mdl_user u WHERE u.id BETWEEN 101 AND 140;

-- -------------------------------------------------------
-- PASO 4: Insertar calificaciones finales (escala UAGRM 0-100)
-- Distribucion: 55% Aprobados, 15% 2da Instancia, 20% Reprobados, 10% Sin nota/0
-- -------------------------------------------------------
-- Primero necesitamos el grade_item del curso
INSERT IGNORE INTO mdl_grade_items (courseid, categoryid, itemtype, itemmodule, iteminstance, itemnumber, gradetype, grademax, grademin, scaleid, timecreated, timemodified)
VALUES (@course_id, NULL, 'course', NULL, @course_id, 0, 1, 100, 0, 0, UNIX_TIMESTAMP(), UNIX_TIMESTAMP());

-- Calificaciones simuladas
INSERT IGNORE INTO mdl_grade_grades (itemid, userid, rawgrade, finalgrade, timemodified)
SELECT
    gi.id,
    u.id,
    CASE
        WHEN u.id IN (101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122) THEN
            -- Aprobados: notas entre 51 y 95
            51 + ((u.id - 101) * 2)
        WHEN u.id IN (123,124,125,126,127,128) THEN
            -- Segunda instancia: notas entre 40 y 50
            40 + (u.id - 123)
        WHEN u.id IN (129,130,131,132,133,134,135,136) THEN
            -- Reprobados: notas entre 5 y 35
            5 + ((u.id - 129) * 4)
        WHEN u.id IN (137,138) THEN
            -- Reprobados con 0
            0
        ELSE NULL  -- Sin nota (139, 140)
    END,
    CASE
        WHEN u.id IN (101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122) THEN
            51 + ((u.id - 101) * 2)
        WHEN u.id IN (123,124,125,126,127,128) THEN
            40 + (u.id - 123)
        WHEN u.id IN (129,130,131,132,133,134,135,136) THEN
            5 + ((u.id - 129) * 4)
        WHEN u.id IN (137,138) THEN 0
        ELSE NULL
    END,
    UNIX_TIMESTAMP()
FROM mdl_grade_items gi, mdl_user u
WHERE gi.courseid = @course_id AND gi.itemtype = 'course'
  AND u.id BETWEEN 101 AND 140;

-- -------------------------------------------------------
-- PASO 5: Generar registros de acceso al log (para consultas de inactividad)
-- Algunos activos, algunos con abandono critico (> 14 dias sin entrar)
-- -------------------------------------------------------
INSERT IGNORE INTO mdl_logstore_standard_log
    (eventname, component, action, target, objecttable, objectid, crud, edulevel, contextid, contextlevel, contextinstanceid, userid, courseid, relateduserid, anonymous, other, timecreated, origin, ip, realuserid)
SELECT
    '\core\event\course_viewed', 'core', 'viewed', 'course', 'course', @course_id, 'r', 2, 5975, 50, @course_id,
    u.id, @course_id, NULL, 0, NULL,
    CASE
        -- Activos (ultimos 3 dias)
        WHEN u.id BETWEEN 101 AND 110 THEN UNIX_TIMESTAMP() - (u.id - 100) * 86400
        -- Alerta temprana (7-13 dias)
        WHEN u.id BETWEEN 111 AND 120 THEN UNIX_TIMESTAMP() - (7 + (u.id - 111)) * 86400
        -- Abandono critico (>= 14 dias)
        WHEN u.id BETWEEN 121 AND 136 THEN UNIX_TIMESTAMP() - (14 + (u.id - 121)) * 86400
        -- Sin acceso registrado (omitir - no insertar)
        ELSE UNIX_TIMESTAMP() - 30 * 86400
    END,
    'web', '10.0.0.1', NULL
FROM mdl_user u WHERE u.id BETWEEN 101 AND 136;

-- -------------------------------------------------------
-- PASO 6: Asignar rol de estudiante a todos en el curso
-- (Role ID 5 = student en Moodle por defecto)
-- -------------------------------------------------------
INSERT IGNORE INTO mdl_role_assignments (roleid, contextid, userid, timemodified, modifierid)
SELECT 5, 5975, u.id, UNIX_TIMESTAMP(), 2
FROM mdl_user u WHERE u.id BETWEEN 101 AND 140;

-- -------------------------------------------------------
-- VERIFICACION FINAL
-- -------------------------------------------------------
SELECT 'Usuarios creados:' AS info, COUNT(*) AS total FROM mdl_user WHERE id BETWEEN 101 AND 140;
SELECT 'Matriculados al curso:' AS info, COUNT(*) AS total FROM mdl_user_enrolments WHERE enrolid = 201;
SELECT 'Calificaciones insertadas:' AS info, COUNT(*) AS total FROM mdl_grade_grades gg JOIN mdl_grade_items gi ON gi.id = gg.itemid WHERE gi.courseid = @course_id AND gi.itemtype = 'course';
SELECT 'Registros de log:' AS info, COUNT(*) AS total FROM mdl_logstore_standard_log WHERE courseid = @course_id;
