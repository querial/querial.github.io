-- Scenario E: SQL Server destination from DuckDB join/aggregate Parquet.
-- Pipeline step code: load_order_summary_sqlserver
-- Step type: staged-database-sql
-- Bind connection: aw-sql-dest
-- Depends on: transform_order_summary (artifact_available)
-- Stage name: order_summary

MERGE aw.sales_order_summary AS t
USING {{ stage.order_summary }} AS s
ON t.sales_order_id = s.sales_order_id
WHEN MATCHED THEN
    UPDATE SET
        customer_id         = s.customer_id,
        order_day           = s.order_day,
        line_count          = s.line_count,
        total_qty           = s.total_qty,
        computed_line_total = s.computed_line_total,
        header_total_due    = s.header_total_due,
        loaded_at_utc       = SYSUTCDATETIME()
WHEN NOT MATCHED THEN
    INSERT (sales_order_id, customer_id, order_day, line_count, total_qty, computed_line_total, header_total_due, loaded_at_utc)
    VALUES (s.sales_order_id, s.customer_id, s.order_day, s.line_count, s.total_qty, s.computed_line_total, s.header_total_due, SYSUTCDATETIME());
