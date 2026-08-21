-- Scenario C: SQL Server destination from a Parquet stage (artifact path).
-- Pipeline step code: load_sales_line_sqlserver_staged
-- Step type: staged-database-sql
-- Bind connection: SQL Server Querial destination.
-- Depends on: extract_sales_line, load_sales_order_sqlserver_staged
-- Stage name: sales_line

MERGE aw.sales_order_line AS t
USING {{ stage }} AS s
ON t.sales_order_id = s.sales_order_id
   AND t.sales_order_detail_id = s.sales_order_detail_id
WHEN MATCHED THEN
    UPDATE SET
        product_id    = s.product_id,
        order_qty     = s.order_qty,
        unit_price    = s.unit_price,
        line_total    = s.line_total,
        loaded_at_utc = SYSUTCDATETIME()
WHEN NOT MATCHED THEN
    INSERT (sales_order_id, sales_order_detail_id, product_id, order_qty, unit_price, line_total, loaded_at_utc)
    VALUES (s.sales_order_id, s.sales_order_detail_id, s.product_id, s.order_qty, s.unit_price, s.line_total, SYSUTCDATETIME());
