-- Scenario E: PostgreSQL destination from transformed Parquet stage.
-- Pipeline step code: load_sales_line_postgres
-- Step type: staged-database-sql
-- Bind connection: aw-pg-dest
-- Depends on: transform_sales_line (artifact_available), load_sales_order_postgres (required)
-- Stage name: sales_line

INSERT INTO aw.sales_order_line
(
    sales_order_id,
    sales_order_detail_id,
    product_id,
    order_qty,
    unit_price,
    line_total,
    loaded_at_utc
)
SELECT
    s.sales_order_id,
    s.sales_order_detail_id,
    s.product_id,
    s.order_qty,
    s.unit_price,
    s.line_total,
    (now() AT TIME ZONE 'utc')
FROM {{ stage }} AS s
ON CONFLICT (sales_order_id, sales_order_detail_id) DO UPDATE SET
    product_id    = EXCLUDED.product_id,
    order_qty     = EXCLUDED.order_qty,
    unit_price    = EXCLUDED.unit_price,
    line_total    = EXCLUDED.line_total,
    loaded_at_utc = EXCLUDED.loaded_at_utc;
