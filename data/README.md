# Datos del proyecto

El dataset completo utilizado por **Cloud Provider Analytics** no se versiona en este repositorio.

## Dataset requerido

Para ejecutar los notebooks se necesita el archivo provisto por la cátedra:

`cloud_provider_challenge_dataset_v1.zip`

Este archivo corresponde al material del Proyecto Integrador y debe obtenerse mediante los canales de la materia.

No se incluye dentro del repositorio público.

---

## Uso en Google Colab

### Evaluación 1

El notebook:

`notebooks/01_evaluacion_1_fundacion.ipynb`

solicita cargar el archivo:

`cloud_provider_challenge_dataset_v1.zip`

para realizar la exploración y fundación inicial del proyecto.

### Evaluación 2

El notebook:

`notebooks/02_evaluacion_2_mvp.ipynb`

también solicita cargar:

`cloud_provider_challenge_dataset_v1.zip`

al comienzo de la ejecución.

El contenido se descomprime dentro del almacenamiento temporal de Google Colab y se utiliza como Landing del pipeline.

A partir de esos archivos el notebook regenera:

- Bronze;
- Silver;
- Gold;
- quarantine;
- checkpoints;
- evidencias de ejecución.

---

## Fuentes disponibles

El dataset contiene:

- `customers_orgs.csv`
- `users.csv`
- `resources.csv`
- `support_tickets.csv`
- `marketing_touches.csv`
- `nps_surveys.csv`
- `billing_monthly.csv`
- `usage_events_stream/*.jsonl`

Durante E2 se verificaron:

- 7 archivos CSV;
- 120 archivos JSONL;
- 43.200 eventos de utilización.

---

## Landing

Los archivos originales deben considerarse inmutables.

Las transformaciones se realizan en capas posteriores del pipeline:

**Landing → Bronze → Silver → Gold**

No deben modificarse los archivos originales para corregir problemas de calidad.

---

## AstraDB

Los archivos y credenciales de AstraDB no forman parte del dataset y no se almacenan en este directorio.

Para reproducir la sección de serving de E2 se necesita:

- una base compatible de DataStax AstraDB;
- el keyspace `cloud_provider_analytics`;
- un Application Token válido;
- el Secure Connect Bundle correspondiente a esa base.

Cada usuario que reproduzca el proyecto debe utilizar sus propias credenciales de AstraDB.

El notebook solicita el Secure Connect Bundle y el Application Token durante la ejecución y no los almacena en GitHub.

---

## Seguridad

No deben versionarse:

- `cloud_provider_challenge_dataset_v1.zip`;
- Secure Connect Bundles;
- Application Tokens;
- contraseñas;
- archivos `.env` con secretos;
- datos sensibles.

El repositorio conserva únicamente código, instrucciones y evidencia necesaria para reproducir la solución.
