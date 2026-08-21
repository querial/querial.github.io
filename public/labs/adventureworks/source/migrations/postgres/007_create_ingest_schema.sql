-- Scenario F: destination schema for trigger-time Parquet ingest.
-- Pipeline migration code: ingest_001_create_schema
-- Apply via Querial to aw-pg-dest (Aspire target-pg / querial_test).

CREATE SCHEMA IF NOT EXISTS ingest;
