# Cloud Provider Analytics

Proyecto Integrador de **Minería de Datos II** — ISTEA.

## Objetivo

El proyecto representa al área de datos de un proveedor de servicios cloud.

El objetivo general es diseñar e implementar progresivamente un pipeline de datos capaz de integrar fuentes batch y eventos de utilización, organizar la información mediante un Data Lake y preparar productos analíticos destinados a los dominios de:

- FinOps
- Soporte
- Producto / Usage

La arquitectura propuesta sigue el flujo:

**Fuentes → Landing → Bronze → Silver → Gold → Serving**

y utiliza Apache Spark como motor principal de procesamiento.

---

## Primera evaluación — Diseño y fundación de datos

La primera evaluación se concentra en comprender el problema y establecer la fundación arquitectónica del proyecto.

El notebook incluye:

1. interpretación del problema, usuarios y objetivos;
2. análisis de las 5V de Big Data;
3. inventario y perfil inicial de las fuentes;
4. arquitectura de alto nivel;
5. selección del patrón Lambda;
6. matriz requisito-componente;
7. diseño del Data Lake;
8. diseño de flujos batch y streaming;
9. ejemplo de procesamiento batch mediante lógica MapReduce;
10. supuestos, riesgos y mitigaciones;
11. estimación de esfuerzo, roles y recursos;
12. repositorio y evidencia inicial.

---

## Tecnologías

- Google Colab
- Python
- Apache Spark / PySpark
- Spark DataFrames
- Structured Streaming
- CSV
- JSON Lines (JSONL)
- Parquet
- Cassandra / AstraDB para la futura capa de serving
- Git / GitHub

---

## Arquitectura

La solución diferencia dos caminos de procesamiento.

### Batch

Utilizado para fuentes maestras y periódicas como:

- clientes;
- usuarios;
- recursos;
- tickets;
- marketing;
- NPS;
- facturación.

### Streaming

Utilizado para:

`usage_events_stream/*.jsonl`

Los eventos serán procesados mediante Structured Streaming en las siguientes etapas.

Ambos caminos convergen progresivamente en las capas Silver y Gold.

---

## Data Lake

Se utilizan cuatro zonas principales:

- **Landing:** archivos originales e inmutables.
- **Bronze:** datos crudos estandarizados técnicamente.
- **Silver:** datos limpios, normalizados y conformados.
- **Gold:** productos de datos orientados a consultas de negocio.

Parquet se utilizará como formato intermedio a partir de Bronze.

También se contempla un área auxiliar de `quarantine` para registros que no superen reglas de calidad.

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
│   └── 01_evaluacion_1_fundacion.ipynb
│
├── docs/
│   ├── evaluacion_1.pdf
│   └── arquitectura_v1.png
│
├── data/
│   └── README.md
│
└── evidence/
    └── README.md
```

La estructura será ampliada durante las siguientes evaluaciones a medida que se incorpore código productivo, configuración y pruebas.

---

## Dataset

El dataset completo no se almacena en este repositorio.

Para ejecutar el notebook se necesita el archivo provisto por la cátedra:

`cloud_provider_challenge_dataset_v1.zip`

El notebook solicita cargar este archivo en Google Colab y posteriormente lo descomprime dentro del entorno temporal de ejecución.

Las fuentes utilizadas incluyen:

- `customers_orgs.csv`
- `users.csv`
- `resources.csv`
- `support_tickets.csv`
- `marketing_touches.csv`
- `nps_surveys.csv`
- `billing_monthly.csv`
- `usage_events_stream/*.jsonl`

---

## Ejecución

1. Abrir `notebooks/01_evaluacion_1_fundacion.ipynb` en Google Colab.
2. Ejecutar las celdas en orden.
3. Cuando el notebook lo solicite, cargar `cloud_provider_challenge_dataset_v1.zip`.
4. Continuar la ejecución hasta finalizar el notebook.

El notebook instala la versión de PySpark utilizada para la evaluación y genera las evidencias de exploración directamente desde los datos.

---

## Evidencias principales

Durante la primera evaluación se verificaron, entre otros resultados:

- 8 fuentes lógicas;
- 43.200 eventos de utilización;
- 120 archivos JSONL;
- dos versiones de esquema;
- ausencia de duplicados en las claves candidatas evaluadas;
- integridad referencial de `org_id` y `resource_id`;
- presencia de valores nulos;
- tipos ambiguos en `value`;
- costos negativos;
- evolución del esquema entre v1 y v2.

Los resultados completos y su interpretación se encuentran documentados en el notebook.

---

## Estado del proyecto

**Evaluación 1:** diseño y fundación de datos.

Las siguientes etapas incorporarán progresivamente:

- ingesta batch a Bronze;
- Structured Streaming;
- Silver;
- reglas de calidad y quarantine;
- productos Gold;
- Cassandra / AstraDB;
- pruebas y reproducibilidad end-to-end.

---

## Seguridad

El repositorio no debe contener:

- contraseñas;
- tokens;
- credenciales;
- archivos `.env` reales;
- credenciales de Cassandra/AstraDB.

La configuración sensible deberá mantenerse fuera del código versionado.
