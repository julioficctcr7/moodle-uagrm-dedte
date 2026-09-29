# Moodle LMS Institucional U.A.G.R.M. (DEDTE)

> **Universidad Autónoma Gabriel René Moreno (U.A.G.R.M.)**  
> **Departamento de Educación a Distancia y Tecnología Educativa (DEDTE)**  
> **Versión de Moodle**: 5.1.1+ (Entorno Presencial y Virtual Oficial)  
> **Sustento Normativo**: Estatuto Orgánico de la UAGRM y Resolución ICU N° 053/2023.

---

## 🏛️ Contenido del Repositorio

Este repositorio contiene la configuración oficial y el desarrollo modular para el LMS Moodle de la UAGRM:

1. **`plugins/report_analitica_ava/`**: Plugin oficial de reporte analítico predictivo para cursos:
   - Integración nativa en la navegación del curso (`/report/analitica_ava/index.php`).
   - Widget flotante/incrustado de monitoreo directo en la cabecera del curso (`course/view.php`).
   - Métricas nominales según ICU 053/2023: Aprobados, Reprobados, **Segunda Instancia (Repechaje: 40-50 pts)** y Semáforo de Riesgo.
2. **`init-db/01_init_analitica.sql`**: Script de inicialización de base de datos con estructura de cursos, matriculaciones y réplica analítica.
3. **`docker-compose.yml`**: Orquestación de contenedores en Docker (Moodle App + MariaDB 11.8).
4. **`custom-php.ini`**: Ajustes de memoria y OPcache de alto rendimiento para soportar alta concurrencia universitaria.

---

## 🚀 Despliegue Rápido con Docker

```bash
# 1. Configurar variables de entorno
cp .env.example .env

# 2. Levantar Moodle LMS y MariaDB
docker compose up -d

# 3. Acceder al LMS
# URL: http://localhost:8080
# Usuario: admin | Contraseña: Admin1234!
```
