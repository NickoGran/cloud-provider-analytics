-- Cloud Provider Analytics - Evaluación 2
-- Keyspace utilizado en AstraDB

USE cloud_provider_analytics;

-- Tabla query-first del mart Gold
CREATE TABLE IF NOT EXISTS org_daily_usage_by_service (
    org_id text,
    service text,
    usage_date date,
    daily_cost_usd double,
    requests bigint,
    genai_tokens bigint,
    carbon_kg double,
    event_count int,
    negative_cost_events int,
    cost_spike_events int,
    PRIMARY KEY ((org_id, service), usage_date)
) WITH CLUSTERING ORDER BY (usage_date DESC);

-- Consulta 1: costos y requests diarios por organización y servicio en un rango
SELECT usage_date, daily_cost_usd, requests
FROM org_daily_usage_by_service
WHERE org_id = 'org_ktakpuxq'
  AND service = 'compute'
  AND usage_date >= '2025-07-03'
  AND usage_date <= '2025-08-31';

-- Consulta 2: últimos 10 registros de una partición organización + servicio
SELECT usage_date,
       daily_cost_usd,
       requests,
       genai_tokens,
       carbon_kg
FROM org_daily_usage_by_service
WHERE org_id = 'org_ktakpuxq'
  AND service = 'compute'
LIMIT 10;
