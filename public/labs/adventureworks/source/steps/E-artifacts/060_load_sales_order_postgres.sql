-- Scenario E: PostgreSQL destination from transformed Parquet stage.
-- Pipeline step code: load_sales_order_postgres
-- Step type: staged-database-sql
-- Bind connection: aw-pg-dest
-- Depends on: transform_sales_order (artifact_available)
-- Stage name: sales_order

INSERT INTO aw.sales_order
(
    sales_order_id,
    order_date,
    status,
    customer_id,
    total_due,
    modified_date,
    loaded_at_utc
)
SELECT
    s.sales_order_id,
    s.order_date,
    s.status,
    s.customer_id,
    s.total_due,
    s.modified_date,
    (now() AT TIME ZONE 'utc')
FROM {{ stage }} AS s
ON CONFLICT (sales_order_id) DO UPDATE SET
    order_date    = EXCLUDED.order_date,
    status        = EXCLUDED.status,
    customer_id   = EXCLUDED.customer_id,
    total_due     = EXCLUDED.total_due,
    modified_date = EXCLUDED.modified_date,
    loaded_at_utc = EXCLUDED.loaded_at_utc;
