# Registro de decisiones

Este documento registra las principales decisiones técnicas adoptadas durante el desarrollo de Cloud Provider Analytics.

---

## D001 — Mantener Landing inmutable

**Estado:** Aceptada

Los archivos originales se conservarán sin modificaciones.

### Motivo

Permite:

- reproducir el procesamiento;
- mantener trazabilidad;
- volver a procesar las fuentes;
- diferenciar los datos originales de las transformaciones posteriores.

---

## D002 — Utilizar arquitectura Lambda

**Estado:** Aceptada

Se utilizarán dos caminos de procesamiento:

- batch para maestros y fuentes periódicas;
- streaming para `usage_events_stream`.

### Motivo

Las fuentes poseen necesidades de procesamiento diferentes y la combinación batch + streaming representa directamente el caso planteado.

No se considera necesario tratar artificialmente todas las fuentes como streams.

---

## D003 — Utilizar Apache Spark / PySpark

**Estado:** Aceptada

PySpark será el motor principal de procesamiento.

### Motivo

Permite utilizar un mismo ecosistema para:

- procesamiento batch;
- DataFrames;
- agregaciones;
- joins;
- Parquet;
- Structured Streaming.

Además forma parte de las tecnologías trabajadas durante la cursada.

---

## D004 — Utilizar Parquet desde Bronze

**Estado:** Aceptada

Landing conservará los formatos originales.

Bronze, Silver y Gold utilizarán Parquet como formato intermedio.

### Motivo

Parquet resulta adecuado para procesamiento analítico con Spark y permite trabajar eficientemente con datos estructurados y particionados.

---

## D005 — Utilizar zonas Landing, Bronze, Silver y Gold

**Estado:** Aceptada

### Responsabilidades

**Landing**

Datos originales.

**Bronze**

Datos técnicamente estandarizados manteniendo el grano original.

**Silver**

Datos limpios, normalizados, enriquecidos y conformados.

**Gold**

Productos analíticos orientados a consultas de negocio.

---

## D006 — Incorporar quarantine

**Estado:** Aceptada

Los registros que no puedan superar determinadas reglas de calidad podrán almacenarse en un área auxiliar de quarantine.

### Motivo

Permite evitar la promoción de información inválida sin perder los registros necesarios para análisis y auditoría.

---

## D007 — Particionar principalmente por tiempo

**Estado:** Inicial / sujeta a validación

Para las fuentes de mayor crecimiento se priorizarán particiones temporales.

Ejemplos:

- eventos por fecha;
- facturación por mes;
- productos Gold por fecha o mes según su grano.

### Motivo

Las consultas previstas poseen un fuerte componente temporal y esta estrategia evita particionar por identificadores de alta cardinalidad.

La cantidad concreta de particiones deberá validarse durante la implementación.

---

## D008 — Utilizar Cassandra / AstraDB como serving

**Estado:** Definida por el proyecto

Los productos Gold serán publicados posteriormente en Cassandra/AstraDB.

El diseño físico será query-first y se definirá durante las siguientes entregas.

---

## D009 — No almacenar el dataset completo en GitHub

**Estado:** Aceptada

El repositorio documentará cómo cargar el dataset provisto por la cátedra.

### Motivo

Evita:

- duplicar archivos innecesarios;
- aumentar el tamaño del repositorio;
- publicar material de cursada que no es necesario versionar.

---

# Decisiones abiertas

Todavía deberán definirse durante la implementación:

- watermark concreto de streaming;
- criterio y umbral de anomalías;
- cantidad óptima de particiones;
- frecuencia exacta de algunas cargas batch;
- política productiva de retención;
- modelo físico query-first de Cassandra/AstraDB.

Estas decisiones se cerrarán cuando exista evidencia técnica suficiente.
