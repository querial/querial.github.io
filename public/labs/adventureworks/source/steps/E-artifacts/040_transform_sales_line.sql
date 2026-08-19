-- Scenario E: DuckDB transform over extract Parquet → new Parquet.
-- Pipeline step code: transform_sales_line
-- Step type: artifact-sql
-- No database connection (artifact in → artifact out).
-- Depends on: extract_sales_line (artifact_available)
-- Input name: sales_line

SELECT
    sales_order_id,
    sales_order_detail_id,
    product_id,
    order_qty,
    unit_price,
    line_total
FROM {{ input.sales_line }}
WHERE order_qty > 0;
