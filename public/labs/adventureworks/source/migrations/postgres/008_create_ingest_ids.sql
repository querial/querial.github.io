-- Scenario F: ids loaded from the trigger-time Parquet fixture (column id).
-- Pipeline migration code: ingest_002_create_ids

CREATE TABLE IF NOT EXISTS ingest.ids
(
    id            INTEGER      NOT NULL,
    loaded_at_utc TIMESTAMPTZ  NOT NULL DEFAULT (now() AT TIME ZONE 'utc'),
    CONSTRAINT pk_ingest_ids PRIMARY KEY (id)
);
