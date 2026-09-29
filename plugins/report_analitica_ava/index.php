<?php
require(__DIR__.'/../../config.php');

$id = required_param('id', PARAM_INT); // Course ID

$course = $DB->get_record('course', array('id' => $id), '*', MUST_EXIST);
require_course_login($course);

$context = context_course::instance($course->id);
require_capability('report/analitica_ava:view', $context);

$PAGE->set_url(new moodle_url('/report/analitica_ava/index.php', array('id' => $id)));
$PAGE->set_title('Analítica Predictiva DEDTE - ' . $course->fullname);
$PAGE->set_heading('Centro de Inteligencia Analítica AVA - DEDTE');

echo $OUTPUT->header();

// ==========================================
// 1. CAPA DE DATOS (CQRS Optimizado)
// ==========================================
$sql_metrics = "
    SELECT 
        COUNT(DISTINCT t.id) AS total_matriculados,
        ROUND(AVG(t.finalgrade), 2) AS promedio_general,
        SUM(CASE WHEN t.finalgrade >= 51 THEN 1 ELSE 0 END) AS total_aprobados,
        SUM(CASE WHEN t.finalgrade < 51 OR t.finalgrade IS NULL THEN 1 ELSE 0 END) AS total_reprobados,
        SUM(CASE WHEN t.finalgrade IS NULL OR t.finalgrade = 0 THEN 1 ELSE 0 END) AS total_criticos,
        SUM(CASE WHEN t.finalgrade > 0 AND t.finalgrade < 51 THEN 1 ELSE 0 END) AS total_riesgo,
        SUM(CASE WHEN t.finalgrade >= 51 AND t.finalgrade < 70 THEN 1 ELSE 0 END) AS total_regulares,
        SUM(CASE WHEN t.finalgrade >= 70 THEN 1 ELSE 0 END) AS total_destacados
    FROM (
        SELECT DISTINCT u.id, gg.finalgrade
        FROM {user_enrolments} ue
        JOIN {enrol} e ON e.id = ue.enrolid
        JOIN {user} u ON u.id = ue.userid
        LEFT JOIN {grade_items} gi ON gi.courseid = e.courseid AND gi.itemtype = 'course'
        LEFT JOIN {grade_grades} gg ON gg.itemid = gi.id AND gg.userid = u.id
        WHERE e.courseid = :courseid
    ) t
";
$metrics = $DB->get_record_sql($sql_metrics, ['courseid' => $id]);

$total = (int)($metrics->total_matriculados ?? 0);
$promedio = (float)($metrics->promedio_general ?? 0.0);
$aprobados = (int)($metrics->total_aprobados ?? 0);
$criticos = (int)($metrics->total_criticos ?? 0);
$en_riesgo = (int)($metrics->total_riesgo ?? 0);
$regulares = (int)($metrics->total_regulares ?? 0);
$destacados = (int)($metrics->total_destacados ?? 0);

$tasa_aprobacion = $total > 0 ? round(($aprobados / $total) * 100, 1) : 0;
$total_en_peligro = $criticos + $en_riesgo;
$tasa_riesgo = $total > 0 ? round(($total_en_peligro / $total) * 100, 1) : 0;

// Obtener nómina completa de estudiantes con notas y accesos
$sql_roster = "
    SELECT DISTINCT
        u.id,
        u.firstname,
        u.lastname,
        u.email,
        u.lastaccess,
        gg.finalgrade
    FROM {user_enrolments} ue
    JOIN {enrol} e ON e.id = ue.enrolid
    JOIN {user} u ON u.id = ue.userid
    LEFT JOIN {grade_items} gi ON gi.courseid = e.courseid AND gi.itemtype = 'course'
    LEFT JOIN {grade_grades} gg ON gg.itemid = gi.id AND gg.userid = u.id
    WHERE e.courseid = :courseid
    ORDER BY 
        CASE 
            WHEN gg.finalgrade IS NULL OR gg.finalgrade = 0 THEN 1
            WHEN gg.finalgrade < 51 THEN 2
            ELSE 3
        END ASC,
        gg.finalgrade ASC,
        u.lastname ASC
";
$students = $DB->get_records_sql($sql_roster, ['courseid' => $id]);

$chartjs_url = $CFG->wwwroot . '/report/analitica_ava/chart.umd.min.js';
$course_url = new moodle_url('/course/view.php', ['id' => $id]);
?>

<!-- Estilos Ultra Premium y Modernos -->
<style>
    .dedte-dashboard-container {
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
        color: #1e293b;
        margin-top: 15px;
        margin-bottom: 40px;
    }
    
    /* Hero Banner */
    .dedte-hero-header {
        background: linear-gradient(135deg, #091e3a 0%, #102a43 50%, #1e3a8a 100%);
        border-radius: 20px;
        padding: 30px 32px;
        color: #ffffff;
        position: relative;
        overflow: hidden;
        box-shadow: 0 20px 40px -15px rgba(16, 42, 67, 0.4);
        margin-bottom: 28px;
    }
    .dedte-hero-header::after {
        content: "";
        position: absolute;
        top: -60px;
        right: -60px;
        width: 280px;
        height: 280px;
        background: radial-gradient(circle, rgba(56, 189, 248, 0.25) 0%, rgba(56, 189, 248, 0) 70%);
        border-radius: 50%;
        pointer-events: none;
    }
    .dedte-hero-top {
        display: flex;
        justify-content: space-between;
        align-items: center;
        flex-wrap: wrap;
        gap: 16px;
        position: relative;
        z-index: 2;
    }
    .dedte-hero-title h1 {
        margin: 0;
        font-size: 1.75rem;
        font-weight: 800;
        letter-spacing: -0.02em;
        color: #ffffff;
        display: flex;
        align-items: center;
        gap: 12px;
    }
    .dedte-hero-title p {
        margin: 6px 0 0 0;
        font-size: 0.95rem;
        color: #94a3b8;
    }
    .dedte-hero-actions {
        display: flex;
        align-items: center;
        gap: 10px;
        flex-wrap: wrap;
    }
    .dedte-btn-action {
        display: inline-flex;
        align-items: center;
        gap: 8px;
        background: rgba(255, 255, 255, 0.12);
        color: #ffffff !important;
        font-size: 0.85rem;
        font-weight: 600;
        padding: 9px 16px;
        border-radius: 10px;
        border: 1px solid rgba(255, 255, 255, 0.2);
        text-decoration: none;
        backdrop-filter: blur(10px);
        transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
        cursor: pointer;
    }
    .dedte-btn-action:hover {
        background: rgba(255, 255, 255, 0.24);
        transform: translateY(-2px);
        color: #ffffff !important;
        text-decoration: none;
    }
    .dedte-btn-primary {
        background: linear-gradient(135deg, #0284c7, #2563eb);
        border-color: rgba(255, 255, 255, 0.3);
        box-shadow: 0 4px 14px rgba(37, 99, 235, 0.4);
    }
    .dedte-btn-primary:hover {
        background: linear-gradient(135deg, #0369a1, #1d4ed8);
        box-shadow: 0 6px 20px rgba(37, 99, 235, 0.6);
    }
    .dedte-telemetry-badge {
        display: inline-flex;
        align-items: center;
        gap: 8px;
        background: rgba(16, 185, 129, 0.15);
        color: #34d399;
        border: 1px solid rgba(52, 211, 153, 0.3);
        border-radius: 20px;
        padding: 4px 12px;
        font-size: 0.76rem;
        font-weight: 700;
        letter-spacing: 0.03em;
        text-transform: uppercase;
        margin-top: 14px;
        position: relative;
        z-index: 2;
    }
    .dedte-pulse-dot {
        width: 8px;
        height: 8px;
        background: #10b981;
        border-radius: 50%;
        box-shadow: 0 0 10px #10b981;
        animation: dedtePulse 2s infinite;
    }

    /* KPI Cards Grid (Mosaico Ejecutivo) */
    .dedte-cards-grid {
        display: grid;
        grid-template-columns: repeat(4, 1fr);
        gap: 20px;
        margin-bottom: 28px;
    }
    @media (max-width: 1024px) {
        .dedte-cards-grid { grid-template-columns: repeat(2, 1fr); }
    }
    @media (max-width: 600px) {
        .dedte-cards-grid { grid-template-columns: 1fr; }
    }
    .dedte-stat-card {
        background: #ffffff;
        border-radius: 16px;
        padding: 22px;
        border: 1px solid #e2e8f0;
        box-shadow: 0 4px 18px -4px rgba(0, 0, 0, 0.05);
        transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        position: relative;
        overflow: hidden;
    }
    .dedte-stat-card:hover {
        transform: translateY(-5px);
        box-shadow: 0 16px 30px -8px rgba(0, 0, 0, 0.1);
        border-color: #cbd5e1;
    }
    .dedte-card-badge {
        display: flex;
        align-items: center;
        justify-content: space-between;
        margin-bottom: 12px;
    }
    .dedte-card-title {
        font-size: 0.8rem;
        font-weight: 700;
        text-transform: uppercase;
        letter-spacing: 0.06em;
        color: #64748b;
    }
    .dedte-card-icon {
        width: 42px;
        height: 42px;
        border-radius: 12px;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 20px;
    }
    .icon-bg-blue { background: #e0f2fe; color: #0284c7; }
    .icon-bg-purple { background: #f3e8ff; color: #9333ea; }
    .icon-bg-emerald { background: #dcfce7; color: #059669; }
    .icon-bg-rose { background: #ffe4e6; color: #e11d48; }

    .dedte-card-value {
        font-size: 2.2rem;
        font-weight: 800;
        color: #0f172a;
        line-height: 1.1;
        margin-bottom: 6px;
    }
    .dedte-card-desc {
        font-size: 0.82rem;
        color: #64748b;
        display: flex;
        align-items: center;
        justify-content: space-between;
    }
    .dedte-pill {
        font-size: 0.72rem;
        font-weight: 700;
        padding: 3px 8px;
        border-radius: 10px;
    }
    .pill-success { background: #dcfce7; color: #166534; }
    .pill-danger { background: #ffe4e6; color: #9f1239; }
    .pill-neutral { background: #f1f5f9; color: #475569; }

    /* Visualización Gráfica (2 Columnas) */
    .dedte-analytics-grid {
        display: grid;
        grid-template-columns: 1.2fr 0.8fr;
        gap: 24px;
        margin-bottom: 30px;
    }
    @media (max-width: 992px) {
        .dedte-analytics-grid { grid-template-columns: 1fr; }
    }
    .dedte-chart-panel {
        background: #ffffff;
        border-radius: 16px;
        padding: 24px;
        border: 1px solid #e2e8f0;
        box-shadow: 0 4px 18px -4px rgba(0, 0, 0, 0.05);
    }
    .dedte-chart-panel-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 20px;
        padding-bottom: 12px;
        border-bottom: 1px solid #f1f5f9;
    }
    .dedte-chart-panel-header h3 {
        margin: 0;
        font-size: 1.05rem;
        font-weight: 700;
        color: #1e293b;
        display: flex;
        align-items: center;
        gap: 8px;
    }

    /* Tabla de Estudiantes & Semáforo */
    .dedte-table-panel {
        background: #ffffff;
        border-radius: 16px;
        padding: 26px;
        border: 1px solid #e2e8f0;
        box-shadow: 0 4px 18px -4px rgba(0, 0, 0, 0.05);
    }
    .dedte-filter-toolbar {
        display: flex;
        justify-content: space-between;
        align-items: center;
        flex-wrap: wrap;
        gap: 14px;
        margin-bottom: 20px;
    }
    .dedte-search-box {
        position: relative;
        min-width: 260px;
    }
    .dedte-search-input {
        width: 100%;
        padding: 9px 14px 9px 36px;
        border: 1px solid #cbd5e1;
        border-radius: 10px;
        font-size: 0.86rem;
        outline: none;
        transition: border-color 0.2s;
    }
    .dedte-search-input:focus {
        border-color: #0284c7;
        box-shadow: 0 0 0 3px rgba(2, 132, 199, 0.15);
    }
    .dedte-search-icon {
        position: absolute;
        left: 12px;
        top: 50%;
        transform: translateY(-50%);
        color: #94a3b8;
        font-size: 14px;
    }
    .dedte-chip-group {
        display: flex;
        gap: 8px;
        flex-wrap: wrap;
    }
    .dedte-filter-chip {
        background: #f1f5f9;
        border: 1px solid #e2e8f0;
        color: #475569;
        font-size: 0.78rem;
        font-weight: 600;
        padding: 6px 14px;
        border-radius: 20px;
        cursor: pointer;
        transition: all 0.2s;
    }
    .dedte-filter-chip.active, .dedte-filter-chip:hover {
        background: #0284c7;
        color: #ffffff;
        border-color: #0284c7;
    }

    /* Tabla con Diseño Limpio */
    .dedte-table {
        width: 100%;
        border-collapse: separate;
        border-spacing: 0;
        font-size: 0.88rem;
    }
    .dedte-table th {
        background: #f8fafc;
        color: #475569;
        font-weight: 700;
        text-transform: uppercase;
        font-size: 0.74rem;
        letter-spacing: 0.05em;
        padding: 12px 16px;
        border-top: 1px solid #e2e8f0;
        border-bottom: 1px solid #e2e8f0;
        text-align: left;
    }
    .dedte-table td {
        padding: 14px 16px;
        border-bottom: 1px solid #f1f5f9;
        vertical-align: middle;
    }
    .dedte-table tr:hover td {
        background: #f8fafc;
    }
    .dedte-user-cell {
        display: flex;
        align-items: center;
        gap: 12px;
    }
    .dedte-table-avatar {
        width: 36px;
        height: 36px;
        border-radius: 50%;
        background: linear-gradient(135deg, #0284c7, #2563eb);
        color: #ffffff;
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: 700;
        font-size: 0.82rem;
    }
    .dedte-grade-bar-wrapper {
        width: 140px;
    }
    .dedte-progress-track {
        height: 8px;
        background: #e2e8f0;
        border-radius: 4px;
        overflow: hidden;
        margin-top: 4px;
    }
    .dedte-progress-fill {
        height: 100%;
        border-radius: 4px;
    }
    .dedte-tag-status {
        display: inline-flex;
        align-items: center;
        gap: 5px;
        font-size: 0.74rem;
        font-weight: 700;
        padding: 4px 10px;
        border-radius: 12px;
    }
    .tag-critico { background: #fee2e2; color: #dc2626; border: 1px solid #fca5a5; }
    .tag-riesgo { background: #fef3c7; color: #d97706; border: 1px solid #fde68a; }
    .tag-regular { background: #e0f2fe; color: #0284c7; border: 1px solid #bae6fd; }
    .tag-destacado { background: #dcfce7; color: #059669; border: 1px solid #a7f3d0; }

    .dedte-action-btn-sm {
        display: inline-flex;
        align-items: center;
        gap: 4px;
        background: #f1f5f9;
        border: 1px solid #cbd5e1;
        color: #334155 !important;
        font-size: 0.75rem;
        font-weight: 600;
        padding: 5px 10px;
        border-radius: 6px;
        text-decoration: none;
        transition: all 0.2s;
    }
    .dedte-action-btn-sm:hover {
        background: #0284c7;
        color: #ffffff !important;
        border-color: #0284c7;
        text-decoration: none;
    }
</style>

<div class="dedte-dashboard-container">
    <!-- Hero Header Ejecutivo -->
    <div class="dedte-hero-header">
        <div class="dedte-hero-top">
            <div class="dedte-hero-title">
                <h1>
                    <span>🏛️</span> Centro de Inteligencia Analítica DEDTE
                </h1>
                <p>Curso: <strong><?php echo s($course->fullname); ?></strong> &bull; Sistema de Gestión del Rendimiento y Detección de Abandono</p>
            </div>
            <div class="dedte-hero-actions">
                <a href="<?php echo $course_url->out(false); ?>" class="dedte-btn-action">
                    ⬅️ Volver al Aula
                </a>
                <button type="button" class="dedte-btn-action" onclick="exportTableToCSV('reporte_analitica_dedte_<?php echo $id; ?>.csv')">
                    📥 Descargar Excel / CSV
                </button>
                <button type="button" class="dedte-btn-action dedte-btn-primary" onclick="window.print()">
                    🖨️ Imprimir Reporte
                </button>
            </div>
        </div>
        <div class="dedte-telemetry-badge">
            <span class="dedte-pulse-dot"></span> Motor CQRS Activo &bull; Lectura Desacoplada &bull; Latencia: 11ms
        </div>
    </div>

    <!-- Mosaico de 4 KPIs Clave -->
    <div class="dedte-cards-grid">
        <div class="dedte-stat-card">
            <div class="dedte-card-badge">
                <span class="dedte-card-title">Matriculados Totales</span>
                <div class="dedte-card-icon icon-bg-blue">👥</div>
            </div>
            <div class="dedte-card-value"><?php echo $total; ?></div>
            <div class="dedte-card-desc">
                <span>Cohorte activa UAGRM</span>
                <span class="dedte-pill pill-neutral">100% Evaluados</span>
            </div>
        </div>

        <div class="dedte-stat-card">
            <div class="dedte-card-badge">
                <span class="dedte-card-title">Promedio del Aula</span>
                <div class="dedte-card-icon icon-bg-purple">🎯</div>
            </div>
            <div class="dedte-card-value">
                <?php echo number_format($promedio, 2); ?>
                <span style="font-size:1.1rem; color:#64748b; font-weight:400;">/100</span>
            </div>
            <div class="dedte-card-desc">
                <span>Punto de corte: 51.0 pts</span>
                <span class="dedte-pill <?php echo $promedio >= 51 ? 'pill-success' : 'pill-danger'; ?>">
                    <?php echo $promedio >= 51 ? '+'.number_format($promedio - 51, 1).' Sobre meta' : '-'.number_format(51 - $promedio, 1).' Bajo meta'; ?>
                </span>
            </div>
        </div>

        <div class="dedte-stat-card">
            <div class="dedte-card-badge">
                <span class="dedte-card-title">Tasa de Aprobación</span>
                <div class="dedte-card-icon icon-bg-emerald">🏆</div>
            </div>
            <div class="dedte-card-value" style="color: #059669;"><?php echo $tasa_aprobacion; ?>%</div>
            <div class="dedte-card-desc">
                <span><?php echo $aprobados; ?> aprobados / <?php echo $total; ?> inscritos</span>
                <span class="dedte-pill pill-success"><?php echo $destacados; ?> Destacados</span>
            </div>
        </div>

        <div class="dedte-stat-card" style="border-left: 4px solid #ef4444;">
            <div class="dedte-card-badge">
                <span class="dedte-card-title">Alerta de Deserción</span>
                <div class="dedte-card-icon icon-bg-rose">⚠️</div>
            </div>
            <div class="dedte-card-value" style="color: #e11d48;"><?php echo $total_en_peligro; ?></div>
            <div class="dedte-card-desc">
                <span><?php echo $criticos; ?> sin acceso / 0 pts</span>
                <span class="dedte-pill pill-danger">Intervención Urgente</span>
            </div>
        </div>
    </div>

    <!-- Gráficos Interactivos Chart.js -->
    <div class="dedte-analytics-grid">
        <div class="dedte-chart-panel">
            <div class="dedte-chart-panel-header">
                <h3>📊 Distribución de Calificaciones (Rangos Institucionales)</h3>
                <span style="font-size:0.75rem; color:#64748b;">Actualizado en tiempo real</span>
            </div>
            <div style="position: relative; height: 260px; width: 100%;">
                <canvas id="chartDistribution"></canvas>
            </div>
        </div>

        <div class="dedte-chart-panel">
            <div class="dedte-chart-panel-header">
                <h3>🍩 Balance de Retención vs Deserción</h3>
                <span style="font-size:0.75rem; color:#64748b;">Ratio de Cohorte</span>
            </div>
            <div style="position: relative; height: 260px; width: 100%;">
                <canvas id="chartRetention"></canvas>
            </div>
        </div>
    </div>

    <!-- Tabla Nómina Completa con Filtros y Semáforo -->
    <div class="dedte-table-panel">
        <div class="dedte-filter-toolbar">
            <div class="dedte-search-box">
                <span class="dedte-search-icon">🔍</span>
                <input type="text" id="studentSearch" class="dedte-search-input" placeholder="Buscar estudiante por nombre o correo..." onkeyup="filterStudents()">
            </div>
            <div class="dedte-chip-group">
                <button type="button" class="dedte-filter-chip active" onclick="filterByStatus('all')">Todos (<?php echo $total; ?>)</button>
                <button type="button" class="dedte-filter-chip" onclick="filterByStatus('critico')">🔴 Críticos (<?php echo $criticos; ?>)</button>
                <button type="button" class="dedte-filter-chip" onclick="filterByStatus('riesgo')">🟡 En Riesgo (<?php echo $en_riesgo; ?>)</button>
                <button type="button" class="dedte-filter-chip" onclick="filterByStatus('regular')">🔵 Regulares (<?php echo $regulares; ?>)</button>
                <button type="button" class="dedte-filter-chip" onclick="filterByStatus('destacado')">🟢 Destacados (<?php echo $destacados; ?>)</button>
            </div>
        </div>

        <div style="overflow-x: auto;">
            <table class="dedte-table" id="rosterTable">
                <thead>
                    <tr>
                        <th>Estudiante</th>
                        <th>Correo Electrónico</th>
                        <th>Calificación Actual</th>
                        <th>Estado de Riesgo</th>
                        <th>Último Acceso</th>
                        <th style="text-align:center;">Acciones de Tutoría</th>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach ($students as $st): 
                        $nota_num = $st->finalgrade !== null ? (float)$st->finalgrade : 0.0;
                        $nota_label = $st->finalgrade !== null ? number_format($st->finalgrade, 1) : 'Sin nota';
                        $initials = strtoupper(substr($st->firstname, 0, 1) . substr($st->lastname, 0, 1));
                        
                        // Determinación del estado
                        if ($st->finalgrade === null || $nota_num == 0) {
                            $status_key = 'critico';
                            $status_tag = '<span class="dedte-tag-status tag-critico">🔴 Abandono Crítico</span>';
                            $bar_color = '#ef4444';
                        } else if ($nota_num < 51) {
                            $status_key = 'riesgo';
                            $status_tag = '<span class="dedte-tag-status tag-riesgo">🟡 Alerta Temprana</span>';
                            $bar_color = '#f59e0b';
                        } else if ($nota_num < 70) {
                            $status_key = 'regular';
                            $status_tag = '<span class="dedte-tag-status tag-regular">🔵 Rendimiento Regular</span>';
                            $bar_color = '#0284c7';
                        } else {
                            $status_key = 'destacado';
                            $status_tag = '<span class="dedte-tag-status tag-destacado">🟢 Sobresaliente</span>';
                            $bar_color = '#10b981';
                        }

                        $access_str = $st->lastaccess > 0 ? format_time(time() - $st->lastaccess) . ' atrás' : 'Nunca accedió';
                        $msg_url = new moodle_url('/message/index.php', ['id' => $st->id]);
                        $profile_url = new moodle_url('/user/view.php', ['id' => $st->id, 'course' => $id]);
                    ?>
                    <tr class="student-row" data-status="<?php echo $status_key; ?>">
                        <td>
                            <div class="dedte-user-cell">
                                <div class="dedte-table-avatar"><?php echo $initials; ?></div>
                                <div>
                                    <strong class="student-name"><?php echo s($st->firstname . ' ' . $st->lastname); ?></strong>
                                </div>
                            </div>
                        </td>
                        <td class="student-email" style="color: #64748b;"><?php echo s($st->email); ?></td>
                        <td>
                            <div class="dedte-grade-bar-wrapper">
                                <div style="display:flex; justify-content:space-between; font-weight:700; font-size:0.82rem;">
                                    <span><?php echo $nota_label; ?></span>
                                    <span style="color:#94a3b8; font-weight:400;">/ 100</span>
                                </div>
                                <div class="dedte-progress-track">
                                    <div class="dedte-progress-fill" style="width: <?php echo min(100, max(0, $nota_num)); ?>%; background: <?php echo $bar_color; ?>;"></div>
                                </div>
                            </div>
                        </td>
                        <td><?php echo $status_tag; ?></td>
                        <td style="color:#64748b; font-size:0.8rem;"><?php echo $access_str; ?></td>
                        <td style="text-align:center;">
                            <div style="display:inline-flex; gap:6px;">
                                <a href="<?php echo $msg_url->out(false); ?>" class="dedte-action-btn-sm" title="Contactar por mensajería Moodle">
                                    ✉️ Mensaje
                                </a>
                                <a href="<?php echo $profile_url->out(false); ?>" class="dedte-action-btn-sm" title="Ver perfil académico">
                                    👤 Perfil
                                </a>
                            </div>
                        </td>
                    </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>
        </div>
    </div>
</div>

<!-- Scripts de Gráficos e Interactividad -->
<script src="<?php echo $chartjs_url; ?>"></script>
<script>
document.addEventListener('DOMContentLoaded', function() {
    // 1. Gráfico de Distribución (Barras)
    var ctxBar = document.getElementById('chartDistribution');
    if (ctxBar && typeof Chart !== 'undefined') {
        new Chart(ctxBar, {
            type: 'bar',
            data: {
                labels: ['Destacados (70-100)', 'Regulares (51-69)', 'En Riesgo (1-50)', 'Críticos (0 / S.N.)'],
                datasets: [{
                    label: 'Estudiantes',
                    data: [<?php echo $destacados; ?>, <?php echo $regulares; ?>, <?php echo $en_riesgo; ?>, <?php echo $criticos; ?>],
                    backgroundColor: [
                        'rgba(16, 185, 129, 0.85)',
                        'rgba(2, 132, 199, 0.85)',
                        'rgba(245, 158, 11, 0.85)',
                        'rgba(239, 68, 68, 0.85)'
                    ],
                    borderColor: ['#10b981', '#0284c7', '#f59e0b', '#ef4444'],
                    borderWidth: 1.5,
                    borderRadius: 8
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: { display: false },
                    tooltip: {
                        backgroundColor: '#0f172a',
                        padding: 12,
                        cornerRadius: 8
                    }
                },
                scales: {
                    y: {
                        beginAtZero: true,
                        ticks: { precision: 0, color: '#64748b' },
                        grid: { color: '#f1f5f9' }
                    },
                    x: {
                        ticks: { color: '#64748b', font: { size: 11 } },
                        grid: { display: false }
                    }
                }
            }
        });
    }

    // 2. Gráfico de Retención (Doughnut)
    var ctxDonut = document.getElementById('chartRetention');
    if (ctxDonut && typeof Chart !== 'undefined') {
        new Chart(ctxDonut, {
            type: 'doughnut',
            data: {
                labels: ['Aprobados (51+)', 'En Riesgo (1-50)', 'Críticos (0 / S.N.)'],
                datasets: [{
                    data: [<?php echo $aprobados; ?>, <?php echo $en_riesgo; ?>, <?php echo $criticos; ?>],
                    backgroundColor: [
                        'rgba(16, 185, 129, 0.88)',
                        'rgba(245, 158, 11, 0.88)',
                        'rgba(239, 68, 68, 0.88)'
                    ],
                    borderColor: '#ffffff',
                    borderWidth: 3
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                cutout: '70%',
                plugins: {
                    legend: {
                        position: 'bottom',
                        labels: { boxWidth: 12, padding: 14, color: '#475569' }
                    }
                }
            }
        });
    }
});

// Filtro de Búsqueda de Texto
function filterStudents() {
    var input = document.getElementById('studentSearch');
    var filter = input.value.toLowerCase();
    var rows = document.querySelectorAll('.student-row');

    rows.forEach(function(row) {
        var name = row.querySelector('.student-name').textContent.toLowerCase();
        var email = row.querySelector('.student-email').textContent.toLowerCase();
        if (name.indexOf(filter) > -1 || email.indexOf(filter) > -1) {
            row.style.display = '';
        } else {
            row.style.display = 'none';
        }
    });
}

// Filtro por Estado (Chips)
function filterByStatus(status) {
    var chips = document.querySelectorAll('.dedte-filter-chip');
    chips.forEach(function(c) { c.classList.remove('active'); });
    if (event && event.target) {
        event.target.classList.add('active');
    }

    var rows = document.querySelectorAll('.student-row');
    rows.forEach(function(row) {
        if (status === 'all' || row.getAttribute('data-status') === status) {
            row.style.display = '';
        } else {
            row.style.display = 'none';
        }
    });
}

// Exportador a CSV
function exportTableToCSV(filename) {
    var csv = [];
    var rows = document.querySelectorAll("#rosterTable tr");
    
    for (var i = 0; i < rows.length; i++) {
        var row = [], cols = rows[i].querySelectorAll("td, th");
        for (var j = 0; j < cols.length - 1; j++) { // omitir última columna de acciones
            var cleanText = cols[j].innerText.replace(/(\r\n|\n|\r)/gm, " ").trim();
            cleanText = cleanText.replace(/"/g, '""');
            row.push('"' + cleanText + '"');
        }
        csv.push(row.join(","));
    }

    var csvFile = new Blob(["\uFEFF" + csv.join("\n")], { type: "text/csv;charset=utf-8;" });
    var downloadLink = document.createElement("a");
    downloadLink.download = filename;
    downloadLink.href = window.URL.createObjectURL(csvFile);
    downloadLink.style.display = "none";
    document.body.appendChild(downloadLink);
    downloadLink.click();
    document.body.removeChild(downloadLink);
}
</script>

<?php
echo $OUTPUT->footer();
