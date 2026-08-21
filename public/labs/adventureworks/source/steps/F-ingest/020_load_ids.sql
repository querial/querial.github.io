-- Scenario F: PostgreSQL destination from uploaded Parquet stage.
-- Pipeline step code: load_ids
-- Step type: staged-database-sql
-- Bind connection: aw-pg-dest
-- Depends on: ingest_ids (artifact_available)
-- Stage name: ids — column id must match the fixture Parquet field.

INSERT INTO ingest.ids
(
    id,
    loaded_at_utc
)
SELECT
    s.id,
    (now() AT TIME ZONE 'utc')
FROM {{ stage }} AS s
ON CONFLICT (id) DO UPDATE SET
    loaded_at_utc = EXCLUDED.loaded_at_utc;
