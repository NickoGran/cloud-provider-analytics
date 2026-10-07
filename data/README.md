# Datos del proyecto

El dataset completo utilizado por Cloud Provider Analytics no se versiona en este repositorio.

## Dataset requerido

Para ejecutar el notebook se necesita:

`cloud_provider_challenge_dataset_v1.zip`

Este archivo es provisto como material del Proyecto Integrador.

## Uso en Google Colab

El notebook:

`notebooks/01_evaluacion_1_fundacion.ipynb`

solicita cargar el ZIP mediante el selector de archivos de Google Colab.

Posteriormente el contenido se descomprime dentro del entorno temporal y se utiliza la ruta:

`datalake/landing`

como origen de las fuentes crudas.

## Fuentes

El dataset contiene:

- `customers_orgs.csv`
- `users.csv`
- `resources.csv`
- `support_tickets.csv`
- `marketing_touches.csv`
- `nps_surveys.csv`
- `billing_monthly.csv`
- `usage_events_stream/*.jsonl`

## Importante

Los archivos de Landing deben considerarse inmutables.

No deben almacenarse credenciales, tokens ni datos sensibles dentro de este directorio.
