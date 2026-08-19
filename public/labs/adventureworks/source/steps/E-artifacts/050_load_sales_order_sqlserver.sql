-- Scenario E: SQL Server destination from transformed Parquet stage.
-- Promoted from C reference 031_load_sales_order_sqlserver_staged.sql.
-- Pipeline step code: load_sales_order_sqlserver
-- Step type: staged-database-sql
-- Bind connection: aw-sql-dest
-- Depends on: transform_sales_order (artifact_available)
-- Stage name: sales_order

MERGE aw.sales_order AS t
USING {{ stage.sales_order }} AS s
ON t.sales_order_id = s.sales_order_id
WHEN MATCHED AND t.modified_date <> s.modified_date THEN
    UPDATE SET
        order_date    = s.order_date,
        status        = s.status,
        customer_id   = s.customer_id,
        total_due     = s.total_due,
        modified_date = s.modified_date,
        loaded_at_utc = SYSUTCDATETIME()
WHEN NOT MATCHED THEN
    INSERT (sales_order_id, order_date, status, customer_id, total_due, modified_date, loaded_at_utc)
    VALUES (s.sales_order_id, s.order_date, s.status, s.customer_id, s.total_due, s.modified_date, SYSUTCDATETIME());
