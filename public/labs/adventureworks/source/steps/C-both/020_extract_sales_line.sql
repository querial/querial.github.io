-- Scenario C: extract sales lines from SQL Server AdventureWorks (source).
-- Pipeline step code: extract_sales_line
-- Step type: database-query-to-parquet
-- Bind connection: SQL Server AdventureWorks (source).

SELECT
    d.SalesOrderID       AS sales_order_id,
    d.SalesOrderDetailID AS sales_order_detail_id,
    d.ProductID          AS product_id,
    d.OrderQty           AS order_qty,
    d.UnitPrice          AS unit_price,
    d.LineTotal          AS line_total
FROM Sales.SalesOrderDetail AS d;
