# Evidencias

Esta carpeta conserva evidencias resumidas de las distintas evaluaciones del Proyecto Integrador **Cloud Provider Analytics**.

Las salidas completas permanecen también dentro de los notebooks ejecutados, mientras que esta carpeta contiene artefactos compactos que facilitan verificar resultados sin volver a ejecutar todo el pipeline.

---

## Evaluación 1

La evidencia principal de la primera evaluación se encuentra en:

`notebooks/01_evaluacion_1_fundacion.ipynb`

El notebook contiene, entre otros:

- inventario de fuentes;
- conteos;
- esquemas;
- perfil de valores nulos;
- análisis de duplicados;
- controles de integridad referencial;
- cobertura temporal;
- trazabilidad del archivo de origen;
- análisis de las 5V;
- ejemplo de procesamiento batch mediante PySpark.

También se conserva documentación de E1 dentro de `docs/`.

---

## Evaluación 2

La evidencia ejecutable principal se encuentra en:

`notebooks/02_evaluacion_2_mvp.ipynb`

El notebook fue guardado con sus salidas de ejecución y documenta el flujo:

**Landing → Bronze → Silver → Gold → AstraDB**

Incluye evidencia de:

- ingesta batch;
- Structured Streaming;
- watermark;
- deduplicación;
- checkpoints;
- reglas de calidad;
- quarantine;
- Silver;
- features;
- Gold;
- particionamiento;
- detección de anomalías;
- carga en AstraDB;
- consultas CQL;
- idempotencia;
- gobierno y linaje.

---

## Resumen consolidado de E2

El archivo:

`e2_summary.json`

contiene los principales conteos finales de la ejecución.

Resultados:

| Evidencia | Resultado |
|---|---:|
| PySpark | 4.0.4 |
| Fuentes CSV | 7 |
| Archivos JSONL | 120 |
| Customers Bronze | 80 |
| Users Bronze | 800 |
| Billing Bronze | 240 |
| Eventos Streaming Bronze | 43.200 |
| Watermark | 86.400 min / 60 días |
| Quarantine | 2.038 |
| Eventos Silver | 41.162 |
| Customers Silver | 80 |
| Filas Gold | 11.050 |
| Claves duplicadas en Gold | 0 |

---

## Idempotencia

Las pruebas consolidadas de E2 registraron:

- batch con mismo conteo después de re-ejecutar;
- streaming sin duplicación al reutilizar el checkpoint;
- deduplicación controlada correcta;
- upserts en AstraDB sin duplicación lógica.

En `e2_summary.json` los cuatro controles quedaron registrados como:

```text id="7y9t7a"
batch_same_count: true
stream_same_count: true
controlled_dedupe_ok: true
astra_upsert_same_count: true
```

---

## Serving

La conexión con AstraDB y la carga del mart fueron ejecutadas correctamente.

La tabla utilizada es:

`org_daily_usage_by_service`

El script CQL completo se encuentra en:

`cql/02_evaluacion_2.cql`

Ese archivo incluye:

- keyspace utilizado;
- definición de la tabla query-first;
- consulta temporal por organización y servicio;
- consulta de últimos registros de una partición.

Las salidas de las consultas también permanecen guardadas en el notebook E2.

---

## Capas físicas generadas

Durante la ejecución E2 se midieron las salidas físicas generadas en Google Colab:

| Capa | Archivos | Tamaño aproximado |
|---|---:|---:|
| Bronze | 11.554 | 36,42 MB |
| Silver | 726 | 8,16 MB |
| Gold | 6 | 0,20 MB |
| Quarantine | 362 | 1,53 MB |
| **Total** | **12.648** | **46,31 MB** |

Estas capas no se versionan completas en GitHub porque son regenerables mediante el notebook y producirían miles de archivos Parquet.

En su lugar se conservan:

- código reproducible;
- resultados ejecutados;
- conteos;
- decisiones;
- CQL;
- resumen de evidencia.

---

## Seguridad

Esta carpeta no contiene:

- tokens de AstraDB;
- Secure Connect Bundles;
- contraseñas;
- credenciales;
- dataset completo.

Las credenciales utilizadas durante la ejecución permanecen fuera del repositorio.
