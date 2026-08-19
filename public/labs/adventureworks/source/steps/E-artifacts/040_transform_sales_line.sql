-- Scenario E: DuckDB single-input transform over extract Parquet → new Parquet.
-- Pipeline step code: transform_sales_line
-- Step type: artifact-sql (no database connection)
-- Depends on: extract_sales_line (artifact_available)
-- Input name: sales_line

SELECT
    CAST(sales_order_id AS INTEGER) AS sales_order_id,
    CAST(sales_order_detail_id AS INTEGER) AS sales_order_detail_id,
    CAST(product_id AS INTEGER) AS product_id,
    CAST(order_qty AS INTEGER) AS order_qty,
    CAST(unit_price AS DECIMAL(19, 4)) AS unit_price,
    CAST(line_total AS DECIMAL(19, 4)) AS line_total
FROM {{ input.sales_line }}
WHERE order_qty > 0;
