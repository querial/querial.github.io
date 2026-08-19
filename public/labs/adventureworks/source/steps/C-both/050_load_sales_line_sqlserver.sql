-- Scenario C: SQL Server destination via same-instance 3-part names.
-- Pipeline step code: load_sales_line_sqlserver
-- Step type: sql_command
-- Bind connection: SQL Server Querial destination.
-- Depends on: load_sales_order_sqlserver
-- Replace [AdventureWorks] if your catalog name differs.

MERGE aw.sales_order_line AS t
USING
(
    SELECT
        d.SalesOrderID       AS sales_order_id,
        d.SalesOrderDetailID AS sales_order_detail_id,
        d.ProductID          AS product_id,
        d.OrderQty           AS order_qty,
        d.UnitPrice          AS unit_price,
        d.LineTotal          AS line_total
    FROM AdventureWorks.Sales.SalesOrderDetail AS d
) AS s
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
