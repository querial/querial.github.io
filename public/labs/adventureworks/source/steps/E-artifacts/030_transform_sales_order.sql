-- Scenario E: DuckDB single-input transform over extract Parquet → new Parquet.
-- Pipeline step code: transform_sales_order
-- Step type: artifact-sql (no database connection)
-- Depends on: extract_sales_order (artifact_available)
-- Input name: sales_order
--
-- DuckDB runs this SQL against the extract Parquet. CAST/filter here so the
-- join step consumes a typed artifact, not a raw extract.

SELECT
    CAST(sales_order_id AS INTEGER) AS sales_order_id,
    CAST(order_date AS TIMESTAMP) AS order_date,
    CAST(status AS INTEGER) AS status,
    CAST(customer_id AS INTEGER) AS customer_id,
    CAST(total_due AS DECIMAL(19, 4)) AS total_due,
    CAST(modified_date AS TIMESTAMP) AS modified_date
FROM {{ input.sales_order }}
WHERE total_due IS NOT NULL;
