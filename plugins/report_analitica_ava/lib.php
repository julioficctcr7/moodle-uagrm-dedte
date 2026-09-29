<?php
defined('MOODLE_INTERNAL') || die;

/**
 * Agrega el reporte a la navegación secundaria del curso (La barra de pestañas)
 */
function report_analitica_ava_extend_navigation_course($navigation, $course, $context) {
    if (has_capability('report/analitica_ava:view', $context)) {
        $url = new moodle_url('/report/analitica_ava/index.php', array('id' => $course->id));
        $navigation->add(
            get_string('pluginname', 'report_analitica_ava'),
            $url,
            navigation_node::TYPE_SETTING,
            null,
            'report_analitica_ava',
            new pix_icon('i/report', '')
        );
    }
}
