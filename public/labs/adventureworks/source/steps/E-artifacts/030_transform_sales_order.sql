-- Scenario E: DuckDB transform over extract Parquet → new Parquet.
-- Pipeline step code: transform_sales_order
-- Step type: artifact-sql
-- No database connection (artifact in → artifact out).
-- Depends on: extract_sales_order (artifact_available)
-- Input name: sales_order

SELECT
    sales_order_id,
    order_date,
    status,
    customer_id,
    total_due,
    modified_date
FROM {{ input.sales_order }}
WHERE total_due IS NOT NULL;
