# Registro de decisiones

Este documento registra las principales decisiones técnicas adoptadas durante el desarrollo de **Cloud Provider Analytics**.

Las decisiones inicialmente planteadas durante la Evaluación 1 se mantienen cuando fueron validadas y se actualizan cuando la implementación de la Evaluación 2 permitió obtener evidencia concreta.

---

## D001 — Mantener Landing inmutable

**Estado:** Aceptada

Los archivos originales se conservan sin modificaciones.

### Motivo

Permite:

- reproducir el procesamiento;
- mantener trazabilidad;
- volver a procesar las fuentes;
- diferenciar claramente los datos originales de las transformaciones posteriores.

Landing funciona como punto de partida reproducible del pipeline.

---

## D002 — Utilizar arquitectura Lambda

**Estado:** Aceptada y validada en E2

Se utilizan dos caminos de procesamiento:

- batch para maestros y fuentes periódicas;
- streaming para `usage_events_stream/*.jsonl`.

### Motivo

Las fuentes poseen necesidades diferentes.

Los maestros y la facturación tienen características batch, mientras que los eventos de utilización representan una fuente naturalmente orientada a procesamiento incremental.

La Evaluación 2 implementó ambos caminos y confirmó que convergen correctamente en las capas Silver y Gold.

---

## D003 — Utilizar Apache Spark / PySpark

**Estado:** Aceptada y validada

PySpark es el motor principal de procesamiento.

### Motivo

Permite trabajar dentro de un mismo ecosistema con:

- procesamiento batch;
- DataFrames;
- joins;
- agregaciones;
- Parquet;
- Structured Streaming;
- watermarks;
- checkpoints;
- controles de calidad.

La implementación de E2 utilizó **PySpark 4.0.4** en Google Colab.

---

## D004 — Utilizar Parquet desde Bronze

**Estado:** Aceptada y validada

Landing conserva los formatos originales.

Bronze, Silver, Gold y quarantine utilizan Parquet.

### Motivo

Parquet es apropiado para procesamiento analítico con Spark y permite trabajar eficientemente con datos estructurados y particionados.

Durante E2 se generaron físicamente las distintas capas y se volvieron a leer desde Parquet para validar que la evidencia no dependiera únicamente de DataFrames en memoria.

---

## D005 — Utilizar zonas Landing, Bronze, Silver y Gold

**Estado:** Aceptada y validada

### Landing

Datos originales e inmutables.

### Bronze

Datos técnicamente estandarizados manteniendo el grano original.

Incluye:

- esquema explícito;
- tipificación controlada;
- metadata técnica;
- deduplicación cuando corresponde.

### Silver

Datos:

- normalizados;
- enriquecidos;
- sometidos a reglas de calidad;
- preparados para análisis.

### Gold

Productos analíticos orientados a consultas de negocio.

Durante E2 se implementó:

`org_daily_usage_by_service`

con grano:

`org_id + usage_date + service`

---

## D006 — Incorporar quarantine

**Estado:** Aceptada e implementada

Los registros que no superan determinadas reglas de promoción se almacenan en un área separada de quarantine.

### Motivo

Permite evitar que registros inválidos avancen hacia Silver sin perder información necesaria para análisis y auditoría.

Durante E2 se generaron:

**2.038 registros en quarantine**

Cada registro conserva `quality_reason` para explicar el motivo del rechazo.

---

## D007 — Particionar Gold por mes

**Estado:** Aceptada para el MVP de E2

Durante E1 se había decidido priorizar particiones temporales, pero la granularidad concreta había quedado pendiente.

En E2 se compararon alternativas utilizando el mismo mart Gold.

### Evidencia

| Estrategia | Archivos Parquet |
|---|---:|
| Sin partición | 1 |
| Por mes | 2 |
| Por fecha | 60 |
| Por fecha + servicio | 360 |

### Decisión

Gold se particiona por:

`usage_month`

### Motivo

La partición mensual:

- mantiene una dimensión temporal útil;
- tiene baja cardinalidad;
- evita la fragmentación observada con particiones diarias;
- resulta suficiente para el volumen académico disponible.

Esta decisión deberá revisarse si el volumen o los patrones de consulta cambian significativamente.

---

## D008 — Utilizar Cassandra / AstraDB como serving

**Estado:** Aceptada e implementada

DataStax AstraDB se utiliza como capa de serving.

Durante E2 se creó el keyspace:

`cloud_provider_analytics`

y la tabla:

`org_daily_usage_by_service`

### Motivo

La consigna requiere Cassandra/AstraDB como serving y un diseño orientado a consultas.

La implementación demostró carga mediante upserts y ejecución real de consultas CQL.

---

## D009 — No almacenar el dataset completo en GitHub

**Estado:** Aceptada

El dataset completo provisto por la cátedra no se versiona en el repositorio.

### Motivo

Evita:

- duplicar material innecesario;
- aumentar considerablemente el tamaño del repositorio;
- publicar datos de cursada que pueden regenerarse mediante las instrucciones del proyecto.

El repositorio documenta cómo cargar el dataset durante la ejecución.

---

## D010 — Utilizar un watermark de 60 días en el MVP académico

**Estado:** Aceptada para E2

En E1 el watermark quedó abierto para evitar elegir un valor arbitrario.

Durante E2 se analizaron distintas tolerancias:

- 120 minutos;
- 1 día;
- 7 días;
- 30 días;
- 60 días.

### Evidencia

La aproximación utilizada produjo:

- P50 de lateness: 42.608 minutos;
- P95: 81.269 minutos;
- P99: 86.394 minutos;
- máximo observado: 86.394 minutos.

Una tolerancia de 30 días cubría aproximadamente el 50,41 % de los eventos.

Una tolerancia de 60 días cubrió el 100 %.

### Decisión

Se utiliza:

**86.400 minutos / 60 días**

### Resultado

Structured Streaming procesó:

- 43.200 eventos;
- 43.200 `event_id` distintos;
- 0 eventos descartados por watermark.

### Limitación

El dataset no posee un timestamp productivo real de llegada y los archivos JSONL no representan un orden cronológico estricto.

Por este motivo, 60 días es una decisión válida para el MVP académico pero **no se propone como configuración productiva**.

En producción debería recalibrarse utilizando lateness real.

---

## D011 — Mantener los costos negativos y marcarlos como anomalía

**Estado:** Aceptada e implementada

Un `cost_usd_increment` menor a:

`-0.01`

se identifica mediante un flag de anomalía.

### Motivo

Los costos negativos pueden representar ajustes, créditos u otras situaciones que no deben eliminarse silenciosamente.

Por lo tanto:

- el evento se conserva;
- se registra el flag;
- la anomalía queda disponible para análisis posterior.

La regla funciona como control de calidad sin eliminar información financiera potencialmente válida.

---

## D012 — Detectar spikes mediante percentil 99 por servicio

**Estado:** Aceptada para el componente analítico de E2

Se utiliza el percentil 99 del costo por servicio para identificar eventos de costo elevado.

### Motivo

Los servicios poseen escalas de costo diferentes.

Calcular un único umbral global podría clasificar incorrectamente servicios con distribuciones distintas.

Por eso el percentil se calcula por `service`.

### Limitación

Se trata de un método simple y explicable apropiado para el MVP.

En la instancia final puede compararse con otros métodos si aporta valor medible.

---

## D013 — Utilizar un modelo Cassandra query-first

**Estado:** Aceptada e implementada

La tabla principal de E2 es:

`org_daily_usage_by_service`

con:

```sql
PRIMARY KEY ((org_id, service), usage_date)
```

y:

```sql
WITH CLUSTERING ORDER BY (usage_date DESC)
```

### Motivo

El modelo está diseñado para consultar eficientemente:

- una organización;
- un servicio;
- un rango temporal.

La partition key es:

`(org_id, service)`

y `usage_date` funciona como clustering key.

Esto evita depender de `ALLOW FILTERING`.

### Alcance

La tabla resuelve las consultas temporales implementadas en E2.

Los patrones requeridos para la evaluación final que tengan otras claves de acceso deberán resolverse mediante nuevas tablas query-first.

---

## D014 — Utilizar upserts para la carga hacia AstraDB

**Estado:** Aceptada e implementada

Las filas Gold se cargan utilizando la primary key definida en Cassandra.

### Motivo

Cassandra trata una nueva escritura sobre la misma primary key como una actualización de la fila existente.

Esto permite reprocesar la misma información sin generar duplicados lógicos.

### Evidencia

La prueba de E2 comparó una partición antes y después de repetir la carga y mantuvo el mismo conteo.

La idempotencia mediante upsert quedó validada.

---

## D015 — Mantener checkpoints separados para Structured Streaming

**Estado:** Aceptada e implementada

Cada query de Structured Streaming utiliza un directorio de checkpoint propio.

### Motivo

El checkpoint conserva el estado de procesamiento y permite identificar archivos ya confirmados.

Durante la prueba de idempotencia, volver a ejecutar el stream con el mismo checkpoint no generó nuevos registros.

Resultado:

**43.200 → 43.200**

---

## D016 — No almacenar credenciales de AstraDB en el repositorio

**Estado:** Aceptada e implementada

No se versionan:

- Application Tokens;
- contraseñas;
- Secure Connect Bundles;
- archivos `.env` con secretos.

### Implementación

El Application Token se solicita durante la ejecución mediante entrada oculta.

El Secure Connect Bundle se carga únicamente en el almacenamiento temporal de Colab.

### Motivo

Separa configuración sensible del código y evita exponer credenciales en GitHub.

---

## D017 — No versionar las capas completas generadas en Colab

**Estado:** Aceptada para E2

Bronze, Silver, Gold y quarantine se regeneran a partir del dataset de Landing.

Durante E2 las salidas físicas generaron aproximadamente:

- Bronze: 36,42 MB;
- Silver: 8,16 MB;
- Gold: 0,20 MB;
- Quarantine: 1,53 MB.

Total aproximado:

**46,31 MB**

Además se generaron **12.648 archivos físicos**.

### Motivo

Versionar miles de archivos Parquet no aporta valor proporcional al repositorio.

En su lugar se versionan:

- notebook reproducible;
- instrucciones de ejecución;
- resumen de evidencia;
- CQL;
- decisiones;
- documentación.

---

## D018 — Política de retención del MVP académico

**Estado:** Aceptada para el período académico

Durante el proyecto se adopta:

| Capa | Política del MVP |
|---|---|
| Landing | Conservar durante todo el proyecto |
| Bronze | Regenerable desde Landing |
| Silver | Regenerable desde Bronze |
| Gold | Regenerable desde Silver |
| Quarantine | Conservar durante el proyecto para auditoría |
| AstraDB | Sin TTL durante el período académico |

### Motivo

La política permite conservar evidencia suficiente para las evaluaciones sin inventar requisitos regulatorios o comerciales inexistentes.

Una política productiva definitiva requiere información de negocio, costos y cumplimiento que no forma parte de E2.

---

# Decisiones todavía abiertas para la instancia final

Las siguientes decisiones no se consideran cerradas de forma productiva:

- recalibración del watermark con datos reales de llegada;
- política productiva definitiva de retención;
- frecuencia y orquestación de las cargas batch;
- nuevas tablas query-first necesarias para las cinco consultas finales;
- estrategia de compactación o control de archivos pequeños a mayor escala;
- ampliación de observabilidad y manejo de errores;
- evaluación de métodos analíticos adicionales cuando aporten valor.

Estas decisiones se cerrarán únicamente cuando exista evidencia o un requisito concreto que permita justificarlas.
