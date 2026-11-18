# Cloud Provider Analytics

Proyecto Integrador de **Minería de Datos II — ISTEA**.

**Integrante:** Nicolás Granata

## Objetivo

Cloud Provider Analytics representa un pipeline de datos para un proveedor de servicios cloud.

El objetivo es integrar fuentes batch y eventos de utilización, organizar la información mediante un Data Lake y generar productos analíticos orientados principalmente a:

- FinOps;
- Soporte;
- Producto / Usage.

La arquitectura implementada sigue el flujo:

**Fuentes → Landing → Bronze → Silver → Gold → Serving**

Apache Spark / PySpark se utiliza como motor principal de procesamiento y DataStax AstraDB como capa de serving para los productos analíticos implementados.

---

## Evolución del proyecto

El proyecto se desarrolla de forma acumulativa durante las distintas instancias de evaluación.

### Evaluación 1 — Diseño y fundación

La primera evaluación estableció la base conceptual y arquitectónica:

- interpretación del problema y usuarios;
- análisis de las 5V de Big Data;
- inventario y perfil inicial de las fuentes;
- diseño Landing / Bronze / Silver / Gold;
- selección del patrón Lambda;
- diseño de flujos batch y streaming;
- ejemplo de procesamiento mediante lógica MapReduce;
- supuestos, riesgos y mitigaciones;
- decisiones iniciales de arquitectura.

Notebook:

`notebooks/01_evaluacion_1_fundacion.ipynb`

### Evaluación 2 — MVP técnico end-to-end

La segunda evaluación transforma ese diseño en una implementación ejecutable:

- ingesta batch hacia Bronze;
- Structured Streaming hacia Bronze;
- esquema explícito;
- watermark;
- deduplicación por `event_id`;
- checkpoints;
- reglas de calidad;
- quarantine;
- Silver conformado y enriquecido;
- features analíticas;
- mart Gold FinOps;
- evaluación de particionamiento;
- analítica de anomalías;
- serving en Cassandra / AstraDB;
- consultas CQL;
- pruebas de idempotencia;
- gobierno y linaje preliminar;
- evidencia reproducible.

Notebook:

`notebooks/02_evaluacion_2_mvp.ipynb`

---

## Tecnologías

- Google Colab
- Python
- Apache Spark / PySpark 4.0.4
- Spark DataFrames
- Spark Structured Streaming
- CSV
- JSON Lines / JSONL
- Parquet
- Cassandra / DataStax AstraDB
- CQL
- Git / GitHub

---

## Arquitectura implementada

La solución mantiene un patrón **Lambda**, utilizando caminos diferentes según la naturaleza de las fuentes.

```text
FUENTES
  ├── CSV batch
  └── usage_events_stream/*.jsonl
            │
            ▼
         LANDING
            │
      ┌─────┴─────────────┐
      │                   │
      ▼                   ▼
 PySpark batch      Structured Streaming
 esquema explícito  esquema + watermark
 metadata           dedupe + checkpoint
      │                   │
      └───────┬───────────┘
              ▼
            BRONZE
           Parquet
              │
              ▼
            SILVER
   calidad + quarantine
   features + enrichment
              │
              ▼
             GOLD
 org_daily_usage_by_service
              │
              ▼
      Cassandra / AstraDB
              │
              ▼
        Consultas CQL
```

Las capacidades transversales incluyen metadata técnica, controles de calidad, linaje, idempotencia, checkpoints y manejo seguro de credenciales.

---

## Data Lake

La implementación utiliza las siguientes zonas:

### Landing

Contiene los archivos originales provistos por la cátedra.

Landing se considera inmutable.

### Bronze

Conserva el grano original pero incorpora:

- esquema explícito;
- tipificación controlada;
- `source_file`;
- `ingest_ts`;
- deduplicación cuando corresponde;
- particionamiento.

### Silver

Contiene información preparada para consumo analítico:

- normalización;
- reglas de calidad;
- casting controlado;
- features;
- enriquecimiento con maestros;
- compatibilidad entre versiones de esquema.

### Gold

Contiene productos analíticos agregados.

En E2 se implementa:

`org_daily_usage_by_service`

con grano:

`org_id + usage_date + service`

### Quarantine

Los registros que no superan las reglas de promoción se almacenan separadamente junto con el motivo de rechazo.

---

## Fuentes

El dataset provisto por la cátedra contiene siete fuentes CSV y eventos JSONL:

- `customers_orgs.csv`
- `users.csv`
- `resources.csv`
- `support_tickets.csv`
- `marketing_touches.csv`
- `nps_surveys.csv`
- `billing_monthly.csv`
- `usage_events_stream/*.jsonl`

En la ejecución de E2 se procesaron:

- **7 archivos CSV**
- **120 archivos JSONL**
- **43.200 eventos de utilización**

El dataset completo no se versiona en este repositorio.

---

## Resultados principales de E2

La ejecución completa produjo:

| Evidencia | Resultado |
|---|---:|
| Customers Bronze | 80 |
| Users Bronze | 800 |
| Billing Bronze | 240 |
| Eventos Streaming Bronze | 43.200 |
| `event_id` distintos en Bronze | 43.200 |
| Watermark seleccionado | 86.400 min / 60 días |
| Eventos descartados por watermark | 0 |
| Registros enviados a quarantine | 2.038 |
| Eventos promovidos a Silver | 41.162 |
| Customers Silver | 80 |
| Filas del mart Gold | 11.050 |
| Claves duplicadas en Gold | 0 |
| Filas cargadas mediante upsert en AstraDB | 11.050 |
| Consulta CQL de rango | 60 filas |
| Consulta CQL de últimos registros | 10 filas |

Los **11.050 registros de Gold** coinciden con los 11.050 grupos obtenidos durante E1 mediante la lógica batch de referencia para:

`org_id + usage_date + service`

---

## Decisión de watermark

El watermark quedó abierto durante E1 y fue evaluado con evidencia en E2.

Se compararon tolerancias de:

- 120 minutos;
- 1 día;
- 7 días;
- 30 días;
- 60 días.

El dataset académico no posee un timestamp real de llegada y los archivos JSONL no representan un orden cronológico estricto.

Para evitar descartar artificialmente eventos válidos se seleccionó:

**86.400 minutos / 60 días**

Esta configuración permitió procesar los **43.200 eventos** sin descartes por watermark.

El valor corresponde únicamente al MVP académico y debería recalibrarse en un entorno productivo utilizando lateness real.

---

## Calidad y quarantine

Entre las reglas implementadas se encuentran:

- `event_id` obligatorio;
- `unit` obligatorio cuando existe `value`;
- validación de conversión numérica de `value`;
- flag de anomalía cuando `cost_usd_increment < -0.01`.

Los registros que no cumplen las reglas de promoción se almacenan en quarantine.

Resultado E2:

**2.038 registros en quarantine**

---

## Analítica

Como componente analítico se implementó detección simple y explicable de spikes de costo mediante **percentil 99 por servicio**.

El cálculo se realiza sobre Silver para respetar las diferentes escalas de costo entre servicios.

---

## Particionamiento

Durante E2 se compararon distintas alternativas para Gold:

| Estrategia | Archivos Parquet |
|---|---:|
| Sin partición | 1 |
| Por mes | 2 |
| Por fecha | 60 |
| Por fecha + servicio | 360 |

Para el MVP se seleccionó partición por:

`usage_month`

porque mantiene una dimensión temporal útil sin generar la fragmentación observada en las alternativas diarias.

---

## Serving en AstraDB

El mart Gold se publica en DataStax AstraDB.

Keyspace utilizado:

`cloud_provider_analytics`

Tabla query-first:

`org_daily_usage_by_service`

Clave primaria:

```sql
PRIMARY KEY ((org_id, service), usage_date)
```

El diseño permite consultar eficientemente una organización y servicio a través del tiempo.

El script utilizado se encuentra en:

`cql/02_evaluacion_2.cql`

---

## Idempotencia

E2 incluye pruebas explícitas de re-ejecución.

Resultados:

| Prueba | Resultado |
|---|---|
| Batch → Bronze | Correcta |
| Streaming con mismo checkpoint | Correcta |
| Deduplicación controlada | Correcta |
| Upserts en AstraDB | Correcta |

La re-ejecución no incrementó indebidamente los conteos.

---

## Estructura del repositorio

```text
cloud-provider-analytics/
│
├── README.md
├── DECISIONS.md
├── .gitignore
│
├── notebooks/
│   ├── 01_evaluacion_1_fundacion.ipynb
│   └── 02_evaluacion_2_mvp.ipynb
│
├── cql/
│   └── 02_evaluacion_2.cql
│
├── docs/
│   ├── README.md
│   ├── evaluacion_1.pdf
│   ├── arquitectura_v1.png
│   └── arquitectura_v2.png
│
├── data/
│   └── README.md
│
└── evidence/
    ├── README.md
    └── e2_summary.json
```

Las salidas completas Bronze, Silver, Gold y quarantine no se versionan debido a que son regenerables desde el dataset original y producen miles de archivos físicos.

La ejecución E2 generó aproximadamente **46,31 MB distribuidos en 12.648 archivos** entre esas capas.

---

# Quickstart — Evaluación 2

## Requisitos

Se necesita:

- una cuenta de Google para utilizar Google Colab;
- el dataset `cloud_provider_challenge_dataset_v1.zip` provisto por la cátedra;
- una base DataStax AstraDB;
- el keyspace `cloud_provider_analytics`;
- un Application Token de AstraDB;
- el Secure Connect Bundle de la base.

Las credenciales no deben almacenarse en GitHub.

## Ejecución

1. Abrir `notebooks/02_evaluacion_2_mvp.ipynb` en Google Colab.
2. Ejecutar las celdas en orden.
3. Cuando Colab lo solicite, cargar `cloud_provider_challenge_dataset_v1.zip`.
4. Verificar la ingesta Batch → Bronze.
5. Ejecutar Structured Streaming hasta completar `availableNow`.
6. Revisar la evidencia del watermark.
7. Ejecutar calidad y generar quarantine.
8. Generar Silver.
9. Construir Gold.
10. Ejecutar la comparación de particionamiento.
11. En AstraDB, disponer del keyspace `cloud_provider_analytics`.
12. Cuando Colab lo solicite, cargar el Secure Connect Bundle `.zip`.
13. Ingresar el Application Token mediante el campo oculto.
14. Ejecutar la carga del mart hacia AstraDB.
15. Ejecutar las dos consultas CQL.
16. Ejecutar las pruebas de idempotencia.
17. Revisar el resumen consolidado de evidencia.

## Ejecución desde un entorno limpio

Google Colab utiliza almacenamiento temporal.

Para una ejecución completamente nueva puede eliminarse:

`/content/cloud_provider_e2`

antes de comenzar.

El dataset original debe volver a cargarse.

Para demostrar la idempotencia del streaming **no debe eliminarse el checkpoint** entre la primera ejecución y la prueba de re-ejecución.

---

## Evidencias

El notebook conserva las salidas de ejecución.

Además se versiona:

`evidence/e2_summary.json`

con los principales conteos y pruebas realizadas.

El archivo resume:

- fuentes procesadas;
- registros Bronze;
- eventos streaming;
- watermark;
- quarantine;
- Silver;
- Gold;
- idempotencia;
- conexión y upserts en AstraDB.

---

## Seguridad

El repositorio no contiene ni debe contener:

- Application Tokens;
- contraseñas;
- archivos `.env` reales;
- Secure Connect Bundles;
- credenciales de AstraDB;
- dataset completo provisto por la cátedra.

El Application Token se solicita durante la ejecución mediante entrada oculta.

El Secure Connect Bundle permanece únicamente en el almacenamiento temporal de Colab.

---

## Limitaciones de E2

Esta entrega corresponde a un MVP académico.

Entre las limitaciones conocidas:

- el watermark se basa en la evidencia disponible y no en lateness productiva real;
- Google Colab utiliza almacenamiento temporal;
- el modelo de serving de E2 cubre consultas temporales por organización y servicio;
- la instancia final requerirá nuevas tablas query-first para los restantes patrones de consulta;
- la política productiva definitiva de retención queda pendiente de requisitos de negocio, costos y cumplimiento;
- las optimizaciones de tamaño de archivos deberán revisarse si el volumen crece.

---

## Estado del proyecto

**Evaluación 1:** completada — diseño y fundación.

**Evaluación 2:** implementada — MVP técnico end-to-end mínimo.

El pipeline ejecutado conecta:

**Landing → Bronze → Silver → Gold → AstraDB**

La siguiente instancia ampliará el MVP con los marts y consultas requeridos para la evaluación final, además de documentación técnica, gobierno, observabilidad y material de defensa.
