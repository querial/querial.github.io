-- Scenario E: PostgreSQL destination from DuckDB join/aggregate Parquet.
-- Pipeline step code: load_order_summary_postgres
-- Step type: staged-database-sql
-- Bind connection: aw-pg-dest
-- Depends on: transform_order_summary (artifact_available)
-- Stage name: order_summary

INSERT INTO aw.sales_order_summary
(
    sales_order_id,
    customer_id,
    order_day,
    line_count,
    total_qty,
    computed_line_total,
    header_total_due,
    loaded_at_utc
)
SELECT
    s.sales_order_id,
    s.customer_id,
    s.order_day,
    s.line_count,
    s.total_qty,
    s.computed_line_total,
    s.header_total_due,
    (now() AT TIME ZONE 'utc')
FROM {{ stage.order_summary }} AS s
ON CONFLICT (sales_order_id) DO UPDATE SET
    customer_id         = EXCLUDED.customer_id,
    order_day           = EXCLUDED.order_day,
    line_count          = EXCLUDED.line_count,
    total_qty           = EXCLUDED.total_qty,
    computed_line_total = EXCLUDED.computed_line_total,
    header_total_due    = EXCLUDED.header_total_due,
    loaded_at_utc       = EXCLUDED.loaded_at_utc;
