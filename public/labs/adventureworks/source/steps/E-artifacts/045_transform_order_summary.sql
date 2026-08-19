-- Scenario E: DuckDB multi-input join + aggregate over two Parquet artifacts.
-- Pipeline step code: transform_order_summary
-- Step type: artifact-sql (no database connection)
-- Depends on: transform_sales_order, transform_sales_line (artifact_available)
-- Input names: sales_order, sales_line
--
-- This is the Artifact SQL teaching step: two from_step inputs, an INNER JOIN,
-- GROUP BY, and a new Parquet output. Sinks load aw.sales_order_summary.

SELECT
    o.sales_order_id,
    o.customer_id,
    CAST(o.order_date AS DATE) AS order_day,
    COUNT(*) AS line_count,
    SUM(l.order_qty) AS total_qty,
    SUM(l.line_total) AS computed_line_total,
    o.total_due AS header_total_due
FROM {{ input.sales_order }} AS o
INNER JOIN {{ input.sales_line }} AS l
    ON o.sales_order_id = l.sales_order_id
GROUP BY
    o.sales_order_id,
    o.customer_id,
    CAST(o.order_date AS DATE),
    o.total_due;
